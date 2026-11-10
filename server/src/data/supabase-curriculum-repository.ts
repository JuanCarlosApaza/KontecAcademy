import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { AccessDeniedError } from '../application/errors.js';
import type {
  CourseAccess,
  CourseCurriculum,
  CourseProgressSummary,
  CurriculumLesson,
  CurriculumModule,
  CurriculumRepository,
  LessonProgressResult,
} from '../domain/curriculum.js';
import { asRows } from './postgrest-rows.js';

/** Fila de `modules` con las lecciones embebidas (uno-a-muchos → array). */
interface ModuleWithLessonsRow {
  id: string;
  title: string;
  order_index: number;
  lessons: {
    id: string;
    title: string;
    content_type: string;
    video_url: string | null;
    zoom_url: string | null;
    drive_url: string | null;
    content_text: string | null;
    attachment_url: string | null;
    attachment_name: string | null;
    order_index: number;
  }[];
}

/**
 * 🔌 DATOS — currículum del curso con Supabase (tabla `modules`,
 * `lessons` y `lesson_progress`).
 *
 * El temario es público (sin sesión → access 'none' y contentUrl
 * null). El contenido solo viaja con inscripción APROBADA, y el
 * progreso (lesson_progress) se lee y escribe por usuario.
 */
export class SupabaseCurriculumRepository implements CurriculumRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async getCurriculum(
    courseId: string,
    userId: string | null,
  ): Promise<CourseCurriculum | null> {
    const { data: course, error: courseError } = await this.client
      .from('courses')
      .select('id, title')
      .eq('id', courseId)
      .maybeSingle();

    if (courseError) {
      throw new Error(`Supabase getCurriculum (courses): ${courseError.message}`);
    }
    if (!course) return null; // curso inexistente → 404 en la ruta

    const access = await this.resolveAccess(courseId, userId);

    const { data: modules, error: modulesError } = await this.client
      .from('modules')
      .select(
        'id, title, order_index, lessons ( id, title, content_type, video_url, zoom_url, drive_url, content_text, attachment_url, attachment_name, order_index )',
      )
      .eq('course_id', courseId)
      .order('order_index', { ascending: true });

    if (modulesError) {
      throw new Error(
        `Supabase getCurriculum (modules): ${modulesError.message}`,
      );
    }

    // El embed modules → lessons (uno-a-muchos → array): lo normaliza
    // asRows, que resuelve la discrepancia de forma sin tipos generados.
    const rows = asRows<ModuleWithLessonsRow>(modules);

    // Progreso del usuario: solo interesa con acceso completo.
    const lessonIds = rows.flatMap((row) =>
      (row.lessons ?? []).map((lesson) => lesson.id),
    );
    const completedIds =
      access === 'full' && userId
        ? await this.fetchCompletedLessonIds(userId, lessonIds)
        : new Set<string>();

    let completedLessons = 0;
    const mapped: CurriculumModule[] = rows.map((row) => {
      // Lecciones ordenadas en JS (el orden embebido no es confiable).
      const lessons: CurriculumLesson[] = [...(row.lessons ?? [])]
        .sort((a, b) => a.order_index - b.order_index)
        .map((lesson) => {
          const isCompleted = completedIds.has(lesson.id);
          if (isCompleted) completedLessons++;
          return {
            id: lesson.id,
            title: lesson.title,
            contentType: lesson.content_type,
            order: lesson.order_index,
            // Contenido SOLO con pago aprobado.
            contentUrl:
              access === 'full'
                ? (lesson.video_url ??
                  lesson.zoom_url ??
                  lesson.drive_url ??
                  null)
                : null,
            contentText: access === 'full' ? lesson.content_text : null,
            attachmentUrl: access === 'full' ? lesson.attachment_url : null,
            attachmentName: access === 'full' ? lesson.attachment_name : null,
            isCompleted,
          };
        });

      return {
        id: row.id,
        title: row.title,
        order: row.order_index,
        lessons,
      };
    });

    return {
      courseId: course.id,
      courseTitle: course.title,
      access,
      modules: mapped,
      totalLessons: lessonIds.length,
      completedLessons,
    };
  }

  async setLessonProgress(
    userId: string,
    lessonId: string,
    completed: boolean,
  ): Promise<LessonProgressResult | null> {
    // 1) La lección debe existir (y conocer su curso, para el gate).
    const { data: lesson, error: lessonError } = await this.client
      .from('lessons')
      .select('id, module_id')
      .eq('id', lessonId)
      .maybeSingle();

    if (lessonError) {
      throw new Error(
        `Supabase setLessonProgress (lessons): ${lessonError.message}`,
      );
    }
    if (!lesson) return null;

    const { data: module, error: moduleError } = await this.client
      .from('modules')
      .select('course_id')
      .eq('id', (lesson as { module_id: string }).module_id)
      .maybeSingle();

    if (moduleError) {
      throw new Error(
        `Supabase setLessonProgress (modules): ${moduleError.message}`,
      );
    }
    if (!module) return null;

    // 2) Gate: solo con pago aprobado se puede avanzar el progreso.
    const courseId = (module as { course_id: string }).course_id;
    const status = await this.resolveEnrollmentStatus(userId, courseId);
    if (status !== 'approved' && status !== 'finished') {
      throw new AccessDeniedError(
        'Tu pago aún no está aprobado. El admin debe verificarlo antes de avanzar en el curso.',
      );
    }

    // 3) Upsert manual en lesson_progress (sin unique (user, lesson)):
    //    si ya existe la fila del usuario, se actualiza; si no, se crea.
    const { data: existing, error: progressError } = await this.client
      .from('lesson_progress')
      .select('id')
      .eq('user_id', userId)
      .eq('lesson_id', lessonId)
      .maybeSingle();

    if (progressError) {
      throw new Error(
        `Supabase setLessonProgress (select): ${progressError.message}`,
      );
    }

    const now = new Date().toISOString();

    if (existing) {
      const { error } = await this.client
        .from('lesson_progress')
        .update({ is_completed: completed, updated_at: now })
        .eq('id', (existing as { id: string }).id);
      if (error) {
        throw new Error(`Supabase setLessonProgress (update): ${error.message}`);
      }
    } else {
      const { error } = await this.client
        .from('lesson_progress')
        .insert({ user_id: userId, lesson_id: lessonId, is_completed: completed });
      if (error) {
        throw new Error(`Supabase setLessonProgress (insert): ${error.message}`);
      }
    }

    return { lessonId, isCompleted: completed };
  }

  async getProgressSummaries(
    userId: string,
    courseIds: string[],
  ): Promise<CourseProgressSummary[]> {
    if (courseIds.length === 0) return [];

    // 1) Módulos con lecciones de los cursos pedidos → total por curso
    //    + mapa lesson_id → course_id.
    const { data: modules, error: modulesError } = await this.client
      .from('modules')
      .select('course_id, lessons ( id )')
      .in('course_id', courseIds);

    if (modulesError) {
      throw new Error(
        `Supabase getProgressSummaries (modules): ${modulesError.message}`,
      );
    }

    const totals = new Map<string, number>();
    for (const id of courseIds) totals.set(id, 0);
    const courseOfLesson = new Map<string, string>();

    for (const row of asRows<{ course_id: string; lessons: { id: string }[] }>(
      modules,
    )) {
      for (const lesson of row.lessons ?? []) {
        totals.set(row.course_id, (totals.get(row.course_id) ?? 0) + 1);
        courseOfLesson.set(lesson.id, row.course_id);
      }
    }

    // 2) Lecciones completadas por el usuario → se atribuyen a su curso.
    const completed = new Map<string, number>();
    for (const id of courseIds) completed.set(id, 0);

    if (courseOfLesson.size > 0) {
      const { data, error } = await this.client
        .from('lesson_progress')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('is_completed', true)
        .in('lesson_id', [...courseOfLesson.keys()]);

      if (error) {
        throw new Error(`Supabase getProgressSummaries: ${error.message}`);
      }

      for (const row of data ?? []) {
        const courseId = courseOfLesson.get(
          (row as { lesson_id: string }).lesson_id,
        );
        if (courseId) {
          completed.set(courseId, (completed.get(courseId) ?? 0) + 1);
        }
      }
    }

    return courseIds.map((courseId) => ({
      courseId,
      totalLessons: totals.get(courseId) ?? 0,
      completedLessons: completed.get(courseId) ?? 0,
    }));
  }

  /** Acceso del usuario según su inscripción (null = sin sesión). */
  private async resolveAccess(
    courseId: string,
    userId: string | null,
  ): Promise<CourseAccess> {
    if (!userId) return 'none';
    const status = await this.resolveEnrollmentStatus(userId, courseId);
    return accessFromStatus(status);
  }

  private async resolveEnrollmentStatus(
    userId: string,
    courseId: string,
  ): Promise<string | null> {
    // MEMBRESÍA ACTIVA = acceso total a cualquier curso (sin
    // inscripción por curso). Se devuelve 'approved' para reutilizar
    // el mapeo existente accessFromStatus → 'full' (el aula y el
    // guard de progreso de lecciones quedan cubiertos con esto).
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
        `Supabase memberships (active): ${membershipError.message}`,
      );
    }
    if (membership) return 'approved';

    const { data, error } = await this.client
      .from('enrollments')
      .select('status')
      .eq('user_id', userId)
      .eq('course_id', courseId)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase enrollments (status): ${error.message}`);
    }
    return data ? (data as { status: string }).status : null;
  }

  /** Lecciones completadas por el usuario (Set de lesson_id). */
  private async fetchCompletedLessonIds(
    userId: string,
    lessonIds: string[],
  ): Promise<Set<string>> {
    if (lessonIds.length === 0) return new Set<string>();

    const { data, error } = await this.client
      .from('lesson_progress')
      .select('lesson_id')
      .eq('user_id', userId)
      .eq('is_completed', true)
      .in('lesson_id', lessonIds);

    if (error) {
      throw new Error(`Supabase lesson_progress: ${error.message}`);
    }

    return new Set((data ?? []).map((row) => (row as { lesson_id: string }).lesson_id));
  }
}

/** Estado de la inscripción → acceso del aula. */
function accessFromStatus(status: string | null): CourseAccess {
  if (status === 'approved' || status === 'finished') return 'full';
  if (status === 'pending_payment') return 'pending';
  if (status === 'rejected') return 'rejected';
  // 'revoked' (acceso retirado por el admin) y cualquier estado
  // desconocido caen aquí: sin contenido.
  return 'none';
}
