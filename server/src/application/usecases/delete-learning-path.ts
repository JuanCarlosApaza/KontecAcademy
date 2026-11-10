import type { LearningPathRepository } from '../../domain/learning-path.js';

/** Caso de uso: borrar una ruta (false si no existía). */
export class DeleteLearningPath {
  constructor(
    private readonly paths: Pick<LearningPathRepository, 'remove'>,
  ) {}

  execute(id: string): Promise<boolean> {
    return this.paths.remove(id);
  }
}
