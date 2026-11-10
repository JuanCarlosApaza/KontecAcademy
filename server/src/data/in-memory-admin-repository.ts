import type { CatalogRepository } from '../domain/catalog.js';
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

/** Pago resuelto → usuario + cursos que abre (combo = varios). */
interface PaymentTarget {
  userId: string;
  courseIds: string[];
  /** Ticket de combo: id de la ruta comprada. */
  pathId?: string;
  /** Ticket de membresía: id de la membresía comprada. */
  membershipId?: string;
}

/** Perfil del usuario tal y como lo expone el store compartido. */
interface SharedUser {
  fullName: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  createdAt: string;
}

/** Inscripción del store compartido (paridad con `enrollments`). */
interface SharedEnrollment {
  userId: string;
  courseId: string;
  status: string;
  enrolledAt: string;
}

/**
 * Tienda compartida admin ↔ checkout EN MEMORIA (paridad con la BD,
 * donde ambos comparten las tablas enrollments/payments).
 */
interface InMemoryEnrollmentStore {
  setEnrollmentStatus(
    userId: string,
    courseId: string,
    status: string,
  ): Promise<void>;
  /** Pago creado en runtime por el checkout; null si no existe. */
  findPaymentForDecision(
    paymentId: string,
  ): Promise<PaymentTarget | null>;
  /** Aplica la decisión sobre una membresía (pago de plan); false si no existe. */
  decideMembership(
    membershipId: string,
    decision: 'approved' | 'rejected',
  ): Promise<boolean>;
  /** Perfil del usuario registrado en checkout; null si no existe. */
  findUser(userId: string): Promise<SharedUser | null>;
  /** Inscripciones de un curso (enrolledAt desc). */
  listEnrollmentsByCourse(
    courseId: string,
  ): Promise<SharedEnrollment[]>;
  /** Inscripciones de un usuario (enrolledAt desc). */
  listEnrollmentsByUser(userId: string): Promise<SharedEnrollment[]>;
}

/**
 * 🔌 DATOS — panel admin en memoria (tests y desarrollo sin Supabase).
 * Si se inyecta el checkout en memoria, `decidePayment` también
 * actualiza la inscripción del estudiante (igual que en la BD, donde
 * admin y checkout comparten las tablas enrollments/payments).
 */
export class InMemoryAdminRepository implements AdminRepository {
  private counter = 0;

  private readonly categories: CategoryRecord[] = [];

  private readonly users: UserRecord[] = [
    {
      id: 'mem-user-1',
      email: 'dev@kontec.pe',
      fullName: 'Dev Kontec',
      phone: null,
      createdAt: new Date('2026-01-01').toISOString(),
      roles: ['admin', 'student'],
      isActive: true,
    },
  ];

  /**
   * Carritos abandonados de DEMOSTRACIÓN: en modo memoria estos datos
   * son ficticios; la fuente real es Supabase (SupabaseAdminRepository),
   * que lee la tabla `carts` con sus joins a users y courses.
   */
  private readonly abandonedCarts: AbandonedCartItem[] = [
    {
      userId: 'mem-user-2',
      email: 'ana@ejemplo.com',
      fullName: 'Ana Torres',
      courseId: 'a0000000-0000-0000-0000-000000000001',
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      price: 150,
      addedAt: '2026-10-23T10:00:00+00:00',
    },
    {
      userId: 'mem-user-3',
      email: 'luis@ejemplo.com',
      fullName: 'Luis Ramírez',
      courseId: 'a0000000-0000-0000-0000-000000000002',
      title: 'Fundamentos de Geotecnia',
      price: 120,
      addedAt: '2026-10-22T09:30:00+00:00',
    },
  ];

  /**
   * Pagos de DEMOSTRACIÓN separados por status, para que el filtro de
   * listPayments tenga datos reales que comparar en los tests. En modo
   * memoria son ficticios; la fuente real es Supabase (payments →
   * enrollments → users/courses).
   */
  private readonly payments: PaymentRecord[] = [
    {
      id: 'mem-payment-1',
      userId: 'mem-user-2',
      email: 'ana@ejemplo.com',
      fullName: 'Ana Torres',
      courseId: 'a0000000-0000-0000-0000-000000000001',
      courseTitle: 'Diseño Avanzado de Estructuras de Concreto Armado',
      amount: 150,
      status: 'pending_approval',
      createdAt: '2026-10-23T11:00:00+00:00',
      pathId: null,
      pathTitle: null,
    },
    {
      id: 'mem-payment-2',
      userId: 'mem-user-3',
      email: 'luis@ejemplo.com',
      fullName: 'Luis Ramírez',
      courseId: 'a0000000-0000-0000-0000-000000000002',
      courseTitle: 'Fundamentos de Geotecnia',
      amount: 120,
      status: 'pending_approval',
      createdAt: '2026-10-22T08:15:00+00:00',
      pathId: null,
      pathTitle: null,
    },
    {
      id: 'mem-payment-3',
      userId: 'mem-user-1',
      email: 'dev@kontec.pe',
      fullName: 'Dev Kontec',
      courseId: 'a0000000-0000-0000-0000-000000000001',
      courseTitle: 'Diseño Avanzado de Estructuras de Concreto Armado',
      amount: 150,
      status: 'approved',
      createdAt: '2026-10-20T17:45:00+00:00',
      pathId: null,
      pathTitle: null,
    },
    {
      id: 'mem-payment-4',
      userId: 'mem-user-3',
      email: 'luis@ejemplo.com',
      fullName: 'Luis Ramírez',
      courseId: 'a0000000-0000-0000-0000-000000000002',
      courseTitle: 'Fundamentos de Geotecnia',
      amount: 120,
      status: 'rejected',
      createdAt: '2026-10-19T12:00:00+00:00',
      pathId: null,
      pathTitle: null,
    },
  ];

  /**
   * Temario por courseId. Se siembra con el mismo curso demo que usa
   * InMemoryCurriculumRepository para que el CRUD arranque con datos.
   */
  private readonly curricula = new Map<string, AdminModule[]>();

  constructor(
    private readonly enrollments?: InMemoryEnrollmentStore,
    private readonly catalog?: Pick<CatalogRepository, 'findById'>,
  ) {}

  async getStats(): Promise<AdminStats> {
    return {
      students: 0,
      courses: 0,
      enrollments: 0,
      pendingPayments: 0,
      revenue: 0,
    };
  }

  async findStudents(): Promise<StudentRecord[]> {
    return [];
  }

  async findUsers(): Promise<UserRecord[]> {
    return [...this.users];
  }

  async listAbandonedCarts(): Promise<AbandonedCartItem[]> {
    // Orden por addedAt desc (los más recientes primero), igual que la BD.
    return [...this.abandonedCarts].sort((a, b) =>
      b.addedAt.localeCompare(a.addedAt),
    );
  }

  async listPayments(status: string): Promise<PaymentRecord[]> {
    return this.payments.filter((payment) => payment.status === status);
  }

  async decidePayment(
    paymentId: string,
    status: string,
  ): Promise<PaymentDecision | null> {
    // Los pagos pueden ser semillas del panel o creados en runtime por
    // el checkout; en la BD real ambos viven en la tabla `payments`.
    const seed = this.payments.find((item) => item.id === paymentId);
    const runtime = seed
      ? null
      : await this.enrollments?.findPaymentForDecision(paymentId);

    const userId = seed?.userId ?? runtime?.userId ?? null;
    const courseIds = seed ? [seed.courseId] : runtime?.courseIds ?? [];
    // Un pago de MEMBRESÍA no tiene cursos (courseIds vacío) pero sí
    // membershipId: no es un pago inexistente.
    const isMembershipPayment = runtime?.membershipId != null;
    if (!userId || (courseIds.length === 0 && !isMembershipPayment)) {
      return null; // pago inexistente → 404
    }

    if (seed) seed.status = status;

    // Como en la BD (misma transacción): aprobar/rechazar el pago
    // también cambia las inscripciones, que es lo que da o quita acceso
    // al aula. Un pago de combo (runtime con pathId) actualiza TODOS
    // los cursos de la ruta; un pago de membresía activa/revoca el
    // plan. Si no hay tienda compartida (semillas ficticias), no-op.
    if (runtime?.membershipId) {
      await this.enrollments?.decideMembership(
        runtime.membershipId,
        status as 'approved' | 'rejected',
      );
      return { id: paymentId, status };
    }

    if (this.enrollments) {
      for (const courseId of courseIds) {
        await this.enrollments.setEnrollmentStatus(userId, courseId, status);
      }
    }

    return { id: paymentId, status };
  }

  // ── PARTICIPANTES + PERFIL DEL ESTUDIANTE ────────────────────

  async listCourseParticipants(
    courseId: string,
  ): Promise<CourseParticipant[]> {
    if (!this.enrollments) return [];

    const rows = await this.enrollments.listEnrollmentsByCourse(courseId);
    const participants: CourseParticipant[] = [];

    for (const row of rows) {
      const user = await this.enrollments.findUser(row.userId);
      participants.push({
        userId: row.userId,
        fullName: user?.fullName ?? '',
        email: user?.email ?? '',
        phone: user?.phone ?? null,
        status: row.status,
        enrolledAt: row.enrolledAt,
      });
    }

    return participants;
  }

  async getStudentProfile(
    studentId: string,
  ): Promise<StudentProfile | null> {
    const user = await this.enrollments?.findUser(studentId);
    if (!user) return null;

    const rows = await (this.enrollments?.listEnrollmentsByUser(studentId) ??
      Promise.resolve([]));

    const enrollments: StudentEnrollment[] = [];
    for (const row of rows) {
      const course = await this.catalog?.findById(row.courseId);
      enrollments.push({
        courseId: row.courseId,
        title: course?.title ?? row.courseId,
        status: row.status,
        enrolledAt: row.enrolledAt,
      });
    }

    return {
      id: studentId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      nationality: user.nationality,
      createdAt: user.createdAt,
      isActive: true,
      enrollments,
    };
  }

  async uploadImage(input: ImageUploadInput): Promise<ImageUploadRecord> {
    const path = `mem/${input.filename}`;
    return { path, publicUrl: `https://storage.example.test/${path}` };
  }

  async createCategory(name: string, slug: string): Promise<CategoryRecord> {
    const category: CategoryRecord = {
      id: `mem-category-${++this.counter}`,
      name,
      slug,
    };
    this.categories.push(category);
    return category;
  }

  async updateCategory(
    id: string,
    name: string,
    slug: string,
  ): Promise<CategoryRecord | null> {
    const category = this.categories.find((item) => item.id === id);
    if (!category) return null;
    category.name = name;
    category.slug = slug;
    return { ...category };
  }

  async createUser(input: NewUserInput): Promise<{ id: string; email: string }> {
    const id = `mem-user-${++this.counter}`;
    this.users.push({
      id,
      email: input.email,
      fullName: input.fullName,
      phone: input.phone,
      createdAt: new Date().toISOString(),
      roles: input.role ? [input.role] : [],
      isActive: true,
    });
    return { id, email: input.email };
  }

  async updateUser(input: UpdateUserInput): Promise<UserRecord | null> {
    const user = this.users.find((item) => item.id === input.id);
    if (!user) return null;

    user.fullName = input.fullName;
    user.phone = input.phone;
    user.roles = input.role ? [input.role] : [];
    user.isActive = input.isActive;
    return { ...user };
  }

  // ── TEMARIO ──────────────────────────────────────────────────

  async getCourseCurriculum(courseId: string): Promise<AdminCurriculum | null> {
    const course = await this.catalog?.findById(courseId);
    if (this.catalog && !course) return null;

    return {
      courseId,
      courseTitle: course?.title ?? courseId,
      modules: this.modulesOf(courseId).map((module) => ({
        ...module,
        lessons: module.lessons.map((lesson) => ({ ...lesson })),
      })),
    };
  }

  async createModule(courseId: string, title: string): Promise<AdminModule> {
    const modules = this.modulesOf(courseId);
    const module: AdminModule = {
      // Prefijo distinto al del seed: `counter` arranca en 0 y un
      // "mem-module-1" chocaría con el módulo sembrado.
      id: `mem-new-module-${++this.counter}`,
      title,
      orderIndex: modules.length + 1,
      lessons: [],
    };
    modules.push(module);
    return { ...module, lessons: [] };
  }

  async updateModule(
    moduleId: string,
    input: UpdateModuleInput,
  ): Promise<AdminModule | null> {
    const found = this.findModule(moduleId);
    if (!found) return null;

    if (input.title !== undefined) found.module.title = input.title;
    if (input.orderIndex !== undefined) {
      move(found.siblings, found.module, input.orderIndex - 1);
    }

    return { ...found.module, lessons: found.module.lessons.map((l) => ({ ...l })) };
  }

  async deleteModule(moduleId: string): Promise<boolean> {
    const found = this.findModule(moduleId);
    if (!found) return false;

    found.siblings.splice(found.siblings.indexOf(found.module), 1);
    reindex(found.siblings);
    return true;
  }

  async createLesson(
    moduleId: string,
    input: NewLessonInput,
  ): Promise<AdminLesson> {
    const found = this.findModule(moduleId);
    if (!found) {
      throw new Error(`Módulo inexistente: ${moduleId}`);
    }

    const lesson: AdminLesson = {
      // Mismo motivo que en createModule: no chocar con el seed.
      id: `mem-new-lesson-${++this.counter}`,
      title: input.title,
      contentType: input.contentType,
      orderIndex: found.module.lessons.length + 1,
      videoUrl: input.videoUrl,
      zoomUrl: input.zoomUrl,
      driveUrl: input.driveUrl,
      contentText: input.contentText,
      attachmentUrl: input.attachmentUrl,
      attachmentName: input.attachmentName,
    };
    found.module.lessons.push(lesson);
    return { ...lesson };
  }

  async updateLesson(
    lessonId: string,
    input: UpdateLessonInput,
  ): Promise<AdminLesson | null> {
    const found = this.findLesson(lessonId);
    if (!found) return null;

    const { lesson, siblings } = found;
    if (input.title !== undefined) lesson.title = input.title;
    if (input.contentType !== undefined) lesson.contentType = input.contentType;
    if (input.videoUrl !== undefined) lesson.videoUrl = input.videoUrl;
    if (input.zoomUrl !== undefined) lesson.zoomUrl = input.zoomUrl;
    if (input.driveUrl !== undefined) lesson.driveUrl = input.driveUrl;
    if (input.contentText !== undefined) lesson.contentText = input.contentText;
    if (input.attachmentUrl !== undefined) {
      lesson.attachmentUrl = input.attachmentUrl;
    }
    if (input.attachmentName !== undefined) {
      lesson.attachmentName = input.attachmentName;
    }
    if (input.orderIndex !== undefined) {
      move(siblings, lesson, input.orderIndex - 1);
    }
    return { ...lesson };
  }

  async deleteLesson(lessonId: string): Promise<boolean> {
    const found = this.findLesson(lessonId);
    if (!found) return false;

    found.siblings.splice(found.siblings.indexOf(found.lesson), 1);
    reindex(found.siblings);
    return true;
  }

  /** Módulos del curso, sembrados la primera vez que se piden. */
  private modulesOf(courseId: string): AdminModule[] {
    const existing = this.curricula.get(courseId);
    if (existing) return existing;

    const seeded = courseId === 'a0000000-0000-0000-0000-000000000001' ? seedCurriculum() : [];
    this.curricula.set(courseId, seeded);
    return seeded;
  }

  private findModule(
    moduleId: string,
  ): { siblings: AdminModule[]; module: AdminModule } | null {
    for (const siblings of this.curricula.values()) {
      const module = siblings.find((item) => item.id === moduleId);
      if (module) return { siblings, module };
    }
    return null;
  }

  private findLesson(
    lessonId: string,
  ): { siblings: AdminLesson[]; lesson: AdminLesson } | null {
    for (const modules of this.curricula.values()) {
      for (const module of modules) {
        const lesson = module.lessons.find((item) => item.id === lessonId);
        if (lesson) return { siblings: module.lessons, lesson };
      }
    }
    return null;
  }
}

/** Renumera el orden de una lista ya reordenada (1..n). */
function reindex(list: { orderIndex: number }[]): void {
  list.forEach((item, index) => {
    item.orderIndex = index + 1;
  });
}

/** Mueve un ítem a la posición destino (0-based) y renumera. */
function move<T extends { orderIndex: number }>(
  list: T[],
  item: T,
  targetIndex: number,
): void {
  const from = list.indexOf(item);
  const to = Math.max(0, Math.min(targetIndex, list.length - 1));
  if (from < 0 || from === to) return;

  list.splice(from, 1);
  list.splice(to, 0, item);
  reindex(list);
}

/** Temario de demostración del curso demo (paridad con el aula). */
function seedCurriculum(): AdminModule[] {
  const lesson = (
    id: string,
    title: string,
    orderIndex: number,
  ): AdminLesson => ({
    id,
    title,
    contentType: 'recorded',
    orderIndex,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    zoomUrl: null,
    driveUrl: null,
    contentText: null,
    attachmentUrl: null,
    attachmentName: null,
  });

  return [
    {
      id: 'mem-module-1',
      title: 'Módulo 1: Fundamentos de Análisis Sismorresistente',
      orderIndex: 1,
      lessons: [
        lesson('mem-lesson-1', 'Introducción a las fuerzas sísmicas', 1),
        lesson('mem-lesson-2', 'Revisión de la norma E.030', 2),
      ],
    },
    {
      id: 'mem-module-2',
      title: 'Módulo 2: Diseño de Columnas y Vigas',
      orderIndex: 2,
      lessons: [lesson('mem-lesson-3', 'Cálculo de acero en vigas principales', 1)],
    },
  ];
}
