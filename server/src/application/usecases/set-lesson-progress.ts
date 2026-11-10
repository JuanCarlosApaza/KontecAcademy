import type { AuthenticatedUser } from '../../domain/checkout.js';
import type {
  CurriculumRepository,
  LessonProgressResult,
} from '../../domain/curriculum.js';

/**
 * Caso de uso: marcar/desmarcar una lección como completada.
 * El repositorio exige pago APROBADO (si no, lanza AccessDeniedError
 * → 403); la lección inexistente vuelve null (→ 404).
 */
export class SetLessonProgress {
  constructor(
    private readonly curriculum: Pick<
      CurriculumRepository,
      'setLessonProgress'
    >,
  ) {}

  execute(
    user: AuthenticatedUser,
    lessonId: string,
    completed: boolean,
  ): Promise<LessonProgressResult | null> {
    return this.curriculum.setLessonProgress(user.id, lessonId, completed);
  }
}
