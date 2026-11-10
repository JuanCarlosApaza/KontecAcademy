import 'dotenv/config';
import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { Client } from 'pg';

/**
 * Aplica las migraciones pendientes de sql/ usando el POOLER IPv4
 * (aws-1-us-west-2), porque el host directo db.* de este proyecto solo
 * tiene AAAA y esta máquina no tiene IPv6. Misma lógica que
 * tool/db-sql.ts --migrate (tabla _migrations, transacción por archivo).
 */

const dbUrl = process.env.SUPABASE_DB_URL;
if (!dbUrl) {
  console.error('Falta SUPABASE_DB_URL en server/.env');
  process.exit(1);
}
const u = new URL(dbUrl);
const ref = new URL(process.env.SUPABASE_URL!).hostname.split('.')[0]!;

const client = new Client({
  host: 'aws-1-us-west-2.pooler.supabase.com',
  port: 6543,
  user: `postgres.${ref}`,
  password: decodeURIComponent(u.password),
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
});

await client.connect();

await client.query(
  `create table if not exists _migrations (
     name text primary key,
     applied_at timestamptz not null default now()
   )`,
);

const dir = path.join(process.cwd(), 'sql');
const files = (await readdir(dir)).filter((n) => n.endsWith('.sql')).sort();
const { rows } = await client.query<{ name: string }>('select name from _migrations');
const applied = new Set(rows.map((r) => r.name));
const pending = files.filter((n) => !applied.has(n));

if (pending.length === 0) {
  console.log(`✅ Migraciones al día (${files.length} aplicadas)`);
  await client.end();
  process.exit(0);
}

console.log(`Pendientes: ${pending.join(', ')}`);

for (const name of pending) {
  const sql = await readFile(path.join(dir, name), 'utf8');
  console.log(`⏳ Aplicando ${name}…`);
  try {
    await client.query('begin');
    await client.query(sql);
    await client.query('insert into _migrations (name) values ($1)', [name]);
    await client.query('commit');
    console.log(`✅ ${name} aplicada`);
  } catch (e) {
    await client.query('rollback');
    console.error(`❌ ${name} revertida: ${(e as Error).message}`);
    await client.end();
    process.exit(1);
  }
}

await client.end();
console.log('Listo.');
