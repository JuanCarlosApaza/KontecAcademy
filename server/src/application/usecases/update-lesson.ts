import type { AdminLesson, AdminRepository } from '../../domain/admin.js';
import type { UpdateLessonDTO } from '../dtos/lesson_dto.js';

/** Caso de uso: editar campos/posición de una lección. */
export class UpdateLesson {
  constructor(
    private readonly admin: Pick<AdminRepository, 'updateLesson'>,
  ) {}

  /** null = la lección no existe (la ruta responde 404). */
  execute(
    lessonId: string,
    dto: UpdateLessonDTO,
  ): Promise<AdminLesson | null> {
    return this.admin.updateLesson(lessonId, dto);
  }
}
