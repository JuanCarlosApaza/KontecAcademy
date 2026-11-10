import type { MembershipPlan, MembershipRepository } from '../../domain/membership.js';

/**
 * Caso de uso: listado de planes de membresía.
 * Público → solo activos; panel → incluye inactivos.
 */
export class ListMembershipPlans {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'listPlans'>,
  ) {}

  execute(includeInactive = false): Promise<MembershipPlan[]> {
    return this.memberships.listPlans(includeInactive);
  }
}
