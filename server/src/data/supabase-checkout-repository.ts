import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type {
  AuthenticatedUser,
  CheckoutInput,
  CheckoutRepository,
  CheckoutResult,
  EnrolledCourse,
  EnrollmentRecord,
  PaymentRecord,
} from '../domain/checkout.js';

interface EnrollmentRow {
  id: string;
  user_id: string;
  course_id: string;
  status: string;
}

interface PaymentRow {
  id: string;
  enrollment_id: string | null;
  amount: number | string;
  status: string;
}

/** Fila de `enrollments` con el curso embebido (join muchos-a-uno). */
interface EnrolledCourseRow {
  course_id: string;
  status: string;
  enrolled_at: string | null;
  courses: {
    title: string;
    description: string | null;
    image_url: string | null;
    modality: string;
  } | null;
}

/**
 * 🔌 DATOS — checkout con Supabase (Postgres + GoTrue).
 *
 * Usa la Service Role Key SOLO en el servidor: con ella escribe en
 * `users`, `enrollments` y `payments`. El front solo manda su JWT de
 * Supabase, que se verifica con auth.getUser.
 *
 * ⚠️ Requiere la migración server/sql/002_add_user_document.sql
 * (agrega `document_number` a public.users). Si aún no se ejecutó,
 * se guarda todo menos el documento (fallback automático).
 */
import {
  permissionCodesOf,
  roleNamesOf,
  type RolePermissionRow,
  type UserRoleRow,
} from './role-rows.js';
import { asRows } from './postgrest-rows.js';

export class SupabaseCheckoutRepository implements CheckoutRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async verifyToken(token: string): Promise<AuthenticatedUser | null> {
    const { data, error } = await this.client.auth.getUser(token);
    if (error || !data.user) return null;
    return { id: data.user.id, email: data.user.email ?? '' };
  }

  async getRoles(userId: string): Promise<string[]> {
    const { data, error } = await this.client
      .from('user_roles')
      .select('roles(name)')
      .eq('user_id', userId);

    if (error) {
      throw new Error(`Supabase getRoles: ${error.message}`);
    }

    // El join `roles(name)` trae roles como objeto (muchos-a-uno).
    const rows = asRows<UserRoleRow>(data);

    return rows.flatMap(roleNamesOf);
  }

  /**
   * Códigos de permiso del usuario. El rol `admin` recibe el catálogo
   * COMPLETO (bypass calculado: no depende de `role_permissions`, así un
   * admin no puede autobloquearse ni hay que sembrar grants por rol).
   * El resto: `user_roles → role_permissions → permissions(code)`.
   */
  async getPermissions(userId: string): Promise<string[]> {
    const roles = await this.getRoles(userId);

    if (roles.includes('admin')) {
      const { data, error } = await this.client
        .from('permissions')
        .select('code');

      if (error) {
        throw new Error(`Supabase getPermissions: ${error.message}`);
      }
      return asRows<{ code: string }>(data).map((row) => row.code);
    }

    const { data: roleRows, error: roleError } = await this.client
      .from('user_roles')
      .select('role_id')
      .eq('user_id', userId);

    if (roleError) {
      throw new Error(`Supabase getPermissions: ${roleError.message}`);
    }

    const roleIds = asRows<{ role_id: string }>(roleRows).map(
      (row) => row.role_id,
    );
    if (roleIds.length === 0) return [];

    // Dos consultas en vez de un embed de 3 niveles: más previsible
    // ante los cambios del schema cache de PostgREST.
    const { data: permRows, error: permError } = await this.client
      .from('role_permissions')
      .select('permissions(code)')
      .in('role_id', roleIds);

    if (permError) {
      throw new Error(`Supabase getPermissions: ${permError.message}`);
    }

    const codes = asRows<RolePermissionRow>(permRows).flatMap(
      permissionCodesOf,
    );
    return [...new Set(codes)];
  }

  async getPathCourseIds(pathId: string): Promise<string[] | null> {
    const { data, error } = await this.client
      .from('learning_paths')
      .select('id')
      .eq('id', pathId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase getPathCourseIds: ${error.message}`);
    }
    if (!data) return null;

    const { data: rows, error: coursesError } = await this.client
      .from('path_courses')
      .select('course_id')
      .eq('path_id', pathId)
      .order('sort_order', { ascending: true });

    if (coursesError) {
      throw new Error(`Supabase getPathCourseIds: ${coursesError.message}`);
    }

    return (rows ?? []).map(
      (row) => (row as { course_id: string }).course_id,
    );
  }

  async createCheckout(input: CheckoutInput): Promise<CheckoutResult> {
    await this.upsertUser(input);

    const enrollments: EnrollmentRecord[] = [];
    const payments: PaymentRecord[] = [];
    let total = 0;

    for (const item of input.items) {
      // ── MEMBRESÍA: una fila pending + UN pago (sin enrollment). ──
      if (item.type === 'membership') {
        const { data: plan, error: planError } = await this.client
          .from('membership_plans')
          .select('id, price')
          .eq('id', item.courseId)
          .maybeSingle();

        if (planError) {
          throw new Error(
            `Supabase createCheckout (plan): ${planError.message}`,
          );
        }
        if (!plan) {
          throw new Error(
            'Supabase createCheckout: el plan de membresía no existe.',
          );
        }

        const { data: membership, error: mError } = await this.client
          .from('memberships')
          .insert({
            user_id: input.userId,
            plan_id: item.courseId,
            status: 'pending_payment',
          })
          .select('id')
          .single();

        if (mError || !membership) {
          throw new Error(
            `Supabase createCheckout (memberships): ${mError?.message}`,
          );
        }

        const { data: pay, error: payError } = await this.client
          .from('payments')
          .insert({
            enrollment_id: null,
            membership_id: (membership as { id: string }).id,
            payment_type: 'full',
            amount: item.amount,
            status: 'pending_approval',
          })
          .select('id, enrollment_id, amount, status')
          .single();

        if (payError || !pay) {
          throw new Error(
            `Supabase createCheckout (payments): ${payError?.message}`,
          );
        }

        const membershipPayment = pay as PaymentRow;
        const membershipAmount = Number(membershipPayment.amount);
        payments.push({
          id: membershipPayment.id,
          enrollmentId: membershipPayment.enrollment_id,
          amount: membershipAmount,
          status: membershipPayment.status,
        });
        total += membershipAmount;
        continue;
      }

      // Un ítem tipo 'path' se EXPANDE: una inscripción por curso del
      // combo y UN solo pago (el ticket del combo con su rebaja).
      const isPath = item.type === 'path';
      const courseIds = isPath
        ? (await this.getPathCourseIds(item.courseId)) ?? []
        : [item.courseId];

      if (isPath && courseIds.length === 0) {
        throw new Error('Supabase createCheckout: la ruta no existe.');
      }

      const itemEnrollments: EnrollmentRecord[] = [];
      for (const courseId of courseIds) {
        // Inscripción (reutiliza la existente si ya estaba inscrito).
        const { data: enr, error: enrError } = await this.client
          .from('enrollments')
          .upsert(
            {
              user_id: input.userId,
              course_id: courseId,
              status: 'pending_payment',
            },
            { onConflict: 'user_id,course_id' },
          )
          .select('id, user_id, course_id, status')
          .single();

        if (enrError || !enr) {
          throw new Error(
            `Supabase createCheckout (enrollments): ${enrError?.message}`,
          );
        }

        const enrollment = enr as EnrollmentRow;
        const record: EnrollmentRecord = {
          id: enrollment.id,
          userId: enrollment.user_id,
          courseId: enrollment.course_id,
          status: enrollment.status,
        };
        enrollments.push(record);
        itemEnrollments.push(record);
      }

      // Pago pendiente de aprobación (ticket/transferencia). El combo
      // genera UN pago ligado a la primera inscripción + path_id.
      const { data: pay, error: payError } = await this.client
        .from('payments')
        .insert({
          enrollment_id: itemEnrollments[0]!.id,
          payment_type: 'full',
          amount: item.amount,
          status: 'pending_approval',
          ...(isPath ? { path_id: item.courseId } : {}),
        })
        .select('id, enrollment_id, amount, status')
        .single();

      if (payError || !pay) {
        throw new Error(
          `Supabase createCheckout (payments): ${payError?.message}`,
        );
      }

      const payment = pay as PaymentRow;
      const amount = Number(payment.amount);
      payments.push({
        id: payment.id,
        enrollmentId: payment.enrollment_id,
        amount,
        status: payment.status,
      });
      total += amount;
    }

    return { userId: input.userId, total, enrollments, payments };
  }

  async listEnrolledCourses(userId: string): Promise<EnrolledCourse[]> {
    const { data, error } = await this.client
      .from('enrollments')
      .select(
        'course_id, status, enrolled_at, courses ( title, description, image_url, modality )',
      )
      .eq('user_id', userId)
      .order('enrolled_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase listEnrolledCourses: ${error.message}`);
    }

    // El embed enrollments → courses (muchos-a-uno) lo normaliza asRows.
    const rows = asRows<EnrolledCourseRow>(data);
    const courses: EnrolledCourse[] = [];

    for (const row of rows) {
      const course = row.courses;
      if (!course) continue; // inscripción huérfana (curso borrado)

      courses.push({
        courseId: row.course_id,
        title: course.title,
        description: course.description ?? '',
        imageUrl: course.image_url,
        modality: course.modality,
        status: row.status,
        enrolledAt: row.enrolled_at,
        // El % de avance lo completa el caso de uso GetMyCourses
        // (vía CurriculumRepository); aquí solo se cumple el contrato.
        totalLessons: 0,
        completedLessons: 0,
      });
    }

    // MEMBRESÍA ACTIVA: "Mis cursos" pasa a ser TODO el catálogo
    // (los ya inscritos conservan su estado; el resto con status
    // 'membership'). Los cursos nuevos que salgan después entran solos.
    const nowIso = new Date().toISOString();
    const { data: membership, error: membershipError } = await this.client
      .from('memberships')
      .select('id')
      .eq('user_id', userId)
      .eq('status', 'active')
      .not('end_date', 'is', null)
      .gt('end_date', nowIso)
      .limit(1)
      .maybeSingle();

    if (membershipError) {
      throw new Error(
        `Supabase listEnrolledCourses (memberships): ${membershipError.message}`,
      );
    }

    if (membership) {
      const { data: allCourses, error: coursesError } = await this.client
        .from('courses')
        .select('id, title, description, image_url, modality')
        .eq('status', 'active')
        .order('created_at', { ascending: false });

      if (coursesError) {
        throw new Error(
          `Supabase listEnrolledCourses (courses): ${coursesError.message}`,
        );
      }

      const already = new Set(courses.map((course) => course.courseId));
      for (const row of asRows<EnrolledCourseRow>(allCourses)) {
        if (already.has(row.course_id)) continue;
        courses.push({
          courseId: row.course_id,
          title: row.courses?.title ?? '',
          description: row.courses?.description ?? '',
          imageUrl: row.courses?.image_url ?? null,
          modality: row.courses?.modality ?? 'asynchronous',
          status: 'membership',
          enrolledAt: null,
          totalLessons: 0,
          completedLessons: 0,
        });
      }
    }

    return courses;
  }

  async getEnrollmentStatus(
    userId: string,
    courseId: string,
  ): Promise<string | null> {
    const { data, error } = await this.client
      .from('enrollments')
      .select('status')
      .eq('user_id', userId)
      .eq('course_id', courseId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase getEnrollmentStatus: ${error.message}`);
    }
    return data ? (data as { status: string }).status : null;
  }

  async setEnrollmentStatus(
    userId: string,
    courseId: string,
    status: string,
  ): Promise<void> {
    // No-op si el usuario no está inscrito (cero filas afectadas).
    const { error } = await this.client
      .from('enrollments')
      .update({ status })
      .eq('user_id', userId)
      .eq('course_id', courseId);

    if (error) {
      throw new Error(`Supabase setEnrollmentStatus: ${error.message}`);
    }
  }

  /** Guarda/actualiza los datos personales en `public.users`. */
  private async upsertUser(input: CheckoutInput): Promise<void> {
    const base: Record<string, unknown> = {
      id: input.userId,
      email: input.email,
      full_name: input.fullName,
      phone: input.phone,
      nationality: input.nationality,
      document_number: input.documentNumber,
      is_active: true,
    };

    // Columnas opcionales del perfil (document_number / is_active): si la
    // migración aún no se ejecutó, PostgREST/Postgres avisa qué columna
    // falta; la quitamos del payload y reintentamos, sin romper el pago.
    for (let attempt = 0; attempt < 6; attempt++) {
      const result = await this.client
        .from('users')
        .upsert(base, { onConflict: 'id' });

      if (!result.error) return;

      // PostgREST: "Could not find the 'x' column of 'users' in the schema cache"
      // Postgres:  'column "x" ... does not exist'
      const missing =
        result.error.message.match(/column "([a-z_]+)"/i) ??
        result.error.message.match(/'([a-z_]+)' column/i);

      const columnName = missing?.[1];
      if (columnName !== undefined && columnName in base && columnName !== 'id') {
        delete base[columnName];
        continue;
      }

      throw new Error(
        `Supabase createCheckout (users): ${result.error.message}`,
      );
    }

    throw new Error(
      'Supabase createCheckout (users): faltan columnas esenciales del perfil',
    );
  }
}
