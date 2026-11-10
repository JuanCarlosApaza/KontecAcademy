import type {
  CourseProgressSummary,
  CurriculumRepository,
} from '../../domain/curriculum.js';
import type {
  AuthenticatedUser,
  CheckoutRepository,
  EnrolledCourse,
} from '../../domain/checkout.js';

/**
 * Caso de uso: cursos inscritos del estudiante ("Mis cursos").
 * Devuelve TODOS los estados para que el front muestre los aprobados
 * (con acceso) y avise si hay uno pendiente de verificación de pago.
 *
 * Los cursos con pago APROBADO traen además `totalLessons` y
 * `completedLessons` (del currículum) para pintar el % de avance.
 */
export class GetMyCourses {
  constructor(
    private readonly checkout: Pick<CheckoutRepository, 'listEnrolledCourses'>,
    private readonly curriculum: Pick<
      CurriculumRepository,
      'getProgressSummaries'
    >,
  ) {}

  async execute(user: AuthenticatedUser): Promise<EnrolledCourse[]> {
    const courses = await this.checkout.listEnrolledCourses(user.id);

    // Solo los cursos con acceso tienen progreso que mostrar; los
    // pendientes/rechazados quedan en 0/0 (la UI no pinta la barra).
    // 'membership' = acceso por membresía activa (también avanza).
    const accessibleIds = courses
      .filter(
        (c) =>
          c.status === 'approved' ||
          c.status === 'finished' ||
          c.status === 'membership',
      )
      .map((c) => c.courseId);

    const summaries = accessibleIds.length
      ? await this.curriculum.getProgressSummaries(user.id, accessibleIds)
      : [];
    const byCourse = new Map<string, CourseProgressSummary>(
      summaries.map((s) => [s.courseId, s]),
    );

    return courses.map((course) => {
      const summary = byCourse.get(course.courseId);
      return {
        ...course,
        totalLessons: summary?.totalLessons ?? 0,
        completedLessons: summary?.completedLessons ?? 0,
      };
    });
  }
}
