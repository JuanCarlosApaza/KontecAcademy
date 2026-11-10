import type { CatalogRepository } from '../../domain/catalog.js';
import type {
  LearningPath,
  LearningPathRepository,
} from '../../domain/learning-path.js';
import type { SetPathCoursesDTO } from '../dtos/learning_path_dto.js';
import { ValidationError } from '../errors.js';

/**
 * Caso de uso: reemplaza TODOS los cursos de una ruta (orden + nivel).
 * Valida antes de escribir: la ruta existe y cada curso existe en el
 * catálogo (en Supabase la FK también lo garantiza, pero aquí el
 * cliente recibe un 400 claro en vez de un 500).
 * Devuelve la ruta actualizada o null si la ruta no existe.
 */
export class SetLearningPathCourses {
  constructor(
    private readonly paths: Pick<
      LearningPathRepository,
      'findById' | 'setCourses'
    >,
    private readonly catalog: Pick<CatalogRepository, 'findById'>,
  ) {}

  async execute(
    pathId: string,
    dto: SetPathCoursesDTO,
  ): Promise<LearningPath | null> {
    const path = await this.paths.findById(pathId);
    if (!path) return null;

    for (const entry of dto.courses) {
      const course = await this.catalog.findById(entry.courseId);
      if (!course) {
        throw new ValidationError(
          `El curso ${entry.courseId} no existe en el catálogo`,
        );
      }
    }

    await this.paths.setCourses(
      pathId,
      dto.courses.map((entry, index) => ({
        courseId: entry.courseId,
        level: entry.level,
        sortOrder: entry.sortOrder ?? index,
      })),
    );

    return this.paths.findById(pathId);
  }
}
