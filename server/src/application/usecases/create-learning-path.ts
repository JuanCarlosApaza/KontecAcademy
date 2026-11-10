import { slugFromPathTitle } from '../../domain/learning-path.js';
import type {
  LearningPath,
  LearningPathRepository,
} from '../../domain/learning-path.js';
import type { CreatePathDTO } from '../dtos/learning_path_dto.js';

/** Caso de uso: crear una ruta de entrenamiento. */
export class CreateLearningPath {
  constructor(
    private readonly paths: Pick<LearningPathRepository, 'create'>,
  ) {}

  execute(dto: CreatePathDTO): Promise<LearningPath> {
    // Regla de negocio única: si el slug no viene, se deriva del título.
    const slug = dto.slug ?? slugFromPathTitle(dto.title);
    return this.paths.create({
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
