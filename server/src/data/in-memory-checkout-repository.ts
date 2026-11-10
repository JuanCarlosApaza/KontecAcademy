import { ValidationError } from '../application/errors.js';
import type { CatalogRepository } from '../domain/catalog.js';
import type {
  AuthenticatedUser,
  CheckoutInput,
  CheckoutRepository,
  CheckoutResult,
  EnrolledCourse,
  EnrollmentRecord,
  PaymentRecord,
} from '../domain/checkout.js';
import type { LearningPathRepository } from '../domain/learning-path.js';
import type { MembershipRepository } from '../domain/membership.js';
import { ALL_PERMISSION_CODES } from '../domain/roles.js';

/** Inscripción guardada por usuario (PK en memoria: user + curso). */
interface StoredEnrollment {
  userId: string;
  courseId: string;
  /** pending_payment | approved | rejected | finished | revoked */
  status: string;
  enrolledAt: string;
}

/** Perfil del usuario registrado en el checkout (paridad con `users`). */
export interface StoredUser {
  fullName: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  createdAt: string;
}

/**
 * 🔌 DATOS — checkout en memoria (tests y desarrollo sin Supabase).
 * Verifica cualquier token no vacío y devuelve ids deterministas.
 * Las inscripciones se conservan para `listEnrolledCourses` ("Mis
 * cursos"); el catálogo resuelve título/imagen/modalidad al leer.
 */
export class InMemoryCheckoutRepository implements CheckoutRepository {
  private counter = 0;

  private readonly enrollments = new Map<string, StoredEnrollment>();

  /** Perfiles de usuario registrados en el checkout (paridad con `users`). */
  private readonly users = new Map<string, StoredUser>();

  /**
   * Pagos creados en runtime (checkout) → usuario + cursos que abre.
   * El panel admin en memoria los resuelve para decidir
   * (aprobar/rechazar) como si compartieran las tablas, que es como
   * funciona con Supabase. Un pago de combo tiene N cursos.
   */
  private readonly paymentTargets = new Map<
    string,
    { userId: string; courseIds: string[]; pathId?: string; membershipId?: string }
  >();

  constructor(
    private readonly catalog: CatalogRepository,
    private readonly paths?: Pick<LearningPathRepository, 'findById'>,
    private readonly memberships?: Pick<
      MembershipRepository,
      'planById' | 'createPending' | 'findActive' | 'decide'
    >,
  ) {}

  async verifyToken(token: string): Promise<AuthenticatedUser | null> {
    if (token.trim().length === 0) return null;
    return { id: 'mem-user-1', email: 'dev@kontec.pe' };
  }

  async getRoles(): Promise<string[]> {
    return ['admin', 'student'];
  }

  /** Coherente con getRoles (siempre admin): todos los códigos. */
  async getPermissions(): Promise<string[]> {
    return [...ALL_PERMISSION_CODES];
  }

  async listEnrolledCourses(userId: string): Promise<EnrolledCourse[]> {
    const courses: EnrolledCourse[] = [];

    for (const enrollment of this.enrollments.values()) {
      if (enrollment.userId !== userId) continue;

      // Curso eliminado del catálogo → no se muestra (join nulo).
      const course = await this.catalog.findById(enrollment.courseId);
      if (!course) continue;

      courses.push({
        courseId: course.id,
        title: course.title,
        description: course.description ?? '',
        imageUrl: course.imageUrl,
        modality: course.modality,
        status: enrollment.status,
        enrolledAt: enrollment.enrolledAt,
        // El % de avance lo completa el caso de uso GetMyCourses
        // (vía CurriculumRepository); aquí solo se cumple el contrato.
        totalLessons: 0,
        completedLessons: 0,
      });
    }

    // MEMBRESÍA ACTIVA: todo el catálogo con status 'membership'
    // (los ya inscritos conservan su estado).
    const active = await this.memberships?.findActive(userId);
    if (active) {
      const already = new Set(courses.map((course) => course.courseId));
      const all = await this.catalog.findAllCourses({ status: 'active' });
      for (const course of all) {
        if (already.has(course.id)) continue;
        courses.push({
          courseId: course.id,
          title: course.title,
          description: course.description ?? '',
          imageUrl: course.imageUrl,
          modality: course.modality,
          status: 'membership',
          enrolledAt: null,
          totalLessons: 0,
          completedLessons: 0,
        });
      }
    }

    // Más recientes primero (igual que la BD con order enrolled_at desc).
    return courses.sort((a, b) =>
      (b.enrolledAt ?? '').localeCompare(a.enrolledAt ?? ''),
    );
  }

  async getEnrollmentStatus(
    userId: string,
    courseId: string,
  ): Promise<string | null> {
    return this.enrollments.get(`${userId}::${courseId}`)?.status ?? null;
  }

  async setEnrollmentStatus(
    userId: string,
    courseId: string,
    status: string,
  ): Promise<void> {
    const key = `${userId}::${courseId}`;
    const existing = this.enrollments.get(key);
    if (!existing) return; // no estaba inscrito → no-op

    this.enrollments.set(key, { ...existing, status });
  }

  async getPathCourseIds(pathId: string): Promise<string[] | null> {
    const path = await this.paths?.findById(pathId);
    if (!path) return null;
    return path.courses.map((course) => course.courseId);
  }

  /** Solo en memoria: resuelve un pago creado en checkout (para el panel). */
  async findPaymentForDecision(
    paymentId: string,
  ): Promise<
    { userId: string; courseIds: string[]; pathId?: string; membershipId?: string } | null
  > {
    return this.paymentTargets.get(paymentId) ?? null;
  }

  /** Decisión del admin sobre el pago de una membresía (para el panel). */
  async decideMembership(
    membershipId: string,
    decision: 'approved' | 'rejected',
  ): Promise<boolean> {
    return this.memberships?.decide(membershipId, decision) ?? false;
  }

  // ── Lecturas que usa el panel admin (paridad con `users` + join) ──

  async findUser(userId: string): Promise<StoredUser | null> {
    return this.users.get(userId) ?? null;
  }

  async listEnrollmentsByCourse(
    courseId: string,
  ): Promise<StoredEnrollment[]> {
    return this.enrollmentList().filter((e) => e.courseId === courseId);
  }

  async listEnrollmentsByUser(userId: string): Promise<StoredEnrollment[]> {
    return this.enrollmentList().filter((e) => e.userId === userId);
  }

  /** Inscripciones ordenadas por enrolledAt desc (igual que la BD). */
  private enrollmentList(): StoredEnrollment[] {
    return [...this.enrollments.values()].sort((a, b) =>
      b.enrolledAt.localeCompare(a.enrolledAt),
    );
  }

  async createCheckout(input: CheckoutInput): Promise<CheckoutResult> {
    const now = new Date().toISOString();

    // Perfil del usuario (paridad con el upsert a `public.users`).
    this.users.set(input.userId, {
      fullName: input.fullName,
      email: input.email,
      phone: input.phone,
      nationality: input.nationality,
      createdAt: this.users.get(input.userId)?.createdAt ?? now,
    });

    const enrollments: EnrollmentRecord[] = [];
    const payments: PaymentRecord[] = [];

    for (const item of input.items) {
      // ── MEMBRESÍA: una fila pending + UN pago (sin enrollment). ──
      if (item.type === 'membership') {
        const plan = await this.memberships?.planById(item.courseId);
        if (!plan) {
          throw new ValidationError(
            'El plan de membresía no existe.',
          );
        }

        const membership = await this.memberships?.createPending(
          input.userId,
          item.courseId,
        );
        if (!membership) {
          throw new ValidationError(
            'El plan de membresía no existe.',
          );
        }

        const membershipPaymentId = `mem-checkout-payment-${++this.counter}`;
        this.paymentTargets.set(membershipPaymentId, {
          userId: input.userId,
          courseIds: [],
          membershipId: membership.id,
        });
        payments.push({
          id: membershipPaymentId,
          enrollmentId: null,
          amount: item.amount,
          status: 'pending_approval',
        });
        continue;
      }

      // Un ítem tipo 'path' se EXPANDE en una inscripción por curso.
      const courseIds =
        item.type === 'path'
          ? (await this.getPathCourseIds(item.courseId)) ?? []
          : [item.courseId];

      if (item.type === 'path' && courseIds.length === 0) {
        throw new ValidationError('La ruta seleccionada no existe.');
      }

      const itemEnrollments: EnrollmentRecord[] = [];
      for (const courseId of courseIds) {
        const key = `${input.userId}::${courseId}`;
        const previous = this.enrollments.get(key);

        const enrollment: StoredEnrollment = {
          userId: input.userId,
          courseId,
          status: 'pending_payment',
          // Re-solicitar conserva la fecha de la primera inscripción.
          enrolledAt: previous?.enrolledAt ?? now,
        };
        this.enrollments.set(key, enrollment);

        const record: EnrollmentRecord = {
          id: `mem-enrollment-${++this.counter}`,
          userId: enrollment.userId,
          courseId: enrollment.courseId,
          status: enrollment.status,
        };
        enrollments.push(record);
        itemEnrollments.push(record);
      }

      // UN pago por ítem: el combo es un solo ticket por su precio.
      const id = `mem-checkout-payment-${++this.counter}`;
      this.paymentTargets.set(id, {
        userId: input.userId,
        courseIds,
        ...(item.type === 'path' ? { pathId: item.courseId } : {}),
      });
      payments.push({
        id,
        enrollmentId: itemEnrollments[0]!.id,
        amount: item.amount,
        status: 'pending_approval',
      });
    }

    const total = input.items.reduce((sum, item) => sum + item.amount, 0);

    return { userId: input.userId, total, enrollments, payments };
  }
}
