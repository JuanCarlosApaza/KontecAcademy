import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Acción manual del admin sobre un pago. */
export type PaymentAction = 'approve' | 'reject';

/** Body de PATCH /admin/payments/:id. */
export interface PaymentDecisionDTO {
  action: PaymentAction;
}

/** Estado que se persiste en la BD para cada acción del admin. */
export const STATUS_OF_ACTION: Record<PaymentAction, string> = {
  approve: 'approved',
  reject: 'rejected',
};

/**
 * Valida el body de PATCH /admin/payments/:id. Lanza [ValidationError].
 * El id viene en la ruta; aquí solo se valida la acción.
 */
export function parsePaymentDecisionDTO(body: unknown): PaymentDecisionDTO {
  const record = asRecord(body);
  const action = optionalText(record?.action);

  if (action !== 'approve' && action !== 'reject') {
    throw new ValidationError('"action" debe ser "approve" o "reject"');
  }
  return { action };
}
