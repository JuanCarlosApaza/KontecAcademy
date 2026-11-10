/**
 * 🧱 DOMINIO — membresías (planes de acceso total a los cursos).
 *
 * membership_plans = los tipos (mensual /6 meses / anual…) que el
 * admin crea desde el panel. memberships = una fila por usuario con
 * fechas de control; 'active' dentro de su vigencia otorga acceso a
 * TODOS los cursos.
 */

/** Plan de membresía (tipo + precio). */
export interface MembershipPlan {
  id: string;
  slug: string;
  name: string;
  /** Duración en meses (1 | 6 | 12 …). */
  months: number;
  price: number;
  isActive: boolean;
  sortOrder: number;
  /** Imagen de la tarjeta pública (subida desde el panel). */
  imageUrl: string | null;
}

/** Estados posibles de una membresía. */
export type MembershipStatus =
  | 'pending_payment'
  | 'active'
  | 'rejected'
  | 'expired'
  | 'revoked';

/** Membresía de un usuario con su plan. */
export interface Membership {
  id: string;
  userId: string;
  /** Email del usuario (solo en el listado del panel; '' en el resto). */
  userEmail: string;
  planId: string;
  planName: string;
  months: number;
  price: number;
  status: MembershipStatus;
  /** Se fija al aprobar el ticket; null mientras está pendiente. */
  startDate: string | null;
  /** start_date + months; null mientras está pendiente. */
  endDate: string | null;
  paymentId: string | null;
  createdAt: string;
}

/**
 * ¿La membresía está ACTIVA en el instante [nowIso]?
 * Regla única: status 'active' + dentro de su vigencia.
 */
export function isActiveAt(
  membership: Pick<Membership, 'status' | 'startDate' | 'endDate'>,
  nowIso: string = new Date().toISOString(),
): boolean {
  if (membership.status !== 'active') return false;
  if (membership.endDate === null) return false;
  if (membership.endDate <= nowIso) return false;
  if (membership.startDate !== null && membership.startDate > nowIso) {
    return false;
  }
  return true;
}

/** Fin de vigencia: inicio + N meses (redondeo a días naturales). */
export function endDateOf(startDate: Date, months: number): string {
  const end = new Date(startDate);
  end.setUTCMonth(end.getUTCMonth() + months);
  return end.toISOString();
}

/** Datos para crear/editar un plan (formulario del panel). */
export interface NewPlanInput {
  slug: string;
  name: string;
  months: number;
  price: number;
  isActive: boolean;
  sortOrder: number;
  imageUrl: string | null;
}

/** Datos para otorgar/editar una membresía desde el panel. */
export interface NewMembershipInput {
  userId: string;
  planId: string;
  status: MembershipStatus;
  startDate: string | null;
  endDate: string | null;
}

/**
 * Contrato de membresías. Lo implementa Supabase (producción) y una
 * versión en memoria (tests / dev sin credenciales).
 */
export interface MembershipRepository {
  /** Planes (los activos para el público; todos si includeInactive). */
  listPlans(includeInactive?: boolean): Promise<MembershipPlan[]>;
  planById(id: string): Promise<MembershipPlan | null>;

  /** Membresías del panel (todas, con usuario y plan resueltos). */
  list(): Promise<Membership[]>;
  /** Membresía ACTIVA del usuario en [nowIso]; null si no tiene. */
  findActive(userId: string, nowIso?: string): Promise<Membership | null>;
  /** Membresía por id; null si no existe. */
  findById(id: string): Promise<Membership | null>;
  /** Membresía pendiente o activa del usuario (para bloquear doble compra). */
  findLatestOpen(userId: string): Promise<Membership | null>;

  createPlan(input: NewPlanInput): Promise<MembershipPlan>;
  updatePlan(
    id: string,
    input: NewPlanInput,
  ): Promise<MembershipPlan | null>;
  removePlan(id: string): Promise<boolean>;

  createMembership(input: NewMembershipInput): Promise<Membership>;
  updateMembership(
    id: string,
    patch: Partial<Pick<Membership, 'status' | 'startDate' | 'endDate'>>,
  ): Promise<Membership | null>;

  /** Crea la membresía PENDIENTE de pago (checkout); null si el plan no existe. */
  createPending(userId: string, planId: string): Promise<Membership | null>;

  /**
   * Aplica la decisión del admin sobre el pago de una membresía:
   * 'approved' → active con fechas (start=now, end=now+meses);
   * 'rejected' → rejected. Null si el pago no es de membresía.
   */
  decide(
    membershipId: string,
    decision: 'approved' | 'rejected',
  ): Promise<boolean>;
}
