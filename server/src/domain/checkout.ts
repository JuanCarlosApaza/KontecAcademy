/**
 * 🧠 DOMINIO — checkout (inscripciones + pagos) y cuenta de usuario.
 * Sin dependencias de Express, ni base de datos, ni frameworks.
 */

/** Item del carrito que llega del front (precio congelado al agregar). */
export interface CheckoutItem {
  /** Id del curso, de la ruta o del plan de membresía según [type]. */
  courseId: string;
  amount: number;
  /** 'course' (default) | 'path' | 'membership'. */
  type?: 'course' | 'path' | 'membership';
}

/** Datos personales + carrito que el front envía al pagar. */
export interface CheckoutInput {
  userId: string;
  email: string;
  fullName: string;
  phone: string | null;
  nationality: string | null;
  documentNumber: string | null;
  items: CheckoutItem[];
}

export interface EnrollmentRecord {
  id: string;
  userId: string;
  courseId: string;
  /**
   * 'pending_payment' | 'approved' | 'rejected' | 'finished'
   * | 'revoked' (acceso retirado por el admin, p. ej. por pago
   * incompleto). Solo 'approved'/'finished' dan acceso al aula.
   */
  status: string;
}

export interface PaymentRecord {
  id: string;
  /** Null en los tickets de MEMBRESÍA (no hay inscripción asociada). */
  enrollmentId: string | null;
  amount: number;
  /** 'pending_approval' | 'approved' | 'rejected' */
  status: string;
}

export interface CheckoutResult {
  userId: string;
  total: number;
  enrollments: EnrollmentRecord[];
  payments: PaymentRecord[];
}

/** Usuario verificado a partir del JWT de Supabase. */
export interface AuthenticatedUser {
  id: string;
  email: string;
}

/** Curso inscrito del estudiante (lista "Mis cursos" del perfil). */
export interface EnrolledCourse {
  courseId: string;
  title: string;
  description: string;
  imageUrl: string | null;
  /** Modalidad ('asynchronous' | 'synchronous' | 'hybrid' | ...). */
  modality: string;
  /** Estado de la INSCRIPCIÓN: pending_payment | approved | rejected
   * | finished | revoked (sin acceso). */
  status: string;
  enrolledAt: string | null;
  /** Total de lecciones del curso (0 sin acceso aprobado). */
  totalLessons: number;
  /** Lecciones completadas por el usuario (0 sin acceso aprobado). */
  completedLessons: number;
}

/**
 * Contrato del checkout. Lo implementa Supabase (producción) y una
 * versión en memoria (tests / desarrollo sin credenciales).
 */
export interface CheckoutRepository {
  /** Verifica el JWT de Supabase; null si es inválido/expirado. */
  verifyToken(token: string): Promise<AuthenticatedUser | null>;

  /** Roles del usuario ('admin', 'student', ...). */
  getRoles(userId: string): Promise<string[]>;

  /**
   * Códigos de permiso del usuario ('users:view', 'courses:create', ...).
   * El rol `admin` recibe TODOS los códigos (bypass calculado, sin
   * depender de los grants de la tabla `role_permissions`).
   */
  getPermissions(userId: string): Promise<string[]>;

  /** Cursos inscritos del usuario ("Mis cursos") con su estado. */
  listEnrolledCourses(userId: string): Promise<EnrolledCourse[]>;

  /** Estado de la inscripción en un curso; null si no está inscrito. */
  getEnrollmentStatus(userId: string, courseId: string): Promise<string | null>;

  /**
   * Cursos de una ruta (combo), en orden; null si la ruta no existe.
   * Lo usa el checkout para expandir un ítem tipo 'path' en N
   * inscripciones.
   */
  getPathCourseIds(pathId: string): Promise<string[] | null>;

  /** Actualiza el estado de una inscripción (no-op si no existe). */
  setEnrollmentStatus(
    userId: string,
    courseId: string,
    status: string,
  ): Promise<void>;

  /** Crea/actualiza el usuario, las inscripciones y los pagos. */
  createCheckout(input: CheckoutInput): Promise<CheckoutResult>;
}
