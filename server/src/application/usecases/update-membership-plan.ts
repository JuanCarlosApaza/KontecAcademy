import type { MembershipPlan, MembershipRepository } from '../../domain/membership.js';
import type { UpdatePlanDTO } from '../dtos/membership_dto.js';

/** Caso de uso: editar un plan de membresía (null si no existe). */
export class UpdateMembershipPlan {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'updatePlan'>,
  ) {}

  execute(dto: UpdatePlanDTO): Promise<MembershipPlan | null> {
    return this.memberships.updatePlan(dto.id, {
      slug: dto.slug ?? dto.name.trim().toLowerCase().replace(/\s+/g, '-'),
      name: dto.name,
      months: dto.months,
      price: dto.price,
      isActive: dto.isActive,
      sortOrder: dto.sortOrder,
      imageUrl: dto.imageUrl,
    });
  }
}
