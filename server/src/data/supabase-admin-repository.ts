import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type {
  AbandonedCartItem,
  AdminCurriculum,
  AdminLesson,
  AdminModule,
  AdminRepository,
  AdminStats,
  CategoryRecord,
  CourseParticipant,
  ImageUploadInput,
  ImageUploadRecord,
  NewLessonInput,
  NewUserInput,
  PaymentDecision,
  PaymentRecord,
  StudentEnrollment,
  StudentProfile,
  StudentRecord,
  UpdateLessonInput,
  UpdateModuleInput,
  UpdateUserInput,
  UserRecord,
} from '../domain/admin.js';
import { effectivePriceOf } from '../domain/catalog.js';
import { pathPricingOf } from '../domain/learning-path.js';
import { endDateOf } from '../domain/membership.js';
import { roleNamesOf, type UserRoleRow } from './role-rows.js';
import { asRows } from './postgrest-rows.js';

interface StudentRow {
  id: string;
  full_name: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  created_at: string | null;
  is_active: boolean | null;
  enrollments: Array<{ count: number }> | null;
}

/** Fila de `payments` (amount puede venir como string de la BD). */
interface PaymentRow {
  amount: number | string;
  status: string;
}

/** Fila de `categories`. */
interface CategoryRow {
  id: string;
  name: string;
  slug: string;
}

/** Fila de `roles` (solo el id). */
interface RoleIdRow {
  id: string;
}

/** Fila de `users` (perfil corto). */
interface ProfileRow {
  id: string;
  full_name: string | null;
  phone: string | null;
  is_active: boolean | null;
}

/** Fila del join `user_roles → roles(name)` + el id del usuario. */
interface UserRolesRow extends UserRoleRow {
  user_id: string;
}

/** Fila de `carts` con el curso embebido (join carts → courses). */
interface AbandonedCartRow {
  user_id: string;
  course_id: string;
  item_type: string | null;
  added_at: string;
  courses: { title: string; price: number | string; compare_at_price: number | string | null } | null;
}

/** Perfil corto de `users` para enriquecer carritos y pagos. */
interface UserContactRow {
  id: string;
  email: string | null;
  full_name: string | null;
}

/** Fila de `courses` (solo el título) para enriquecer pagos. */
interface CourseTitleRow {
  id: string;
  title: string;
}

/** Fila de `enrollments` con el usuario embebido (muchos-a-uno). */
interface ParticipantRow {
  user_id: string;
  status: string;
  enrolled_at: string | null;
  users: {
    full_name: string | null;
    email: string | null;
    phone: string | null;
  } | null;
}

/** Perfil corto de `users` para el detalle del estudiante. */
interface StudentProfileRow {
  id: string;
  full_name: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  created_at: string | null;
  is_active: boolean | null;
}

/** Fila de `enrollments` con el curso embebido (para el perfil). */
interface ProfileEnrollmentRow {
  course_id: string;
  status: string;
  enrolled_at: string | null;
  courses: { title: string } | null;
}

/** Fila de `modules` con sus lecciones embebidas (uno-a-muchos). */
interface ModuleWithLessonsRow {
  id: string;
  title: string;
  order_index: number;
  lessons: LessonRow[] | null;
}

/** Fila de `lessons` (campos crudos de contenido). */
interface LessonRow {
  id: string;
  title: string;
  content_type: string;
  order_index: number;
  video_url: string | null;
  zoom_url: string | null;
  drive_url: string | null;
  content_text: string | null;
  attachment_url: string | null;
  attachment_name: string | null;
}

/** Fila de `modules` a secas. */
interface ModuleRow {
  id: string;
  title: string;
  order_index: number;
}

/** Convierte una fila de `lessons` a la forma del dominio. */
function toAdminLesson(row: LessonRow): AdminLesson {
  return {
    id: row.id,
    title: row.title,
    contentType: row.content_type,
    orderIndex: row.order_index,
    videoUrl: row.video_url,
    zoomUrl: row.zoom_url,
    driveUrl: row.drive_url,
    contentText: row.content_text,
    attachmentUrl: row.attachment_url,
    attachmentName: row.attachment_name,
  };
}

/** Fila de `payments` con la inscripción embebida. */
interface PaymentListRow {
  id: string;
  amount: number | string;
  status: string;
  created_at: string;
  path_id: string | null;
  enrollments: { user_id: string; course_id: string } | null;
}

// ── Mappers: fila (snake_case de la BD) → registro de dominio ──

function toStudentRecord(row: StudentRow): StudentRecord {
  return {
    id: row.id,
    fullName: row.full_name,
    email: row.email,
    phone: row.phone,
    nationality: row.nationality,
    createdAt: row.created_at,
    enrolledCourses: row.enrollments?.[0]?.count ?? 0,
    isActive: row.is_active ?? true,
  };
}

function toCategoryRecord(row: CategoryRow): CategoryRecord {
  return { id: row.id, name: row.name, slug: row.slug };
}

/** Agrega los pagos en los KPIs del dashboard. */
function summarizePayments(rows: PaymentRow[]): {
  pendingPayments: number;
  revenue: number;
} {
  let pendingPayments = 0;
  let revenue = 0;
  for (const row of rows) {
    if (row.status === 'pending_approval') pendingPayments += 1;
    if (row.status === 'approved') revenue += Number(row.amount);
  }
  return { pendingPayments, revenue };
}

/**
 * 🔌 DATOS — panel administrativo con Supabase.
 * Usa la Service Role Key (solo en el backend) para leer estadísticas,
 * estudiantes y crear usuarios/categorías.
 */
export class SupabaseAdminRepository implements AdminRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async getStats(): Promise<AdminStats> {
    const countOf = async (table: string): Promise<number> => {
      const { count, error } = await this.client
        .from(table)
        .select('id', { count: 'exact', head: true });
      if (error) {
        throw new Error(`Supabase getStats (${table}): ${error.message}`);
      }
      return count ?? 0;
    };

    const students = await countOf('users');
    const courses = await countOf('courses');
    const enrollments = await countOf('enrollments');

    const { data: payments, error } = await this.client
      .from('payments')
      .select('amount, status');
    if (error) {
      throw new Error(`Supabase getStats (payments): ${error.message}`);
    }

    const { pendingPayments, revenue } = summarizePayments(
      asRows<PaymentRow>(payments),
    );

    return { students, courses, enrollments, pendingPayments, revenue };
  }

  async findStudents(): Promise<StudentRecord[]> {
    const { data, error } = await this.client
      .from('users')
      .select(
        'id, full_name, email, phone, nationality, created_at, is_active, enrollments(count)',
      )
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase findStudents: ${error.message}`);
    }

    return asRows<StudentRow>(data).map(toStudentRecord);
  }

  async createCategory(name: string, slug: string): Promise<CategoryRecord> {
    const { data, error } = await this.client
      .from('categories')
      .insert({ name, slug })
      .select('id, name, slug')
      .single();

    if (error) {
      throw new Error(`Supabase createCategory: ${error.message}`);
    }

    return toCategoryRecord(data as CategoryRow);
  }

  async createUser(input: NewUserInput): Promise<{ id: string; email: string }> {
    // 1. Cuenta en Supabase Auth (confirmada de fábrica: la creó el admin).
    const { data: created, error } = await this.client.auth.admin.createUser({
      email: input.email,
      password: input.password,
      email_confirm: true,
    });

    if (error || !created.user) {
      throw new Error(`Supabase createUser: ${error?.message}`);
    }

    const userId = created.user.id;

    // 2. Perfil en public.users.
    const { error: profileError } = await this.client.from('users').insert({
      id: userId,
      email: input.email,
      full_name: input.fullName,
      phone: input.phone,
      is_active: true,
    });

    if (profileError) {
      throw new Error(`Supabase createUser (users): ${profileError.message}`);
    }

    // 3. Rol (si existe en la tabla roles; ver sql/003_seed_roles.sql).
    const { data: role } = await this.client
      .from('roles')
      .select('id')
      .eq('name', input.role)
      .maybeSingle();

    if (role) {
      const { error: roleError } = await this.client
        .from('user_roles')
        .insert({ user_id: userId, role_id: (role as RoleIdRow).id });

      if (roleError) {
        throw new Error(`Supabase createUser (user_roles): ${roleError.message}`);
      }
    }

    return { id: userId, email: input.email };
  }

  async findUsers(): Promise<UserRecord[]> {
    // 1. Cuentas de auth (fuente completa de emails y fechas).
    const authUsers: Array<{
      id: string;
      email: string | null;
      createdAt: string | null;
    }> = [];
    for (let page = 1; page <= 50; page++) {
      const { data, error } = await this.client.auth.admin.listUsers({
        page,
        perPage: 100,
      });
      if (error) {
        throw new Error(`Supabase findUsers: ${error.message}`);
      }
      for (const user of data.users) {
        authUsers.push({
          id: user.id,
          email: user.email ?? null,
          createdAt: user.created_at ?? null,
        });
      }
      if (data.users.length === 0 || page >= (data.totalPages ?? 1)) break;
    }

    // 2. Perfiles (public.users).
    const { data: profiles } = await this.client
      .from('users')
      .select('id, full_name, phone, is_active');
    const profileById = new Map(
      asRows<ProfileRow>(profiles).map((row) => [row.id, row]),
    );

    // 3. Roles por usuario (user_roles → roles).
    const { data: roleRows, error: roleError } = await this.client
      .from('user_roles')
      .select('user_id, roles(name)');
    if (roleError) {
      throw new Error(`Supabase findUsers (user_roles): ${roleError.message}`);
    }

    const rolesByUser = new Map<string, string[]>();
    for (const row of asRows<UserRolesRow>(roleRows)) {
      rolesByUser.set(row.user_id, [
        ...(rolesByUser.get(row.user_id) ?? []),
        ...roleNamesOf(row),
      ]);
    }

    return authUsers.map((user) => ({
      id: user.id,
      email: user.email ?? '',
      fullName:
        profileById.get(user.id)?.full_name ??
        (user.email ? user.email.split('@')[0] ?? '' : ''),
      phone: profileById.get(user.id)?.phone ?? null,
      createdAt: user.createdAt,
      roles: rolesByUser.get(user.id) ?? [],
      isActive: profileById.get(user.id)?.is_active ?? true,
    }));
  }

  async updateCategory(
    id: string,
    name: string,
    slug: string,
  ): Promise<CategoryRecord | null> {
    const { data, error } = await this.client
      .from('categories')
      .update({ name, slug })
      .eq('id', id)
      .select('id, name, slug')
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updateCategory: ${error.message}`);
    }
    return data ? toCategoryRecord(data as CategoryRow) : null;
  }

  async updateUser(input: UpdateUserInput): Promise<UserRecord | null> {
    // 1. Perfil: nombre, teléfono y estado (activo/inactivo).
    const { data: profile, error } = await this.client
      .from('users')
      .update({
        full_name: input.fullName,
        phone: input.phone,
        is_active: input.isActive,
      })
      .eq('id', input.id)
      .select('id')
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updateUser (users): ${error.message}`);
    }
    if (!profile) return null;

    // 2. Rol: reemplaza los actuales por el indicado ('' = sin rol).
    const { error: clearError } = await this.client
      .from('user_roles')
      .delete()
      .eq('user_id', input.id);
    if (clearError) {
      throw new Error(`Supabase updateUser (user_roles): ${clearError.message}`);
    }

    if (input.role.length > 0) {
      const { data: role } = await this.client
        .from('roles')
        .select('id')
        .eq('name', input.role)
        .maybeSingle();

      if (role) {
        const { error: roleError } = await this.client
          .from('user_roles')
          .insert({ user_id: input.id, role_id: (role as RoleIdRow).id });
        if (roleError) {
          throw new Error(
            `Supabase updateUser (user_roles insert): ${roleError.message}`,
          );
        }
      }
    }

    // 3. Devuelve el registro tal como quedó.
    const users = await this.findUsers();
    return users.find((user) => user.id === input.id) ?? null;
  }

  /** Perfiles (id → email/nombre) para enriquecer carritos y pagos. */
  private async findUserContacts(): Promise<Map<string, UserContactRow>> {
    const { data, error } = await this.client
      .from('users')
      .select('id, email, full_name');

    if (error) {
      throw new Error(`Supabase findUserContacts: ${error.message}`);
    }

    return new Map(
      asRows<UserContactRow>(data).map((row) => [row.id, row]),
    );
  }

  async listAbandonedCarts(): Promise<AbandonedCartItem[]> {
    // Cada fila de carts es un ítem, así que listarlas = listar usuarios
    // con carrito no vacío. Orden por addedAt desc (los más recientes
    // primero). El curso va embebido; las filas tipo 'path' (combo) se
    // resuelven contra learning_paths.
    const { data, error } = await this.client
      .from('carts')
      .select(
        'user_id, course_id, item_type, added_at, courses ( title, price, compare_at_price )',
      )
      .order('added_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase listAbandonedCarts: ${error.message}`);
    }

    // El perfil va aparte: carts.user_id apunta a auth.users y la
    // relación con public.users no siempre está expuesta como join.
    const contacts = await this.findUserContacts();

    const rows = asRows<AbandonedCartRow>(data);

    // Precisos de las rutas del carrito (precio del combo con rebaja).
    const pathIds = [
      ...new Set(
        rows
          .filter((row) => (row.item_type ?? 'course') === 'path')
          .map((row) => row.course_id),
      ),
    ];
    const pathsById = new Map<string, { title: string; price: number }>();
    if (pathIds.length > 0) {
      const { data: pathData, error: pathError } = await this.client
        .from('learning_paths')
        .select(
          'id, title, discount_percent, path_courses(courses(price, compare_at_price))',
        )
        .in('id', pathIds);

      if (pathError) {
        throw new Error(
          `Supabase listAbandonedCarts (paths): ${pathError.message}`,
        );
      }

      for (const row of asRows<{
        id: string;
        title: string;
        discount_percent: number;
        path_courses: Array<{
          courses: { price: number | string; compare_at_price: number | string | null } | null;
        }> | null;
      }>(pathData)) {
        const courses = (row.path_courses ?? [])
          .map((entry) => entry.courses)
          .filter((course): course is NonNullable<typeof course> => course !== null)
          .map((course) => ({
            price: Number(course.price),
            compareAtPrice:
              course.compare_at_price === null
                ? null
                : Number(course.compare_at_price),
          }));

        const pricing = pathPricingOf(
          courses.map((course) => ({
            courseId: '',
            title: '',
            imageUrl: null,
            price: effectivePriceOf(course),
            hours: 0,
            level: null,
            sortOrder: 0,
          })),
          row.discount_percent ?? 0,
        );
        pathsById.set(row.id, { title: row.title, price: pricing.price });
      }
    }

    // El embed carts → courses (muchos-a-uno) lo normaliza asRows; el
    // flatMap descarta los join nulos (curso/ruta borrada) sin casts.
    return rows.flatMap((row) => {
      const contact = contacts.get(row.user_id);
      const isPath = (row.item_type ?? 'course') === 'path';

      if (isPath) {
        const path = pathsById.get(row.course_id);
        if (!path) return [];
        return [
          {
            userId: row.user_id,
            email: contact?.email ?? '',
            fullName: contact?.full_name ?? '',
            courseId: row.course_id,
            title: `Ruta: ${path.title}`,
            price: path.price,
            addedAt: row.added_at,
          },
        ];
      }

      const course = row.courses;
      if (course === null) return [];
      return [
        {
          userId: row.user_id,
          email: contact?.email ?? '',
          fullName: contact?.full_name ?? '',
          courseId: row.course_id,
          title: course.title,
          // Lo que el cliente pagaría hoy: la oferta si existe.
          price: effectivePriceOf({
            price: Number(course.price),
            compareAtPrice:
              course.compare_at_price === null
                ? null
                : Number(course.compare_at_price),
          }),
          addedAt: row.added_at,
        },
      ];
    });
  }

  async listPayments(status: string): Promise<PaymentRecord[]> {
    const { data, error } = await this.client
      .from('payments')
      .select(
        'id, amount, status, created_at, path_id, enrollments ( user_id, course_id )',
      )
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase listPayments: ${error.message}`);
    }

    // El embed payments → enrollments (muchos-a-uno) lo normaliza asRows.
    const rows = asRows<PaymentListRow>(data);
    if (rows.length === 0) return [];

    // Usuario y curso en consultas aparte (mismos joins manuales que
    // findUsers): no dependemos de FK que PostgREST pueda exponer o no.
    const contacts = await this.findUserContacts();

    const courseIds = [
      ...new Set(
        rows.flatMap((row) =>
          row.enrollments ? [row.enrollments.course_id] : [],
        ),
      ),
    ];
    const { data: courses, error: coursesError } = await this.client
      .from('courses')
      .select('id, title')
      .in('id', courseIds);

    if (coursesError) {
      throw new Error(`Supabase listPayments (courses): ${coursesError.message}`);
    }
    const titlesById = new Map(
      asRows<CourseTitleRow>(courses).map((row) => [row.id, row.title]),
    );

    // Títulos de las rutas (tickets de combo).
    const pathIds = [
      ...new Set(
        rows.flatMap((row) => (row.path_id ? [row.path_id] : [])),
      ),
    ];
    const pathTitlesById = new Map<string, string>();
    if (pathIds.length > 0) {
      const { data: paths, error: pathsError } = await this.client
        .from('learning_paths')
        .select('id, title')
        .in('id', pathIds);

      if (pathsError) {
        throw new Error(`Supabase listPayments (paths): ${pathsError.message}`);
      }
      for (const row of asRows<CourseTitleRow>(paths)) {
        pathTitlesById.set(row.id, row.title);
      }
    }

    return rows.flatMap((row) => {
      const enrollment = row.enrollments;
      if (enrollment === null) return [];
      const contact = contacts.get(enrollment.user_id);
      return [
        {
          id: row.id,
          userId: enrollment.user_id,
          email: contact?.email ?? '',
          fullName: contact?.full_name ?? '',
          courseId: enrollment.course_id,
          courseTitle: titlesById.get(enrollment.course_id) ?? '',
          amount: Number(row.amount),
          status: row.status,
          createdAt: row.created_at,
          pathId: row.path_id,
          pathTitle: row.path_id
            ? pathTitlesById.get(row.path_id) ?? null
            : null,
        },
      ];
    });
  }

  async decidePayment(
    paymentId: string,
    status: string,
    adminUserId: string,
  ): Promise<PaymentDecision | null> {
    // 1) Lee el pago antes de tocar nada (null = no existe → 404).
    //    path_id = ticket de COMBO; membership_id = ticket de PLAN;
    //    user_id para expandir el alcance del combo.
    const { data: payment, error } = await this.client
      .from('payments')
      .select(
        'id, enrollment_id, path_id, membership_id, enrollments ( user_id ), memberships ( membership_plans ( months ) )',
      )
      .eq('id', paymentId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase decidePayment: ${error.message}`);
    }
    if (!payment) return null;

    // Los embeds many-to-one pueden venir como objeto O como array de1.
    const raw = payment as Record<string, unknown>;
    const pickEmbed = <T>(value: unknown): T | null => {
      if (Array.isArray(value)) return (value[0] as T) ?? null;
      return (value as T) ?? null;
    };

    const paymentRow = {
      id: raw['id'] as string,
      enrollment_id: raw['enrollment_id'] as string | null,
      path_id: raw['path_id'] as string | null,
      membership_id: raw['membership_id'] as string | null,
      user_id:
        pickEmbed<{ user_id: string }>(raw['enrollments'])?.user_id ?? null,
      membershipMonths:
        pickEmbed<{ membership_plans?: { months?: number } | null }>(
          raw['memberships'],
        )?.membership_plans?.months ?? null,
    };

    // 2) Decisión del admin en payments (+ quién aprobó y cuándo).
    const { error: payError } = await this.client
      .from('payments')
      .update({
        status,
        approved_by: adminUserId,
        paid_at: status === 'approved' ? new Date().toISOString() : null,
      })
      .eq('id', paymentId);

    if (payError) {
      throw new Error(
        `Supabase decidePayment (payments): ${payError.message}`,
      );
    }

    // 3) MEMBRESÍA (ticket de plan): activa con fechas desde AHORA
    //    (start = hoy, end = hoy + meses del plan) o rechazada.
    if (paymentRow.membership_id) {
      const start = new Date();
      const { error: membershipError } = await this.client
        .from('memberships')
        .update({
          status: status === 'approved' ? 'active' : 'rejected',
          start_date: status === 'approved' ? start.toISOString() : null,
          end_date:
            status === 'approved'
              ? endDateOf(start, paymentRow.membershipMonths ?? 1)
              : null,
          updated_at: start.toISOString(),
        })
        .eq('id', paymentRow.membership_id);

      if (membershipError) {
        throw new Error(
          `Supabase decidePayment (memberships): ${membershipError.message}`,
        );
      }
      return { id: paymentId, status };
    }

    // 4) La INSCRIPCIÓN manda el acceso: 'approved' = puede entrar al
    //    curso; 'rejected' = lo pierde. Mismos valores que el pago.
    if (paymentRow.enrollment_id) {
      const { error: enrError } = await this.client
        .from('enrollments')
        .update({ status })
        .eq('id', paymentRow.enrollment_id);

      if (enrError) {
        throw new Error(
          `Supabase decidePayment (enrollments): ${enrError.message}`,
        );
      }
    }

    // 5) COMBO (path_id): el mismo ticket aprueba TODOS los cursos de
    //    la ruta para ese usuario (un solo pago para el combo).
    if (paymentRow.path_id && paymentRow.user_id) {
      const { data: pathCourses, error: pathError } = await this.client
        .from('path_courses')
        .select('course_id')
        .eq('path_id', paymentRow.path_id);

      if (pathError) {
        throw new Error(
          `Supabase decidePayment (path_courses): ${pathError.message}`,
        );
      }

      const courseIds = (pathCourses ?? []).map(
        (row) => (row as { course_id: string }).course_id,
      );
      if (courseIds.length > 0) {
        const { error: bundleError } = await this.client
          .from('enrollments')
          .update({ status })
          .eq('user_id', paymentRow.user_id)
          .in('course_id', courseIds);

        if (bundleError) {
          throw new Error(
            `Supabase decidePayment (bundle enrollments): ${bundleError.message}`,
          );
        }
      }
    }

    return { id: paymentId, status };
  }

  // ── PARTICIPANTES + PERFIL DEL ESTUDIANTE ────────────────────

  async listCourseParticipants(
    courseId: string,
  ): Promise<CourseParticipant[]> {
    const { data, error } = await this.client
      .from('enrollments')
      .select(
        'user_id, status, enrolled_at, users ( full_name, email, phone )',
      )
      .eq('course_id', courseId)
      .order('enrolled_at', { ascending: false });

    if (error) {
      throw new Error(`Supabase listCourseParticipants: ${error.message}`);
    }

    return asRows<ParticipantRow>(data).map((row) => ({
      userId: row.user_id,
      fullName: row.users?.full_name ?? '',
      email: row.users?.email ?? '',
      phone: row.users?.phone ?? null,
      status: row.status,
      enrolledAt: row.enrolled_at,
    }));
  }

  async getStudentProfile(studentId: string): Promise<StudentProfile | null> {
    const { data: profile, error } = await this.client
      .from('users')
      .select('id, full_name, email, phone, nationality, created_at, is_active')
      .eq('id', studentId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase getStudentProfile: ${error.message}`);
    }
    if (!profile) return null;

    const { data: enrollments, error: enrollError } = await this.client
      .from('enrollments')
      .select('course_id, status, enrolled_at, courses ( title )')
      .eq('user_id', studentId)
      .order('enrolled_at', { ascending: false });

    if (enrollError) {
      throw new Error(
        `Supabase getStudentProfile (enrollments): ${enrollError.message}`,
      );
    }

    const rows = asRows<ProfileEnrollmentRow>(enrollments).map(
      (row): StudentEnrollment => ({
        courseId: row.course_id,
        title: row.courses?.title ?? row.course_id,
        status: row.status,
        enrolledAt: row.enrolled_at,
      }),
    );

    const user = profile as StudentProfileRow;
    return {
      id: user.id,
      fullName: user.full_name,
      email: user.email,
      phone: user.phone,
      nationality: user.nationality,
      createdAt: user.created_at,
      isActive: user.is_active ?? true,
      enrollments: rows,
    };
  }

  // ── TEMARIO (módulos + lecciones) ────────────────────────────

  async getCourseCurriculum(courseId: string): Promise<AdminCurriculum | null> {
    const { data: course, error } = await this.client
      .from('courses')
      .select('id, title')
      .eq('id', courseId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase getCourseCurriculum (courses): ${error.message}`);
    }
    if (!course) return null;

    const { data: modules, error: modulesError } = await this.client
      .from('modules')
      .select(
        'id, title, order_index, lessons ( id, title, content_type, order_index, video_url, zoom_url, drive_url, content_text, attachment_url, attachment_name )',
      )
      .eq('course_id', courseId)
      .order('order_index', { ascending: true });

    if (modulesError) {
      throw new Error(
        `Supabase getCourseCurriculum (modules): ${modulesError.message}`,
      );
    }

    // El embed modules → lessons no garantiza el orden: se reordena en
    // JS (misma razón que en SupabaseCurriculumRepository).
    const rows = [...asRows<ModuleWithLessonsRow>(modules)].sort(
      (a, b) => a.order_index - b.order_index,
    );

    return {
      courseId,
      courseTitle: course.title,
      modules: rows.map((row) => ({
        id: row.id,
        title: row.title,
        orderIndex: row.order_index,
        lessons: [...(row.lessons ?? [])]
          .sort((a, b) => a.order_index - b.order_index)
          .map(toAdminLesson),
      })),
    };
  }

  async createModule(courseId: string, title: string): Promise<AdminModule> {
    const orderIndex = (await this.nextOrderIndex('modules', 'course_id', courseId));

    const { data, error } = await this.client
      .from('modules')
      .insert({ course_id: courseId, title, order_index: orderIndex })
      .select('id, title, order_index')
      .single();

    if (error) {
      throw new Error(`Supabase createModule: ${error.message}`);
    }

    const row = data as ModuleRow;
    return {
      id: row.id,
      title: row.title,
      orderIndex: row.order_index,
      lessons: [],
    };
  }

  async updateModule(
    moduleId: string,
    input: UpdateModuleInput,
  ): Promise<AdminModule | null> {
    const existing = await this.findModuleRow(moduleId);
    if (!existing) return null;

    if (input.title !== undefined) {
      const { error } = await this.client
        .from('modules')
        .update({ title: input.title })
        .eq('id', moduleId);
      if (error) {
        throw new Error(`Supabase updateModule: ${error.message}`);
      }
    }

    if (input.orderIndex !== undefined) {
      await this.reorder(
        'modules',
        'course_id',
        existing.course_id,
        moduleId,
        input.orderIndex - 1,
      );
    }

    return this.requireModule(moduleId);
  }

  async deleteModule(moduleId: string): Promise<boolean> {
    const existing = await this.findModuleRow(moduleId);
    if (!existing) return false;

    // Cascada: primero el progreso de SUS lecciones, luego las
    // lecciones y al final el módulo (las FKs lo exigen en ese orden).
    const { data: lessons, error: lessonsError } = await this.client
      .from('lessons')
      .select('id')
      .eq('module_id', moduleId);

    if (lessonsError) {
      throw new Error(`Supabase deleteModule (lessons): ${lessonsError.message}`);
    }

    const lessonIds = asRows<{ id: string }>(lessons).map((row) => row.id);
    await this.deleteLessonProgress(lessonIds);

    if (lessonIds.length > 0) {
      const { error: deleteLessonsError } = await this.client
        .from('lessons')
        .delete()
        .in('id', lessonIds);
      if (deleteLessonsError) {
        throw new Error(
          `Supabase deleteModule (lessons): ${deleteLessonsError.message}`,
        );
      }
    }

    const { error } = await this.client.from('modules').delete().eq('id', moduleId);
    if (error) {
      throw new Error(`Supabase deleteModule: ${error.message}`);
    }
    return true;
  }

  async createLesson(
    moduleId: string,
    input: NewLessonInput,
  ): Promise<AdminLesson> {
    const orderIndex = (await this.nextOrderIndex('lessons', 'module_id', moduleId));

    const { data, error } = await this.client
      .from('lessons')
      .insert({
        module_id: moduleId,
        title: input.title,
        content_type: input.contentType,
        order_index: orderIndex,
        video_url: input.videoUrl,
        zoom_url: input.zoomUrl,
        drive_url: input.driveUrl,
        content_text: input.contentText,
        attachment_url: input.attachmentUrl,
        attachment_name: input.attachmentName,
      })
      .select('id, title, content_type, order_index, video_url, zoom_url, drive_url, content_text, attachment_url, attachment_name')
      .single();

    if (error) {
      throw new Error(`Supabase createLesson: ${error.message}`);
    }
    return toAdminLesson(data as LessonRow);
  }

  async updateLesson(
    lessonId: string,
    input: UpdateLessonInput,
  ): Promise<AdminLesson | null> {
    const existing = await this.findLessonRow(lessonId);
    if (!existing) return null;

    const patch: Record<string, unknown> = {};
    if (input.title !== undefined) patch['title'] = input.title;
    if (input.contentType !== undefined) patch['content_type'] = input.contentType;
    if (input.videoUrl !== undefined) patch['video_url'] = input.videoUrl;
    if (input.zoomUrl !== undefined) patch['zoom_url'] = input.zoomUrl;
    if (input.driveUrl !== undefined) patch['drive_url'] = input.driveUrl;
    if (input.contentText !== undefined) patch['content_text'] = input.contentText;
    if (input.attachmentUrl !== undefined) {
      patch['attachment_url'] = input.attachmentUrl;
    }
    if (input.attachmentName !== undefined) {
      patch['attachment_name'] = input.attachmentName;
    }

    if (Object.keys(patch).length > 0) {
      const { error } = await this.client
        .from('lessons')
        .update(patch)
        .eq('id', lessonId);
      if (error) {
        throw new Error(`Supabase updateLesson: ${error.message}`);
      }
    }

    if (input.orderIndex !== undefined) {
      await this.reorder(
        'lessons',
        'module_id',
        existing.module_id,
        lessonId,
        input.orderIndex - 1,
      );
    }

    const { data, error } = await this.client
      .from('lessons')
      .select('id, title, content_type, order_index, video_url, zoom_url, drive_url, content_text, attachment_url, attachment_name')
      .eq('id', lessonId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updateLesson (lectura): ${error.message}`);
    }
    return data ? toAdminLesson(data as LessonRow) : null;
  }

  async deleteLesson(lessonId: string): Promise<boolean> {
    const existing = await this.findLessonRow(lessonId);
    if (!existing) return false;

    await this.deleteLessonProgress([lessonId]);

    const { error } = await this.client.from('lessons').delete().eq('id', lessonId);
    if (error) {
      throw new Error(`Supabase deleteLesson: ${error.message}`);
    }
    return true;
  }

  /** Siguiente order_index dentro del grupo (máximo actual + 1). */
  private async nextOrderIndex(
    table: 'modules' | 'lessons',
    column: 'course_id' | 'module_id',
    parentId: string,
  ): Promise<number> {
    const { data, error } = await this.client
      .from(table)
      .select('order_index')
      .eq(column, parentId)
      .order('order_index', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase ${table} (orden): ${error.message}`);
    }
    return data ? ((data as { order_index: number }).order_index ?? 0) + 1 : 1;
  }

  private async findModuleRow(
    moduleId: string,
  ): Promise<(ModuleRow & { course_id: string }) | null> {
    const { data, error } = await this.client
      .from('modules')
      .select('id, title, order_index, course_id')
      .eq('id', moduleId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase modules (lectura): ${error.message}`);
    }
    return data ? (data as ModuleRow & { course_id: string }) : null;
  }

  private async requireModule(moduleId: string): Promise<AdminModule> {
    const row = await this.findModuleRow(moduleId);
    if (!row) {
      throw new Error(`Supabase updateModule: el módulo ${moduleId} desapareció`);
    }
    const { data: lessons, error } = await this.client
      .from('lessons')
      .select('id, title, content_type, order_index, video_url, zoom_url, drive_url, content_text, attachment_url, attachment_name')
      .eq('module_id', moduleId)
      .order('order_index', { ascending: true });

    if (error) {
      throw new Error(`Supabase updateModule (lessons): ${error.message}`);
    }

    return {
      id: row.id,
      title: row.title,
      orderIndex: row.order_index,
      lessons: asRows<LessonRow>(lessons).map(toAdminLesson),
    };
  }

  private async findLessonRow(
    lessonId: string,
  ): Promise<{ module_id: string } | null> {
    const { data, error } = await this.client
      .from('lessons')
      .select('id, module_id')
      .eq('id', lessonId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase lessons (lectura): ${error.message}`);
    }
    return data ? (data as { module_id: string }) : null;
  }

  /** Borra el progreso de las lecciones indicadas (si existe). */
  private async deleteLessonProgress(lessonIds: string[]): Promise<void> {
    if (lessonIds.length === 0) return;

    const { error } = await this.client
      .from('lesson_progress')
      .delete()
      .in('lesson_id', lessonIds);

    // lesson_progress puede no existir en instalaciones antiguas: no es
    // fatal para el borrado del temario, pero se deja constancia.
    if (error && !error.message.includes('lesson_progress')) {
      throw new Error(`Supabase lesson_progress: ${error.message}`);
    }
  }

  /**
   * Mueve un ítem a la posición destino dentro de su grupo y renumera
   * el resto. Dos pasadas para no chocar con un índice único transitorio.
   */
  private async reorder(
    table: 'modules' | 'lessons',
    column: 'course_id' | 'module_id',
    parentId: string,
    itemId: string,
    targetIndex: number,
  ): Promise<void> {
    const { data, error } = await this.client
      .from(table)
      .select('id')
      .eq(column, parentId)
      .order('order_index', { ascending: true });

    if (error) {
      throw new Error(`Supabase ${table} (orden): ${error.message}`);
    }

    const ids = reorderedIds(
      asRows<{ id: string }>(data).map((row) => row.id),
      itemId,
      targetIndex,
    );

    for (let i = 0; i < ids.length; i++) {
      const { error: tempError } = await this.client
        .from(table)
        .update({ order_index: 1000 + i })
        .eq('id', ids[i]!);
      if (tempError) {
        throw new Error(`Supabase ${table} (orden): ${tempError.message}`);
      }
    }

    for (let i = 0; i < ids.length; i++) {
      const { error: finalError } = await this.client
        .from(table)
        .update({ order_index: i + 1 })
        .eq('id', ids[i]!);
      if (finalError) {
        throw new Error(`Supabase ${table} (orden): ${finalError.message}`);
      }
    }
  }

  /** Bucket público de imágenes de cursos (creado en el dashboard). */
  private static readonly bucket = 'courses';

  async uploadImage(input: ImageUploadInput): Promise<ImageUploadRecord> {
    // Ruta única por subida; conserva la extensión válida.
    const ext =
      input.filename
        .toLowerCase()
        .match(/\.(jpe?g|png|webp|gif|avif)$/)?.[1] ?? 'jpg';
    const path = `course-${Date.now()}-${Math.random()
      .toString(36)
      .slice(2, 8)}.${ext}`;

    const { error } = await this.client.storage
      .from(SupabaseAdminRepository.bucket)
      .upload(path, input.buffer, {
        contentType: input.contentType,
        upsert: false,
      });

    if (error) {
      throw new Error(`Supabase uploadImage: ${error.message}`);
    }

    const { data } = this.client.storage
      .from(SupabaseAdminRepository.bucket)
      .getPublicUrl(path);

    return { path, publicUrl: data.publicUrl };
  }
}

/**
 * Lista de ids con `id` movido a `targetIndex` (0-based, recortado a
 * los límites de la lista). El resto conserva su orden relativo.
 */
function reorderedIds(ids: string[], id: string, targetIndex: number): string[] {
  const rest = ids.filter((item) => item !== id);
  const to = Math.max(0, Math.min(targetIndex, rest.length));
  return [id, ...rest.slice(0, to), ...rest.slice(to)];
}
