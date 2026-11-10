/**
 * 🧠 DOMINIO — panel administrativo.
 * KPIs del dashboard, listado de estudiantes y altas (usuarios,
 * categorías). Sin dependencias de frameworks.
 */

export interface AdminStats {
  students: number;
  courses: number;
  enrollments: number;
  /** Pagos esperando aprobación de ticket. */
  pendingPayments: number;
  /** Ingresos aprobados (USD). */
  revenue: number;
}

export interface StudentRecord {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  createdAt: string | null;
  /** Cursos en los que está inscrito. */
  enrolledCourses: number;
  /** false = cuenta desactivada (borrado lógico, nunca se borra la fila). */
  isActive: boolean;
}

export interface CategoryRecord {
  id: string;
  name: string;
  slug: string;
}

export interface NewUserInput {
  email: string;
  /** Contraseña temporal (el usuario puede cambiarla después). */
  password: string;
  fullName: string;
  phone: string | null;
  /** 'admin' | 'student' | 'teacher' | ... */
  role: string;
}

/** Usuario del panel (cualquier rol: admin, teacher, student, sin rol). */
export interface UserRecord {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  createdAt: string | null;
  /** Nombres de rol ('admin', 'teacher', 'student', ...). */
  roles: string[];
  /** false = cuenta desactivada (borrado lógico, nunca se borra la fila). */
  isActive: boolean;
}

/** Datos para editar un usuario desde el panel (sin tocar el email). */
export interface UpdateUserInput {
  id: string;
  fullName: string;
  phone: string | null;
  /** Rol único: reemplaza los roles actuales ('' = sin rol). */
  role: string;
  /** false = desactiva el acceso; la cuenta y sus datos se conservan. */
  isActive: boolean;
}

/** Archivo de imagen que llega desde el formulario de cursos. */
export interface ImageUploadInput {
  buffer: Buffer;
  filename: string;
  contentType: string;
}

/** Imagen ya guardada en el bucket de Storage (pública). */
export interface ImageUploadRecord {
  path: string;
  publicUrl: string;
}

/** Ítem del carrito de un usuario (carritos abandonados del panel). */
export interface AbandonedCartItem {
  userId: string;
  email: string;
  fullName: string;
  courseId: string;
  title: string;
  price: number;
  addedAt: string;
}

/** Pago del panel administrativo, con datos del usuario y del curso. */
export interface PaymentRecord {
  id: string;
  userId: string;
  email: string;
  fullName: string;
  courseId: string;
  courseTitle: string;
  amount: number;
  /** 'pending_approval' | 'approved' | 'rejected' */
  status: string;
  createdAt: string;
  /** Pago de COMBO: id de la ruta comprada (null = curso suelto). */
  pathId: string | null;
  /** Título de la ruta (para identificar el ticket en el panel). */
  pathTitle: string | null;
}

/** Resultado de aprobar/rechazar un pago desde el panel. */
export interface PaymentDecision {
  id: string;
  /** 'approved' (acceso al curso) | 'rejected' (sin acceso). */
  status: string;
}

/** Participante de un curso (inscripción + datos del estudiante). */
export interface CourseParticipant {
  userId: string;
  fullName: string;
  email: string;
  phone: string | null;
  /** Estado de la INSCRIPCIÓN: pending_payment | approved | rejected
   * | finished | revoked. */
  status: string;
  enrolledAt: string | null;
}

/** Inscripción del estudiante en el perfil (con el título del curso). */
export interface StudentEnrollment {
  courseId: string;
  title: string;
  /** Estado de la INSCRIPCIÓN (ver [CourseParticipant.status]). */
  status: string;
  enrolledAt: string | null;
}

/** Perfil del estudiante + sus cursos (pantalla de detalle del panel). */
export interface StudentProfile {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  nationality: string | null;
  createdAt: string | null;
  isActive: boolean;
  enrollments: StudentEnrollment[];
}

/** Lección tal y como la edita el admin (con TODAS sus URLs). */
export interface AdminLesson {
  id: string;
  title: string;
  /** 'recorded' | 'live' | 'drive' (clave libre en la BD). */
  contentType: string;
  orderIndex: number;
  videoUrl: string | null;
  zoomUrl: string | null;
  driveUrl: string | null;
  /** Texto de la lección (tipo 'text': bienvenida, guía, notas). */
  contentText: string | null;
  /** Archivo o enlace adjunto (tipo 'file' | 'link'). */
  attachmentUrl: string | null;
  /** Nombre visible del adjunto (ej: "Syllabus.pdf"). */
  attachmentName: string | null;
}

/** Módulo del temario con sus lecciones ya ordenadas. */
export interface AdminModule {
  id: string;
  title: string;
  orderIndex: number;
  lessons: AdminLesson[];
}

/** Temario completo de un curso (sección "Temario" del panel). */
export interface AdminCurriculum {
  courseId: string;
  courseTitle: string;
  modules: AdminModule[];
}

/** Alta de una lección desde el panel. */
export interface NewLessonInput {
  title: string;
  contentType: string;
  videoUrl: string | null;
  zoomUrl: string | null;
  driveUrl: string | null;
  contentText: string | null;
  attachmentUrl: string | null;
  attachmentName: string | null;
}

/** Edición parcial de un módulo (título y/o posición). */
export interface UpdateModuleInput {
  title?: string;
  orderIndex?: number;
}

/** Edición parcial de una lección (campos y/o posición). */
export interface UpdateLessonInput extends Partial<NewLessonInput> {
  orderIndex?: number;
}

/**
 * Contrato del panel admin. Lo implementa Supabase (producción) y una
 * versión en memoria (tests / desarrollo sin credenciales).
 */
export interface AdminRepository {
  getStats(): Promise<AdminStats>;
  findStudents(): Promise<StudentRecord[]>;
  /** Todos los usuarios + sus roles (sección "Usuarios"). */
  findUsers(): Promise<UserRecord[]>;
  createCategory(name: string, slug: string): Promise<CategoryRecord>;
  /** Renombra una categoría; null si el id no existe. */
  updateCategory(
    id: string,
    name: string,
    slug: string,
  ): Promise<CategoryRecord | null>;
  createUser(input: NewUserInput): Promise<{ id: string; email: string }>;
  /** Actualiza perfil, rol y estado de un usuario; null si no existe. */
  updateUser(input: UpdateUserInput): Promise<UserRecord | null>;
  /** Sube una imagen al bucket de Storage y devuelve su URL pública. */
  uploadImage(input: ImageUploadInput): Promise<ImageUploadRecord>;
  /** Carritos abandonados: usuarios con carrito no vacío (addedAt desc). */
  listAbandonedCarts(): Promise<AbandonedCartItem[]>;
  /** Pagos filtrados por estado ('pending_approval' | 'approved' | 'rejected'). */
  listPayments(status: string): Promise<PaymentRecord[]>;
  /**
   * Aprueba o rechaza un pago (verificación MANUAL del admin) y
   * actualiza la inscripción asociada: 'approved' CONCEDE el acceso al
   * curso, 'rejected' lo retira. null si el pago no existe.
   */
  decidePayment(
    paymentId: string,
    status: string,
    adminUserId: string,
  ): Promise<PaymentDecision | null>;
  // ── PARTICIPANTES + PERFIL DEL ESTUDIANTE ────────────────────
  /** Participantes de un curso (inscripción + datos), enrolledAt desc. */
  listCourseParticipants(courseId: string): Promise<CourseParticipant[]>;
  /** Perfil del estudiante + sus inscripciones; null si no existe. */
  getStudentProfile(studentId: string): Promise<StudentProfile | null>;
  // ── TEMARIO (módulos + lecciones) ─────────────────────────────
  /** Temario completo del curso; null si el curso no existe. */
  getCourseCurriculum(courseId: string): Promise<AdminCurriculum | null>;
  /** Alta de módulo: se coloca el último del curso. */
  createModule(courseId: string, title: string): Promise<AdminModule>;
  /** Edición de módulo; null si no existe. */
  updateModule(
    moduleId: string,
    input: UpdateModuleInput,
  ): Promise<AdminModule | null>;
  /** Borrado en CASCADA: lecciones + su progreso. false si no existe. */
  deleteModule(moduleId: string): Promise<boolean>;
  /** Alta de lección: se coloca la última del módulo. */
  createLesson(
    moduleId: string,
    input: NewLessonInput,
  ): Promise<AdminLesson>;
  /** Edición de lección; null si no existe. */
  updateLesson(
    lessonId: string,
    input: UpdateLessonInput,
  ): Promise<AdminLesson | null>;
  /** Borra la lección y su progreso. false si no existe. */
  deleteLesson(lessonId: string): Promise<boolean>;
}
