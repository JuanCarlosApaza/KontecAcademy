import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Payload de creación de plan (POST /admin/membership-plans). */
export interface CreatePlanDTO {
  name: string;
  slug?: string;
  months: number;
  price: number;
  isActive: boolean;
  sortOrder: number;
  /** Imagen de la tarjeta pública (URL del bucket) o null. */
  imageUrl: string | null;
}

function optionalInt(
  value: unknown,
  field: string,
  { min = 0 }: { min?: number } = {},
): number | null {
  if (value === undefined || value === null || value === '') return null;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min) {
    throw new ValidationError(
      `El campo "${field}" debe ser un entero mayor o igual a ${min}`,
    );
  }
  return parsed;
}

/** Valida el body de creación/edición de un plan de membresía. */
export function parseCreatePlanDTO(body: unknown): CreatePlanDTO {
  const record = asRecord(body);
  const name = optionalText(record?.name);

  if (!name) {
    throw new ValidationError('El campo "name" es obligatorio');
  }

  const months = optionalInt(record?.months, 'months', { min: 1 }) ?? 1;
  const price = Number(record?.price ?? 0);
  if (!Number.isFinite(price) || price < 0) {
    throw new ValidationError('El campo "price" debe ser un número ≥ 0');
  }

  return {
    name,
    slug: optionalText(record?.slug) ?? undefined,
    months,
    price,
    isActive:
      typeof record?.isActive === 'boolean' ? record.isActive : true,
    sortOrder: optionalInt(record?.sortOrder, 'sortOrder') ?? 0,
    imageUrl: optionalText(record?.imageUrl),
  };
}

/** Payload de edición (PATCH /admin/membership-plans/:id). */
export interface UpdatePlanDTO extends CreatePlanDTO {
  id: string;
}

export function parseUpdatePlanDTO(
  id: string,
  body: unknown,
): UpdatePlanDTO {
  return { id, ...parseCreatePlanDTO(body) };
}

/** Payload de alta manual de membresía (POST /admin/memberships). */
export interface CreateMembershipDTO {
  userId: string;
  planId: string;
  status: 'active' | 'pending_payment';
  startDate: string | null;
  endDate: string | null;
}

export function parseCreateMembershipDTO(
  body: unknown,
): CreateMembershipDTO {
  const record = asRecord(body);
  const userId = optionalText(record?.userId);
  const planId = optionalText(record?.planId);

  if (!userId) {
    throw new ValidationError('El campo "userId" es obligatorio');
  }
  if (!planId) {
    throw new ValidationError('El campo "planId" es obligatorio');
  }

  const status = optionalText(record?.status) ?? 'active';
  if (status !== 'active' && status !== 'pending_payment') {
    throw new ValidationError(
      'El campo "status" debe ser active | pending_payment',
    );
  }

  return {
    userId,
    planId,
    status,
    startDate: optionalText(record?.startDate),
    endDate: optionalText(record?.endDate),
  };
}

/** Payload de edición de membresía (PATCH /admin/memberships/:id). */
export interface UpdateMembershipDTO {
  id: string;
  status?: 'active' | 'pending_payment' | 'rejected' | 'expired' | 'revoked';
  startDate?: string | null;
  endDate?: string | null;
}

export function parseUpdateMembershipDTO(
  id: string,
  body: unknown,
): UpdateMembershipDTO {
  const record = asRecord(body);
  const status = optionalText(record?.status);

  if (
    status !== null &&
    status !== 'active' &&
    status !== 'pending_payment' &&
    status !== 'rejected' &&
    status !== 'expired' &&
    status !== 'revoked'
  ) {
    throw new ValidationError(
      'El campo "status" no es válido (pending_payment | active | rejected | expired | revoked)',
    );
  }

  return {
    id,
    ...(status !== null ? { status } : {}),
    ...(record !== null && 'startDate' in record
      ? { startDate: (record.startDate as string | null) ?? null }
      : {}),
    ...(record !== null && 'endDate' in record
      ? { endDate: (record.endDate as string | null) ?? null }
      : {}),
  };
}
