/**
 * Normaliza la `data` de PostgREST a un arreglo de filas tipadas `T[]`.
 *
 * Sin tipos generados de la BD, supabase-js infiere la forma de los
 * embeds (`courses (…)` dentro de un select) con una estructura que no
 * siempre coincide con la real: muchos-a-uno llega como **objeto** y lo
 * infiere como array (y viceversa en uno-a-muchos). Este guard devuelve
 * `T[]` con un único cast documentado AQUÍ, en lugar del doble cast
 * `as unknown as <Row[]>` repetido en cada repositorio.
 *
 * `null` (sin filas) → `[]`, así los call sites ya no necesitan `?? []`.
 */
export function asRows<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[];
  if (data === null || data === undefined) return [];
  // Consultas puntuales (`single()` / embed suelto) devuelven el objeto.
  return [data as T];
}
