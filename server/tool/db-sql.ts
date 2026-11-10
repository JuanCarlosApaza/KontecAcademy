import 'dotenv/config';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { Client } from 'pg';

/**
 * 🛠️ CONSULTA Y MODIFICACIÓN DIRECTA DE LA BD (Supabase Postgres).
 *
 * Ya no hace falta entrar al SQL Editor de Supabase para operar la BD
 * desde el backend. Requiere `SUPABASE_DB_URL` en `server/.env`
 * (Supabase → Project Settings → Database → Connection string → URI
 * del modo "Direct connection", usuario `postgres`).
 *
 * Uso (dentro de server/):
 *   npm run db:sql -- "select id, email from public.users limit 10"
 *   npm run db:sql -- --file sql/004_create_carts.sql
 *   npm run db:sql -- --migrate      # aplica TODAS las migraciones pendientes
 *
 * `--migrate` ejecuta en orden cada archivo de `sql/*.sql` que aún no
 * se haya aplicado (control en la tabla `_migrations`); cada archivo
 * corre en su propia transacción: si algo falla, esa migración entera
 * se revierte y se detiene el proceso.
 */

const USAGE = `
Uso:
  npm run db:sql -- "select * from public.courses limit 5"   # SQL en línea
  npm run db:sql -- --file sql/004_create_carts.sql          # ejecuta un archivo
  npm run db:sql -- --migrate                               # migraciones pendientes
`;

function fail(message: string): never {
  console.error(`❌ ${message}`);
  process.exit(1);
}

const dbUrl = process.env.SUPABASE_DB_URL;
if (!dbUrl) {
  fail(
    'Falta SUPABASE_DB_URL en server/.env\n' +
      '   → Supabase → Project Settings → Database → Connection string → URI\n' +
      '   → modo "Direct connection" (usuario postgres).',
  );
}

/** Conexión efímera: cierra siempre al terminar (success o error). */
async function withClient<T>(run: (client: Client) => Promise<T>): Promise<T> {
  const client = new Client({
    connectionString: dbUrl,
    // Supabase exige SSL; su certificado no está en el store del SO.
    ssl: dbUrl.includes('localhost')
      ? undefined
      : { rejectUnauthorized: false },
  });

  await client.connect();
  try {
    return await run(client);
  } finally {
    await client.end();
  }
}

/** Imprime el resultado de una consulta como tabla legible. */
function printRows(command: string, rows: Record<string, unknown>[]) {
  if (rows.length === 0) {
    console.log(`✅ ${command} — 0 filas`);
    return;
  }
  // Objetos/arrays en una celda legible (console.table los larga solos).
  const flat = rows.map((row) =>
    Object.fromEntries(
      Object.entries(row).map(([key, value]) => [
        key,
        typeof value === 'object' && value !== null
          ? JSON.stringify(value)
          : value,
      ]),
    ),
  );
  console.table(flat);
  console.log(`✅ ${rows.length} fila(s)`);
}

/** Ejecuta UNA consulta (SELECT u otra) y muestra el resultado. */
async function runSql(client: Client, sql: string): Promise<void> {
  const result = await client.query(sql);
  for (const batch of Array.isArray(result) ? result : [result]) {
    if (batch.rows.length > 0) {
      printRows(batch.command, batch.rows as Record<string, unknown>[]);
    } else {
      console.log(`✅ ${batch.command} — ${batch.rowCount ?? 0} fila(s) afectadas`);
    }
  }
}

/** Aplica en orden todas las migraciones de sql/*.sql pendientes. */
async function runMigrations(client: Client): Promise<void> {
  await client.query(
    `create table if not exists _migrations (
       name text primary key,
       applied_at timestamp with time zone not null default now()
     )`,
  );

  const dir = path.join(process.cwd(), 'sql');
  const files = (await readdir(dir))
    .filter((name) => name.endsWith('.sql'))
    .sort();

  const { rows } = await client.query<{ name: string }>(
    'select name from _migrations',
  );
  const applied = new Set(rows.map((row) => row.name));

  const pending = files.filter((name) => !applied.has(name));
  if (pending.length === 0) {
    console.log(`✅ Migraciones al día (${files.length} aplicadas)`);
    return;
  }

  for (const name of pending) {
    const sql = await readFile(path.join(dir, name), 'utf8');
    console.log(`⏳ Aplicando ${name}…`);
    try {
      await client.query('begin');
      await client.query(sql);
      await client.query('insert into _migrations (name) values ($1)', [name]);
      await client.query('commit');
      console.log(`✅ ${name} aplicada`);
    } catch (error) {
      await client.query('rollback');
      const message = error instanceof Error ? error.message : String(error);
      fail(`${name} falló y fue REVERTIDA: ${message}`);
    }
  }
}

// ── CLI ────────────────────────────────────────────────────────────
const args = process.argv.slice(2);

try {
  await withClient(async (client) => {
    if (args[0] === '--migrate') {
      await runMigrations(client);
      return;
    }

    if (args[0] === '--file') {
      const file = args[1];
      if (!file) fail('--file requiere la ruta de un archivo .sql\n' + USAGE);
      const sql = await readFile(path.resolve(file), 'utf8');
      await runSql(client, sql);
      return;
    }

    const sql = args.join(' ').trim();
    if (sql.length === 0) fail('Falta el SQL a ejecutar.\n' + USAGE);
    await runSql(client, sql);
  });
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  fail(message);
}
