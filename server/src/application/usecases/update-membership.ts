import type {
  Membership,
  MembershipRepository,
} from '../../domain/membership.js';
import type { UpdateMembershipDTO } from '../dtos/membership_dto.js';

/** Caso de uso: editar estado/fechas de una membresía (panel). */
export class UpdateMembership {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'updateMembership'>,
  ) {}

  execute(dto: UpdateMembershipDTO): Promise<Membership | null> {
    return this.memberships.updateMembership(dto.id, {
      ...(dto.status !== undefined ? { status: dto.status } : {}),
      ...(dto.startDate !== undefined ? { startDate: dto.startDate } : {}),
      ...(dto.endDate !== undefined ? { endDate: dto.endDate } : {}),
    });
  }
}
