import { ValidationError } from '../errors.js';
import { asRecord } from './parse.js';

/** Estados de pago que admite el listado del panel. */
const PAYMENT_STATUSES = ['pending_approval', 'approved', 'rejected'];

/** Filtros de GET /admin/payments (?status=). */
export interface ListPaymentsDTO {
  /** Por defecto 'pending_approval' (la cola que revisa el admin). */
  status: string;
}

/** Valida el query string de GET /admin/payments. Lanza [ValidationError]. */
export function parseListPaymentsDTO(query: unknown): ListPaymentsDTO {
  const record = asRecord(query);

  if (record?.status === undefined) {
    return { status: 'pending_approval' };
  }

  const status = typeof record.status === 'string' ? record.status : '';
  if (!PAYMENT_STATUSES.includes(status)) {
    throw new ValidationError(
      '"status" debe ser pending_approval, approved o rejected',
    );
  }
  return { status };
}
