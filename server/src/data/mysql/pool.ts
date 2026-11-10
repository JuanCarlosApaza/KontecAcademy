import { createPool, type Pool, type PoolOptions } from 'mysql2/promise';

/**
 * Pool MySQL único para la API (patrón equivalente al cliente
 * Supabase que hoy se crea en cada repo). Se crea en el composition
 * root (index.ts) y se inyecta a los repos de la Fase 2.
 *
 * Convención de tipos (ver plan de migración):
 *  - `dateStrings: true` → mysql2 devuelve DATETIME como string
 *    'YYYY-MM-DD HH:MM:SS' en UTC, sin pasar por Date ni por la tz
 *    local de la máquina; los mappers `iso()` normalizan a ISO-8601.
 *  - Booleans: TINYINT(1) → `toBool()`.
 *  - UUIDs: CHAR(36) generados por la app (crypto.randomUUID).
 */

export type MysqlConfig = {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
};

export function createMysqlPool(config: MysqlConfig): Pool {
  const options: PoolOptions = {
    host: config.host,
    port: config.port,
    user: config.user,
    password: config.password,
    database: config.database,
    connectionLimit: 10,
    waitForConnections: true,
    // Devuelve fechas como string UTC; sin esto mysql2 convierte a
    // Date usando la tz local y desplaza las comparaciones.
    dateStrings: true,
    // Charset del proyecto (emoji/acentos en textos de cursos).
    charset: 'utf8mb4',
  };
  const pool = createPool(options);
  // Cada conexión nace en UTC: sin esto, CURRENT_TIMESTAMP guarda la
  // hora del servidor y rompe las comparaciones de membresías.
  pool.on('connection', (connection) => {
    void connection.query("SET time_zone = '+00:00'");
  });
  return pool;
}

/** Lee la config de MYSQL_* del entorno (ya cargado por dotenv). */
export function mysqlConfigFromEnv(): MysqlConfig | null {
  const host = process.env.MYSQL_HOST;
  const user = process.env.MYSQL_USER;
  const password = process.env.MYSQL_PASSWORD;
  const database = process.env.MYSQL_DATABASE;
  if (!host || !user || !password || !database) return null;
  return {
    host,
    port: Number(process.env.MYSQL_PORT ?? 3306),
    user,
    password,
    database,
  };
}

/**
 * SELECT genérico: `await query<Row>(pool, 'select … where id = ?', [id])`.
 * Devuelve solo las filas (mysql2 las tipa como RowDataPacket[]).
 */
export async function query<T>(
  pool: Pool,
  sql: string,
  params: unknown[] = [],
): Promise<T[]> {
  const [rows] = await pool.query<T[]>(sql, params);
  return rows;
}

/**
 * DATETIME (string UTC 'YYYY-MM-DD HH:MM:SS') → ISO-8601 con 'Z'.
 * Así siguen funcionando las comparaciones de string existentes
 * (`endDate > nowIso`) heredadas del código PostgREST.
 */
export function iso(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const s = String(value);
  if (s === '') return null;
  // 'YYYY-MM-DD HH:MM:SS' → 'YYYY-MM-DDTHH:MM:SS.sssZ'
  const normalized = s.replace(' ', 'T');
  const withMillis = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(normalized)
    ? `${normalized}.000Z`
    : normalized;
  return withMillis.endsWith('Z') ? withMillis : `${withMillis}Z`;
}

/** TINYINT(1) (0/1/'0'/'1') → boolean. */
export function toBool(value: unknown): boolean {
  return value === true || value === 1 || value === '1';
}

/** boolean → TINYINT(1) para parámetros de INSERT/UPDATE. */
export function fromBool(value: boolean): number {
  return value ? 1 : 0;
}
