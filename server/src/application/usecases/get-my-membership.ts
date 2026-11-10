import type {
  AuthenticatedUser,
} from '../../domain/checkout.js';
import type {
  Membership,
  MembershipRepository,
} from '../../domain/membership.js';

/** Caso de uso: membresía ACTIVA del usuario de la sesión (banner). */
export class GetMyMembership {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'findActive'>,
  ) {}

  execute(user: AuthenticatedUser): Promise<Membership | null> {
    return this.memberships.findActive(user.id);
  }
}
