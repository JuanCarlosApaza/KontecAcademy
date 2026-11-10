import 'dotenv/config';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { Client } from 'pg';

/**
 * Fase 0 — Extrae de Supabase (SOLO LECTURA, nunca escribe allí ni en
 * MySQL) tres archivos de referencia a sql-mysql/:
 *
 *   1. schema-source.json — columnas, restricciones e índices de todas
 *      las tablas del esquema `public`. Es la fuente de verdad para
 *      redactar 000_base_schema.sql en dialecto MySQL.
 *   2. seed-source.json   — datos seed crudos (referencia/humanos).
 *   3. 001_seed.sql       — INSERTs MySQL listos (roles, permisos,
 *      categorías, rutas, planes). Idempotente (INSERT IGNORE).
 *
 * Usa el POOLER IPv4 (misma conexión que tool/migrate-pooler.ts),
 * porque el host directo db.* solo tiene AAAA.
 *
 * Uso:  cd server && npx tsx tool/mysql-schema-dump.ts
 */

type ColumnRow = {
  table_name: string;
  column_name: string;
  data_type: string;
  udt_name: string;
  is_nullable: 'YES' | 'NO';
  column_default: string | null;
  character_maximum_length: number | null;
  numeric_precision: number | null;
  numeric_scale: number | null;
  ordinal_position: number;
  is_identity: 'YES' | 'NO';
};

type ConstraintRow = {
  table_name: string;
  name: string;
  type: 'p' | 'f' | 'u' | 'c';
  definition: string;
};

type IndexRow = {
  tablename: string;
  indexname: string;
  indexdef: string;
};

type SeedValue = string | null;

/**
 * Tablas que se siembran en MySQL. Excluidas a propósito:
 *  - path_courses: sus filas referencian cursos que NO se migran
 *    (arranque limpio); se vuelca solo a seed-source.json para poder
 *    re-enlazarlas a mano desde el panel admin.
 *  - usuarios/pagos/inscripciones: datos, no seeds.
 */
const SEED_TABLES = [
  'roles',
  'permissions',
  'role_permissions',
  'categories',
  'learning_paths',
  'membership_plans',
];

/** Solo referencial (va a seed-source.json pero no a 001_seed.sql). */
const REFERENCE_TABLES = ['path_courses'];

function fail(msg: string): never {
  console.error(`❌ ${msg}`);
  process.exit(1);
}

const dbUrl = process.env.SUPABASE_DB_URL;
if (!dbUrl) fail('Falta SUPABASE_DB_URL en server/.env');
const supabaseUrl = process.env.SUPABASE_URL;
if (!supabaseUrl) fail('Falta SUPABASE_URL en server/.env');

const u = new URL(dbUrl);
const ref = new URL(supabaseUrl).hostname.split('.')[0]!;

const client = new Client({
  host: 'aws-1-us-west-2.pooler.supabase.com',
  port: 6543,
  user: `postgres.${ref}`,
  password: decodeURIComponent(u.password),
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
});

// ── Consultas de esquema ──────────────────────────────────────────────

async function fetchTables(): Promise<string[]> {
  const { rows } = await client.query<{ table_name: string }>(
    `select table_name from information_schema.tables
      where table_schema = 'public' and table_type = 'BASE TABLE'
      order by table_name`,
  );
  return rows.map((r) => r.table_name);
}

async function fetchViews(): Promise<string[]> {
  const { rows } = await client.query<{ table_name: string }>(
    `select table_name from information_schema.views
      where table_schema = 'public' order by table_name`,
  );
  return rows.map((r) => r.table_name);
}

async function fetchColumns(): Promise<ColumnRow[]> {
  const { rows } = await client.query<ColumnRow>(
    `select table_name, column_name, data_type, udt_name, is_nullable,
            column_default, character_maximum_length, numeric_precision,
            numeric_scale, ordinal_position, is_identity
       from information_schema.columns
      where table_schema = 'public'
      order by table_name, ordinal_position`,
  );
  return rows;
}

async function fetchConstraints(): Promise<ConstraintRow[]> {
  const { rows } = await client.query<ConstraintRow>(
    `select rel.relname as table_name, con.conname as name,
            con.contype as type, pg_get_constraintdef(con.oid) as definition
       from pg_constraint con
       join pg_class rel on rel.oid = con.conrelid
       join pg_namespace ns on ns.oid = rel.relnamespace
      where ns.nspname = 'public'
      order by rel.relname, con.conname`,
  );
  return rows;
}

async function fetchIndexes(): Promise<IndexRow[]> {
  const { rows } = await client.query<IndexRow>(
    `select tablename, indexname, indexdef from pg_indexes
      where schemaname = 'public' order by tablename, indexname`,
  );
  return rows;
}

// ── Traducción de valores a literales MySQL ───────────────────────────

function selectExpr(c: ColumnRow): string {
  const q = `"${c.column_name}"`;
  switch (c.data_type) {
    case 'timestamp with time zone':
      // UTC explícito: el DATETIME de MySQL guarda UTC sin offset.
      return `to_char(${q} at time zone 'UTC', 'YYYY-MM-DD HH24:MI:SS')`;
    case 'timestamp without time zone':
      return `to_char(${q}, 'YYYY-MM-DD HH24:MI:SS')`;
    case 'date':
      return `to_char(${q}, 'YYYY-MM-DD')`;
    case 'boolean':
      return `${q}::int::text`;
    default:
      return `${q}::text`;
  }
}

function isNumericType(dataType: string): boolean {
  return [
    'smallint',
    'integer',
    'bigint',
    'numeric',
    'real',
    'double precision',
    'decimal',
  ].includes(dataType);
}

function mysqlEscape(s: string): string {
  return s.replace(/[\0\x08\x09\x1a\n\r"'\\]/g, (ch) => {
    switch (ch) {
      case '\0':
        return '\\0';
      case '\x08':
        return '\\b';
      case '\x09':
        return '\\t';
      case '\x1a':
        return '\\Z';
      case '\n':
        return '\\n';
      case '\r':
        return '\\r';
      case '"':
        return '\\"';
      case "'":
        return "\\'";
      default:
        return '\\\\';
    }
  });
}

function literal(c: ColumnRow, value: SeedValue): string {
  if (value === null) return 'NULL';
  if (c.data_type === 'boolean') return value === '1' ? '1' : '0';
  if (isNumericType(c.data_type)) {
    // numeric::text es canónico en PG; si no parece número, se cotiza.
    return /^-?\d+(\.\d+)?$/.test(value) ? value : `'${mysqlEscape(value)}'`;
  }
  return `'${mysqlEscape(value)}'`;
}

async function fetchSeedRows(
  table: string,
  cols: ColumnRow[],
): Promise<Record<string, SeedValue>[]> {
  const exprs = cols.map((c) => `${selectExpr(c)} as "${c.column_name}"`);
  const { rows } = await client.query<Record<string, SeedValue>>(
    `select ${exprs.join(', ')} from public."${table}"`,
  );
  return rows;
}

function buildInsert(
  table: string,
  cols: ColumnRow[],
  rows: Record<string, SeedValue>[],
): string {
  const colList = cols.map((c) => `\`${c.column_name}\``).join(', ');
  const tuples = rows
    .map((r) => `(${cols.map((c) => literal(c, r[c.column_name])).join(', ')})`)
    .join(',\n  ');
  return `INSERT IGNORE INTO \`${table}\` (${colList}) VALUES\n  ${tuples};`;
}

// ── Programa principal ────────────────────────────────────────────────

await client.connect();

try {
  const tables = await fetchTables();
  const views = await fetchViews();
  const columns = await fetchColumns();
  const constraints = await fetchConstraints();
  const indexes = await fetchIndexes();

  if (views.length > 0) {
    console.log(`⚠️  Vistas en public (no se portan a MySQL): ${views.join(', ')}`);
  }

  // Estructura del dump de esquema.
  const schemaDump: Record<string, unknown> = {};
  for (const t of tables) {
    schemaDump[t] = {
      columns: columns.filter((c) => c.table_name === t),
      constraints: constraints.filter((c) => c.table_name === t),
      indexes: indexes.filter((i) => i.tablename === t),
    };
  }

  const outDir = path.join(process.cwd(), 'sql-mysql');
  await mkdir(outDir, { recursive: true });

  await writeFile(
    path.join(outDir, 'schema-source.json'),
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        source: `supabase (${ref}) via pooler — solo lectura`,
        note: 'Fuente de verdad para redactar 000_base_schema.sql (MySQL).',
        tables: schemaDump,
      },
      null,
      2,
    ),
  );

  // Resumen + alertas para la traducción MySQL.
  console.log(`\n📄 Esquema: ${tables.length} tablas → sql-mysql/schema-source.json`);
  for (const t of tables) {
    const cols = columns.filter((c) => c.table_name === t);
    const pks = constraints.filter((c) => c.table_name === t && c.type === 'p');
    console.log(
      `   ${t.padEnd(22)} ${String(cols.length).padStart(2)} columnas  PK: ${
        pks[0]?.definition ?? '(ninguna)'
      }`,
    );
  }

  const authFks = constraints.filter(
    (c) => c.type === 'f' && /references\s+auth\./i.test(c.definition),
  );
  if (authFks.length > 0) {
    console.log('\n⚠️  FKs hacia auth.users (en MySQL apuntan a users local):');
    for (const c of authFks) {
      console.log(`   ${c.table_name}.${c.name}: ${c.definition}`);
    }
  }

  const serials = columns.filter(
    (c) =>
      c.is_identity === 'YES' ||
      (c.column_default ?? '').startsWith('nextval('),
  );
  if (serials.length > 0) {
    console.log('\n⚠️  Columnas serial/identity (→ AUTO_INCREMENT en MySQL):');
    for (const c of serials) {
      console.log(`   ${c.table_name}.${c.column_name}`);
    }
  }

  // Datos seed → JSON de referencia + 001_seed.sql.
  const seedData: Record<string, Record<string, SeedValue>[]> = {};
  const sqlParts: string[] = [
    `-- 001_seed.sql — GENERADO por tool/mysql-schema-dump.ts desde la BD`,
    `-- Supabase (${ref}). Idempotente: INSERT IGNORE (re-ejecutar no duplica).`,
    `--`,
    `-- Solo seeds de configuración: roles, permisos, categorías, rutas y`,
    `-- planes de membresía. NO se migran usuarios, cursos ni pagos`,
    `-- (arranque limpio). path_courses queda vacía: depende de cursos que`,
    `-- aún no existen — se re-enlaza desde el panel admin (ver seed-source.json).`,
    ``,
    `SET NAMES utf8mb4;`,
    ``,
  ];

  for (const t of [...SEED_TABLES, ...REFERENCE_TABLES]) {
    const cols = columns.filter((c) => c.table_name === t);
    if (cols.length === 0) {
      console.log(`\n⚠️  Tabla seed ausente en Supabase, omitida: ${t}`);
      continue;
    }
    const rows = await fetchSeedRows(t, cols);
    seedData[t] = rows;
    const inSql = SEED_TABLES.includes(t);
    console.log(
      `\n🌱 ${t}: ${rows.length} filas → ${inSql ? '001_seed.sql' : 'solo seed-source.json (FK a cursos no migrados)'}`,
    );
    if (inSql && rows.length > 0) {
      sqlParts.push(`-- ${t} (${rows.length} filas)`);
      sqlParts.push(buildInsert(t, cols, rows));
      sqlParts.push('');
    }
  }

  await writeFile(
    path.join(outDir, 'seed-source.json'),
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        source: `supabase (${ref}) via pooler — solo lectura`,
        note: 'Datos seed crudos de referencia. 001_seed.sql es el derivado MySQL.',
        tables: seedData,
      },
      null,
      2,
    ),
  );

  const seedPath = path.join(outDir, '001_seed.sql');
  await writeFile(seedPath, sqlParts.join('\n'));

  console.log(`\n✅ Listo:`);
  console.log(`   sql-mysql/schema-source.json  (esquema completo)`);
  console.log(`   sql-mysql/seed-source.json    (datos seed crudos)`);
  console.log(`   sql-mysql/001_seed.sql        (INSERTs MySQL)`);
} finally {
  await client.end();
}
