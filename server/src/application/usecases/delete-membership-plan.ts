import type { MembershipRepository } from '../../domain/membership.js';

/** Caso de uso: borrar un plan de membresía (false si no existía). */
export class DeleteMembershipPlan {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'removePlan'>,
  ) {}

  execute(id: string): Promise<boolean> {
    return this.memberships.removePlan(id);
  }
}
