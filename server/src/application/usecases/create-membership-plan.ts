import type { MembershipPlan, MembershipRepository } from '../../domain/membership.js';
import type { CreatePlanDTO } from '../dtos/membership_dto.js';

/** Caso de uso: crear un plan de membresía (panel). */
export class CreateMembershipPlan {
  constructor(
    private readonly memberships: Pick<MembershipRepository, 'createPlan'>,
  ) {}

  execute(dto: CreatePlanDTO): Promise<MembershipPlan> {
    return this.memberships.createPlan({
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
