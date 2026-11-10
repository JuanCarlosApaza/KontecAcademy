import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import {
  endDateOf,
  type Membership,
  type MembershipPlan,
  type MembershipRepository,
  type MembershipStatus,
  type NewMembershipInput,
  type NewPlanInput,
} from '../domain/membership.js';
import { asRows } from './postgrest-rows.js';

/** Fila de `membership_plans`. */
interface PlanRow {
  id: string;
  slug: string;
  name: string;
  months: number;
  price: number | string;
  is_active: boolean;
  sort_order: number;
  image_url: string | null;
}

/** Plan embebido dentro de `memberships`. */
interface EmbeddedPlan {
  id: string;
  name: string;
  months: number;
  price: number | string;
}

/** Fila de `memberships` con su plan embebido. */
interface MembershipRow {
  id: string;
  user_id: string;
  plan_id: string;
  status: string;
  start_date: string | null;
  end_date: string | null;
  payment_id: string | null;
  created_at: string;
  membership_plans: EmbeddedPlan | EmbeddedPlan[] | null;
}

/** Relación membership → users (perfil corto para el panel). */
interface UserContactRow {
  id: string;
  email: string | null;
  full_name: string | null;
}

const PLAN_SELECT = '*';
const MEMBERSHIP_SELECT = '*, membership_plans(id, name, months, price)';

function toPlan(row: PlanRow): MembershipPlan {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    months: row.months,
    price: Number(row.price),
    isActive: row.is_active,
    sortOrder: row.sort_order,
    imageUrl: row.image_url ?? null,
  };
}

function toMembership(
  row: MembershipRow,
  userEmail = '',
): Membership {
  // El embed many-to-one puede venir como objeto O como array de1.
  const embedded = Array.isArray(row.membership_plans)
    ? row.membership_plans[0]
    : row.membership_plans;

  return {
    id: row.id,
    userId: row.user_id,
    userEmail,
    planId: row.plan_id,
    planName: embedded?.name ?? '',
    months: embedded?.months ?? 0,
    price: embedded ? Number(embedded.price) : 0,
    status: row.status as MembershipStatus,
    startDate: row.start_date,
    endDate: row.end_date,
    paymentId: row.payment_id,
    createdAt: row.created_at,
  };
}

/**
 * 🔌 DATOS — membresías con Supabase (Postgres).
 * Service Role Key solo en el servidor. Es el ÚNICO lugar que conoce
 * el esquema snake_case de estas tablas.
 */
export class SupabaseMembershipRepository implements MembershipRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async listPlans(includeInactive = false): Promise<MembershipPlan[]> {
    let query = this.client
      .from('membership_plans')
      .select(PLAN_SELECT)
      .order('sort_order', { ascending: true });

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Supabase listPlans: ${error.message}`);
    }
    return asRows<PlanRow>(data).map(toPlan);
  }

  async planById(id: string): Promise<MembershipPlan | null> {
    const { data, error } = await this.client
      .from('membership_plans')
      .select(PLAN_SELECT)
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase planById: ${error.message}`);
    }
    return data ? toPlan(data as PlanRow) : null;
  }

  async list(): Promise<Membership[]> {
    const { data, error } = await this.client
      .from('memberships')
      .select(MEMBERSHIP_SELECT)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase listMemberships: ${error.message}`);
    }

    const rows = asRows<MembershipRow>(data);
    const userIds = [...new Set(rows.map((row) => row.user_id))];

    // Perfiles aparte (user_id apunta a auth.users; el perfil corto
    // vive en public.users — mismo patrón que los carritos).
    const contacts = new Map<string, string>();
    if (userIds.length > 0) {
      const { data: users, error: usersError } = await this.client
        .from('users')
        .select('id, email')
        .in('id', userIds);

      if (usersError) {
        throw new Error(`Supabase listMemberships (users): ${usersError.message}`);
      }
      for (const row of asRows<UserContactRow>(users)) {
        contacts.set(row.id, row.email ?? '');
      }
    }

    return rows.map((row) => toMembership(row, contacts.get(row.user_id) ?? ''));
  }

  async findActive(
    userId: string,
    nowIso: string = new Date().toISOString(),
  ): Promise<Membership | null> {
    const { data, error } = await this.client
      .from('memberships')
      .select(MEMBERSHIP_SELECT)
      .eq('user_id', userId)
      .eq('status', 'active')
      .not('end_date', 'is', null)
      .gt('end_date', nowIso)
      .order('end_date', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findActiveMembership: ${error.message}`);
    }
    return data ? toMembership(data as MembershipRow) : null;
  }

  async findById(id: string): Promise<Membership | null> {
    const { data, error } = await this.client
      .from('memberships')
      .select(MEMBERSHIP_SELECT)
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findMembershipById: ${error.message}`);
    }
    return data ? toMembership(data as MembershipRow) : null;
  }

  async findLatestOpen(userId: string): Promise<Membership | null> {
    const { data, error } = await this.client
      .from('memberships')
      .select(MEMBERSHIP_SELECT)
      .eq('user_id', userId)
      .in('status', ['pending_payment', 'active'])
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findLatestOpenMembership: ${error.message}`);
    }
    return data ? toMembership(data as MembershipRow) : null;
  }

  async createPlan(input: NewPlanInput): Promise<MembershipPlan> {
    const { data, error } = await this.client
      .from('membership_plans')
      .insert({
        slug: input.slug,
        name: input.name,
        months: input.months,
        price: input.price,
        is_active: input.isActive,
        sort_order: input.sortOrder,
        image_url: input.imageUrl,
      })
      .select('*')
      .single();

    if (error) {
      throw new Error(`Supabase createPlan: ${error.message}`);
    }
    return toPlan(data as PlanRow);
  }

  async updatePlan(
    id: string,
    input: NewPlanInput,
  ): Promise<MembershipPlan | null> {
    const { data, error } = await this.client
      .from('membership_plans')
      .update({
        slug: input.slug,
        name: input.name,
        months: input.months,
        price: input.price,
        is_active: input.isActive,
        sort_order: input.sortOrder,
        image_url: input.imageUrl,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updatePlan: ${error.message}`);
    }
    return data ? toPlan(data as PlanRow) : null;
  }

  async removePlan(id: string): Promise<boolean> {
    const { data, error } = await this.client
      .from('membership_plans')
      .delete()
      .eq('id', id)
      .select('id');

    if (error) {
      throw new Error(`Supabase removePlan: ${error.message}`);
    }
    return (data ?? []).length > 0;
  }

  async createMembership(input: NewMembershipInput): Promise<Membership> {
    const { data, error } = await this.client
      .from('memberships')
      .insert({
        user_id: input.userId,
        plan_id: input.planId,
        status: input.status,
        start_date: input.startDate,
        end_date: input.endDate,
      })
      .select(MEMBERSHIP_SELECT)
      .single();

    if (error) {
      throw new Error(`Supabase createMembership: ${error.message}`);
    }
    return toMembership(data as MembershipRow);
  }

  async updateMembership(
    id: string,
    patch: Partial<Pick<Membership, 'status' | 'startDate' | 'endDate'>>,
  ): Promise<Membership | null> {
    const { data, error } = await this.client
      .from('memberships')
      .update({
        ...(patch.status !== undefined ? { status: patch.status } : {}),
        ...(patch.startDate !== undefined
          ? { start_date: patch.startDate }
          : {}),
        ...(patch.endDate !== undefined ? { end_date: patch.endDate } : {}),
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select(MEMBERSHIP_SELECT)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updateMembership: ${error.message}`);
    }
    return data ? toMembership(data as MembershipRow) : null;
  }

  async createPending(
    userId: string,
    planId: string,
  ): Promise<Membership | null> {
    // El plan debe existir (el FK también lo garantiza).
    const plan = await this.planById(planId);
    if (!plan) return null;

    const { data, error } = await this.client
      .from('memberships')
      .insert({
        user_id: userId,
        plan_id: planId,
        status: 'pending_payment',
      })
      .select(MEMBERSHIP_SELECT)
      .single();

    if (error) {
      throw new Error(`Supabase createPendingMembership: ${error.message}`);
    }
    return toMembership(data as MembershipRow);
  }

  async decide(
    membershipId: string,
    decision: 'approved' | 'rejected',
  ): Promise<boolean> {
    const membership = await this.findById(membershipId);
    if (!membership) return false;

    if (decision === 'rejected') {
      const { error } = await this.client
        .from('memberships')
        .update({ status: 'rejected', updated_at: new Date().toISOString() })
        .eq('id', membershipId);
      if (error) {
        throw new Error(`Supabase decideMembership: ${error.message}`);
      }
      return true;
    }

    // Aprobada: activa DESDE AHORA y vigente N meses.
    const start = new Date();
    const { error } = await this.client
      .from('memberships')
      .update({
        status: 'active',
        start_date: start.toISOString(),
        end_date: endDateOf(start, membership.months),
        updated_at: new Date().toISOString(),
      })
      .eq('id', membershipId);

    if (error) {
      throw new Error(`Supabase decideMembership: ${error.message}`);
    }
    return true;
  }
}
