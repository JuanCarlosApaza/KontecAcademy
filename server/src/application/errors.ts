/**
 * 🧠 APLICACIÓN — errores del flujo de casos de uso.
 *
 * El adaptador HTTP (`app.ts`) los traduce a códigos de estado:
 * `ValidationError` → 400. Los errores de repositorio (BD/red) se
 * propagan sin capturar y el middleware final responde 500.
 */
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

/** Acceso denegado (pago no aprobado) → 403. */
export class AccessDeniedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AccessDeniedError';
  }
}
