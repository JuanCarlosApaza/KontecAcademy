/**
 * Helpers de lectura de payloads. De uso EXCLUSIVO de los DTOs:
 * toda interpretación de `body`/`query` ocurre aquí, nunca en los
 * casos de uso ni en los repositorios.
 */

/** Body/query a Record o null si no es un objeto. */
export function asRecord(body: unknown): Record<string, unknown> | null {
  return typeof body === 'object' && body !== null
    ? (body as Record<string, unknown>)
    : null;
}

/** Texto recortado, o null si está vacío/ausente. */
export function optionalText(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : null;
}
