import type { AuthenticatedUser } from '../../domain/checkout.js';
import type {
  CourseCurriculum,
  CurriculumRepository,
} from '../../domain/curriculum.js';

/**
 * Caso de uso: currículum del curso ("Aula" del estudiante).
 * El temario (módulos/lecciones) es PÚBLICO; el contenido (URL del
 * video/zoom/drive) y el progreso dependen del estado del pago del
 * usuario autenticado (userId null = sin sesión).
 */
export class GetCurriculum {
  constructor(
    private readonly curriculum: Pick<CurriculumRepository, 'getCurriculum'>,
  ) {}

  execute(
    user: AuthenticatedUser | null,
    courseId: string,
  ): Promise<CourseCurriculum | null> {
    return this.curriculum.getCurriculum(courseId, user?.id ?? null);
  }
}
