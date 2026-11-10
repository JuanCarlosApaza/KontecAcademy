import { randomUUID } from 'node:crypto';
import {
  endDateOf,
  type Membership,
  type MembershipPlan,
  type MembershipRepository,
  type MembershipStatus,
  type NewMembershipInput,
  type NewPlanInput,
} from '../domain/membership.js';

/**
 * 🔌 DATOS — membresías en memoria (tests / dev sin Supabase).
 * Se siembra con los3 planes del seed real (mensual/semestral/anual)
 * para que las pruebas trabajen con los mismos tipos.
 */
export class InMemoryMembershipRepository implements MembershipRepository {
  private readonly plans: MembershipPlan[] = [
    {
      id: 'mem-plan-mensual',
      slug: 'mensual',
      name: 'Mensual',
      months: 1,
      price: 29,
      isActive: true,
      sortOrder: 0,
      imageUrl: null,
    },
    {
      id: 'mem-plan-semestral',
      slug: 'semestral',
      name: 'Semestral (6 meses)',
      months: 6,
      price: 149,
      isActive: true,
      sortOrder: 1,
      imageUrl: null,
    },
    {
      id: 'mem-plan-anual',
      slug: 'anual',
      name: 'Anual',
      months: 12,
      price: 249,
      isActive: true,
      sortOrder: 2,
      imageUrl: null,
    },
  ];

  private readonly memberships: Membership[] = [];

  async listPlans(includeInactive = false): Promise<MembershipPlan[]> {
    return this.plans
      .filter((plan) => includeInactive || plan.isActive)
      .sort((a, b) => a.sortOrder - b.sortOrder);
  }

  async planById(id: string): Promise<MembershipPlan | null> {
    return this.plans.find((plan) => plan.id === id) ?? null;
  }

  async list(): Promise<Membership[]> {
    return [...this.memberships].sort((a, b) =>
      b.createdAt.localeCompare(a.createdAt),
    );
  }

  async findActive(
    userId: string,
    nowIso: string = new Date().toISOString(),
  ): Promise<Membership | null> {
    const open = this.memberships.filter(
      (m) =>
        m.userId === userId &&
        m.status === 'active' &&
        m.endDate !== null &&
        m.endDate > nowIso &&
        (m.startDate === null || m.startDate <= nowIso),
    );
    open.sort((a, b) => (b.endDate ?? '').localeCompare(a.endDate ?? ''));
    return open[0] ?? null;
  }

  async findById(id: string): Promise<Membership | null> {
    return this.memberships.find((m) => m.id === id) ?? null;
  }

  async findLatestOpen(userId: string): Promise<Membership | null> {
    const open = this.memberships
      .filter(
        (m) =>
          m.userId === userId &&
          (m.status === 'pending_payment' || m.status === 'active'),
      )
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    return open[0] ?? null;
  }

  async createPlan(input: NewPlanInput): Promise<MembershipPlan> {
    const plan: MembershipPlan = {
      id: randomUUID(),
      slug: input.slug,
      name: input.name,
      months: input.months,
      price: input.price,
      isActive: input.isActive,
      sortOrder: input.sortOrder,
      imageUrl: input.imageUrl,
    };
    this.plans.push(plan);
    return plan;
  }

  async updatePlan(
    id: string,
    input: NewPlanInput,
  ): Promise<MembershipPlan | null> {
    const index = this.plans.findIndex((plan) => plan.id === id);
    if (index < 0) return null;

    const updated: MembershipPlan = {
      ...this.plans[index]!,
      slug: input.slug,
      name: input.name,
      months: input.months,
      price: input.price,
      isActive: input.isActive,
      sortOrder: input.sortOrder,
      imageUrl: input.imageUrl,
    };
    this.plans[index] = updated;
    return updated;
  }

  async removePlan(id: string): Promise<boolean> {
    const index = this.plans.findIndex((plan) => plan.id === id);
    if (index < 0) return false;
    // Membresías del plan caen en cascada (paridad con la BD).
    for (let i = this.memberships.length - 1; i >= 0; i--) {
      if (this.memberships[i]!.planId === id) this.memberships.splice(i, 1);
    }
    this.plans.splice(index, 1);
    return true;
  }

  async createMembership(input: NewMembershipInput): Promise<Membership> {
    const plan = await this.planById(input.planId);
    if (!plan) {
      throw new Error(`Plan no encontrado: ${input.planId}`);
    }
    return this.insert(input.userId, plan, input);
  }

  async updateMembership(
    id: string,
    patch: Partial<Pick<Membership, 'status' | 'startDate' | 'endDate'>>,
  ): Promise<Membership | null> {
    const index = this.memberships.findIndex((m) => m.id === id);
    if (index < 0) return null;

    const current = this.memberships[index]!;
    const updated: Membership = {
      ...current,
      status: (patch.status ?? current.status) as MembershipStatus,
      startDate: patch.startDate !== undefined ? patch.startDate : current.startDate,
      endDate: patch.endDate !== undefined ? patch.endDate : current.endDate,
    };
    this.memberships[index] = updated;
    return updated;
  }

  async createPending(
    userId: string,
    planId: string,
  ): Promise<Membership | null> {
    const plan = await this.planById(planId);
    if (!plan) return null;

    return this.insert(userId, plan, {
      userId,
      planId,
      status: 'pending_payment',
      startDate: null,
      endDate: null,
    });
  }

  async decide(
    membershipId: string,
    decision: 'approved' | 'rejected',
  ): Promise<boolean> {
    const index = this.memberships.findIndex((m) => m.id === membershipId);
    if (index < 0) return false;

    const current = this.memberships[index]!;
    if (decision === 'rejected') {
      this.memberships[index] = { ...current, status: 'rejected' };
      return true;
    }

    const start = new Date();
    this.memberships[index] = {
      ...current,
      status: 'active',
      startDate: start.toISOString(),
      endDate: endDateOf(start, current.months),
    };
    return true;
  }

  /** Inserta una membresía con el plan resuelto (paridad con el embed). */
  private insert(
    userId: string,
    plan: MembershipPlan,
    input: NewMembershipInput,
  ): Membership {
    const membership: Membership = {
      id: randomUUID(),
      userId,
      userEmail: '',
      planId: plan.id,
      planName: plan.name,
      months: plan.months,
      price: plan.price,
      status: input.status,
      startDate: input.startDate,
      endDate: input.endDate,
      paymentId: null,
      createdAt: new Date().toISOString(),
    };
    this.memberships.push(membership);
    return membership;
  }
}
