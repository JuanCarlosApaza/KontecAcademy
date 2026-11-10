import type {
  LearningPath,
  LearningPathRepository,
} from '../../domain/learning-path.js';

/**
 * Caso de uso: listado de rutas de entrenamiento.
 * El público solo ve publicadas; el panel admin pasa includeUnpublished.
 */
export class ListLearningPaths {
  constructor(
    private readonly paths: Pick<LearningPathRepository, 'list'>,
  ) {}

  execute(includeUnpublished = false): Promise<LearningPath[]> {
    return this.paths.list(includeUnpublished);
  }
}
