/**
 * 🧠 DOMINIO — currículum del curso ("Aula" del estudiante).
 * Módulos + lecciones con el contenido GATEADO por el estado del pago.
 * Sin dependencias de frameworks ni base de datos.
 */

/** Lección del temario. El contenido solo viaja con acceso aprobado. */
export interface CurriculumLesson {
  id: string;
  title: string;
  /** 'recorded' | 'live' | 'drive' | ... (clave de la BD). */
  contentType: string;
  order: number;
  /** URL del contenido (video/zoom/drive); null SIN pago aprobado. */
  contentUrl: string | null;
  /** Texto de la lección; null SIN pago aprobado. */
  contentText: string | null;
  /** Archivo o enlace adjunto; null SIN pago aprobado. */
  attachmentUrl: string | null;
  /** Nombre visible del adjunto; null SIN pago aprobado. */
  attachmentName: string | null;
  /** true = el usuario la marcó como completada. */
  isCompleted: boolean;
}

export interface CurriculumModule {
  id: string;
  title: string;
  order: number;
  lessons: CurriculumLesson[];
}

/**
 * Acceso del usuario al curso:
 *  * full     → pago aprobado: ve contenido y progresa.
 *  * pending  → solicitó, el pago está en verificación manual.
 *  * rejected → el admin rechazó el pago.
 *  * none     → sin sesión o sin inscripción (solo ve el temario).
 */
export type CourseAccess = 'full' | 'pending' | 'rejected' | 'none';

export interface CourseCurriculum {
  courseId: string;
  courseTitle: string;
  access: CourseAccess;
  modules: CurriculumModule[];
  /** Total de lecciones del curso. */
  totalLessons: number;
  /** Lecciones completadas por el usuario (0 sin acceso). */
  completedLessons: number;
}

/** Resultado de marcar/desmarcar una lección. */
export interface LessonProgressResult {
  lessonId: string;
  isCompleted: boolean;
}

/** Avance del usuario en un curso ("Mis cursos": X de Y lecciones). */
export interface CourseProgressSummary {
  courseId: string;
  totalLessons: number;
  completedLessons: number;
}

/**
 * Contrato del currículum. Lo implementa Supabase (producción) y una
 * versión en memoria (tests / desarrollo sin credenciales).
 */
export interface CurriculumRepository {
  /**
   * Temario completo del curso con el acceso del usuario (userId null
   * = sin sesión). null si el curso no existe.
   */
  getCurriculum(
    courseId: string,
    userId: string | null,
  ): Promise<CourseCurriculum | null>;

  /**
   * Marca/desmarca una lección como completada. null si la lección no
   * existe; lanza AccessDeniedError si el pago no está aprobado.
   */
  setLessonProgress(
    userId: string,
    lessonId: string,
    completed: boolean,
  ): Promise<LessonProgressResult | null>;

  /**
   * Avance del usuario en varios cursos (para "Mis cursos"). Devuelve
   * una fila por curso, incluso si no tiene lecciones (0/0).
   */
  getProgressSummaries(
    userId: string,
    courseIds: string[],
  ): Promise<CourseProgressSummary[]>;
}
