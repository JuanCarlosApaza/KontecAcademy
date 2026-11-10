import type {
  LearningPath,
  LearningPathRepository,
} from '../../domain/learning-path.js';

/** Caso de uso: ruta por slug (null si no existe o no está publicada). */
export class GetLearningPathBySlug {
  constructor(
    private readonly paths: Pick<LearningPathRepository, 'findBySlug'>,
  ) {}

  execute(slug: string): Promise<LearningPath | null> {
    return this.paths.findBySlug(slug);
  }
}
