import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Item del carrito tal como llega del front. */
export interface CheckoutItemDTO {
  courseId: string;
  amount: number;
  /** 'course' (default) | 'path' | 'membership'. */
  type: 'course' | 'path' | 'membership';
}

/** Payload de inscripción (POST /checkout). */
export interface CreateCheckoutDTO {
  /** Si el front no lo envía, se usa el email de la sesión (JWT). */
  email: string;
  fullName: string;
  phone: string | null;
  nationality: string | null;
  documentNumber: string | null;
  items: CheckoutItemDTO[];
}

/**
 * Valida el body de POST /checkout. Lanza [ValidationError].
 * [fallbackEmail] es el email verificado del JWT de la sesión.
 */
export function parseCreateCheckoutDTO(
  body: unknown,
  fallbackEmail: string,
): CreateCheckoutDTO {
  const record = asRecord(body);
  const fullName = optionalText(record?.fullName);
  const email = optionalText(record?.email) ?? fallbackEmail;

  if (!fullName) {
    throw new ValidationError('El campo "fullName" es obligatorio');
  }
  if (!email.includes('@')) {
    throw new ValidationError('El campo "email" no es válido');
  }

  const rawItems = Array.isArray(record?.items) ? record.items : [];
  const items: CheckoutItemDTO[] = [];
  for (const raw of rawItems) {
    const item = asRecord(raw);
    const courseId = optionalText(item?.courseId);
    const amount = Number(item?.amount);
    const type = optionalText(item?.type) ?? 'course';

    if (!courseId || !Number.isFinite(amount) || amount < 0) {
      throw new ValidationError(
        'Cada item necesita "courseId" y un "amount" numérico ≥ 0',
      );
    }
    if (type !== 'course' && type !== 'path' && type !== 'membership') {
      throw new ValidationError(
        'El campo "type" debe ser course | path | membership',
      );
    }
    items.push({ courseId, amount, type });
  }

  if (items.length === 0) {
    throw new ValidationError('El carrito está vacío (items: [])');
  }

  return {
    email,
    fullName,
    phone: optionalText(record?.phone),
    nationality: optionalText(record?.nationality),
    documentNumber: optionalText(record?.documentNumber),
    items,
  };
}
