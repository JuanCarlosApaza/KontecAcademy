import type { AdminRepository } from '../../domain/admin.js';

/** Caso de uso: borrar una lección y su progreso. */
export class DeleteLesson {
  constructor(
    private readonly admin: Pick<AdminRepository, 'deleteLesson'>,
  ) {}

  /** false = la lección no existe (la ruta responde 404). */
  execute(lessonId: string): Promise<boolean> {
    return this.admin.deleteLesson(lessonId);
  }
}
