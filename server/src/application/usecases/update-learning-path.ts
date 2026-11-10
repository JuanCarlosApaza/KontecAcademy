import { slugFromPathTitle } from '../../domain/learning-path.js';
import type {
  LearningPath,
  LearningPathRepository,
} from '../../domain/learning-path.js';
import type { UpdatePathDTO } from '../dtos/learning_path_dto.js';

/** Caso de uso: editar la cabecera de una ruta (null si no existe). */
export class UpdateLearningPath {
  constructor(
    private readonly paths: Pick<LearningPathRepository, 'update'>,
  ) {}

  execute(dto: UpdatePathDTO): Promise<LearningPath | null> {
    const slug = dto.slug ?? slugFromPathTitle(dto.title);
    return this.paths.update(dto.id, {
      slug,
      title: dto.title,
      description: dto.description,
      coverUrl: dto.coverUrl,
      modality: dto.modality,
      durationHours: dto.durationHours,
      accessMonths: dto.accessMonths,
      discountPercent: dto.discountPercent,
      sortOrder: dto.sortOrder,
      isPublished: dto.isPublished,
    });
  }
}
