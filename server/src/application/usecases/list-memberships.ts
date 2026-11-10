import type { Membership, MembershipRepository } from '../../domain/membership.js';

/** Caso de uso: listado de membresías (panel, todas). */
export class ListMemberships {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'list'>,
  ) {}

  execute(): Promise<Membership[]> {
    return this.memberships.list();
  }
}
