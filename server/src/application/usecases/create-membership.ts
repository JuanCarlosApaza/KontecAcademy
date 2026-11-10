import { endDateOf } from '../../domain/membership.js';
import type {
  Membership,
  MembershipRepository,
} from '../../domain/membership.js';
import { ValidationError } from '../errors.js';
import type { CreateMembershipDTO } from '../dtos/membership_dto.js';

/**
 * Caso de uso: otorgar una membresía MANUAL desde el panel (regalar /
 * corregir). Si el estado es 'active' y no vienen fechas, se calculan
 * desde ahora + meses del plan (misma regla que la aprobación de un
 * pago).
 */
export class CreateMembership {
  constructor(
    private readonly memberships: Pick<
      MembershipRepository,
      'planById' | 'createMembership'
    >,
  ) {}

  async execute(dto: CreateMembershipDTO): Promise<Membership> {
    const plan = await this.memberships.planById(dto.planId);
    if (!plan) {
      throw new ValidationError('El plan no existe.');
    }

    let startDate = dto.startDate;
    let endDate = dto.endDate;

    if (dto.status === 'active') {
      const start = startDate ? new Date(startDate) : new Date();
      startDate = start.toISOString();
      endDate = endDate ?? endDateOf(start, plan.months);
    }

    return this.memberships.createMembership({
      userId: dto.userId,
      planId: dto.planId,
      status: dto.status,
      startDate: startDate ?? null,
      endDate: endDate ?? null,
    });
  }
}
