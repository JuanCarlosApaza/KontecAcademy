import { AccessDeniedError } from '../application/errors.js';
import type { CatalogRepository } from '../domain/catalog.js';
import type { CheckoutRepository } from '../domain/checkout.js';
import type { MembershipRepository } from '../domain/membership.js';
import type {
  CourseAccess,
  CourseCurriculum,
  CourseProgressSummary,
  CurriculumRepository,
  CurriculumLesson,
  LessonProgressResult,
} from '../domain/curriculum.js';

/** Lección sembrada (memoria) del aula. */
interface SeedLesson {
  id: string;
  title: string;
  contentType: string;
  order: number;
  contentUrl: string;
  /** Opcional: texto y adjunto (tipos text/file/link). */
  contentText?: string;
  attachmentUrl?: string;
  attachmentName?: string;
}

/** Módulo sembrado (memoria) del aula. */
interface SeedModule {
  id: string;
  title: string;
  order: number;
  lessons: SeedLesson[];
}

/**
 * 🔌 DATOS — currículum en memoria (tests y desarrollo sin Supabase).
 * Sembra el temario del curso demo del catálogo; el acceso depende de
 * las inscripciones del InMemoryCheckoutRepository (checkout → pago
 * aprobado por el admin) y el progreso vive en un Map por usuario.
 */
export class InMemoryCurriculumRepository implements CurriculumRepository {
  /** Temario por courseId (solo el curso demo tiene semillas). */
  private readonly seeds: Record<string, SeedModule[]> = {
    'a0000000-0000-0000-0000-000000000001': [
      {
        id: 'mem-module-1',
        title: 'Módulo 1: Fundamentos de Análisis Sismorresistente',
        order: 1,
        lessons: [
          {
            id: 'mem-lesson-0',
            title: 'Bienvenida al curso',
            contentType: 'text',
            order: 1,
            contentUrl: '',
            contentText:
              '¡Bienvenido al curso! Aquí encontrarás todo el material ' +
              'ordenado módulo a módulo. Recomendamos seguir el temario ' +
              'en orden y usar el foro de consultas.',
          },
          {
            id: 'mem-lesson-1',
            title: 'Introducción a las fuerzas sísmicas',
            contentType: 'recorded',
            order: 2,
            contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          },
          {
            id: 'mem-lesson-2',
            title: 'Revisión de la norma E.030',
            contentType: 'recorded',
            order: 3,
            contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          },
        ],
      },
      {
        id: 'mem-module-2',
        title: 'Módulo 2: Diseño de Columnas y Vigas',
        order: 2,
        lessons: [
          {
            id: 'mem-lesson-3',
            title: 'Cálculo de acero en vigas principales',
            contentType: 'recorded',
            order: 1,
            contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          },
        ],
      },
    ],
  };

  /** Progreso por usuario: `${userId}::${lessonId}` → completada. */
  private readonly progress = new Map<string, boolean>();

  constructor(
    private readonly catalog: Pick<CatalogRepository, 'findById'>,
    private readonly checkout: Pick<CheckoutRepository, 'getEnrollmentStatus'>,
    private readonly memberships?: Pick<MembershipRepository, 'findActive'>,
  ) {}

  async getCurriculum(
    courseId: string,
    userId: string | null,
  ): Promise<CourseCurriculum | null> {
    const course = await this.catalog.findById(courseId);
    if (!course) return null;

    const access = await this.resolveAccess(courseId, userId);

    let completedLessons = 0;
    const totalLessons = (this.seeds[courseId] ?? []).reduce(
      (sum, module) => sum + module.lessons.length,
      0,
    );

    const modules = (this.seeds[courseId] ?? []).map((module) => ({
      id: module.id,
      title: module.title,
      order: module.order,
      lessons: module.lessons.map<CurriculumLesson>((lesson) => {
        const isCompleted =
          access === 'full' &&
          this.progress.get(`${userId}::${lesson.id}`) === true;
        if (isCompleted) completedLessons++;

        return {
          id: lesson.id,
          title: lesson.title,
          contentType: lesson.contentType,
          order: lesson.order,
          // Contenido SOLO con pago aprobado.
          contentUrl: access === 'full' ? lesson.contentUrl : null,
          contentText: access === 'full' ? (lesson.contentText ?? null) : null,
          attachmentUrl:
            access === 'full' ? (lesson.attachmentUrl ?? null) : null,
          attachmentName:
            access === 'full' ? (lesson.attachmentName ?? null) : null,
          isCompleted,
        };
      }),
    }));

    return {
      courseId: course.id,
      courseTitle: course.title,
      access,
      modules,
      totalLessons,
      completedLessons,
    };
  }

  async setLessonProgress(
    userId: string,
    lessonId: string,
    completed: boolean,
  ): Promise<LessonProgressResult | null> {
    // Busca la lección en los seeds para conocer su curso (el gate).
    let lessonCourseId: string | null = null;
    for (const [courseId, modules] of Object.entries(this.seeds)) {
      const found = modules.some((module) =>
        module.lessons.some((lesson) => lesson.id === lessonId),
      );
      if (found) {
        lessonCourseId = courseId;
        break;
      }
    }
    if (!lessonCourseId) return null; // lección inexistente → 404

    // Membresía activa = acceso total (mismo criterio que el aula).
    const active = await this.memberships?.findActive(userId);
    if (active) {
      this.progress.set(`${userId}::${lessonId}`, completed);
      return { lessonId, isCompleted: completed };
    }

    const status = await this.checkout.getEnrollmentStatus(
      userId,
      lessonCourseId,
    );
    if (status !== 'approved' && status !== 'finished') {
      throw new AccessDeniedError(
        'Tu pago aún no está aprobado. El admin debe verificarlo antes de avanzar en el curso.',
      );
    }

    this.progress.set(`${userId}::${lessonId}`, completed);
    return { lessonId, isCompleted: completed };
  }

  async getProgressSummaries(
    userId: string,
    courseIds: string[],
  ): Promise<CourseProgressSummary[]> {
    return courseIds.map((courseId) => {
      const lessons = (this.seeds[courseId] ?? []).flatMap(
        (module) => module.lessons,
      );
      const completedLessons = lessons.filter(
        (lesson) => this.progress.get(`${userId}::${lesson.id}`) === true,
      ).length;

      return {
        courseId,
        totalLessons: lessons.length,
        completedLessons,
      };
    });
  }

  /** Estado de la inscripción → acceso del aula. */
  private async resolveAccess(
    courseId: string,
    userId: string | null,
  ): Promise<CourseAccess> {
    if (!userId) return 'none';

    // Membresía activa = acceso total a cualquier curso.
    const active = await this.memberships?.findActive(userId);
    if (active) return 'full';

    const status = await this.checkout.getEnrollmentStatus(userId, courseId);
    if (status === 'approved' || status === 'finished') return 'full';
    if (status === 'pending_payment') return 'pending';
    if (status === 'rejected') return 'rejected';
    return 'none';
  }
}
