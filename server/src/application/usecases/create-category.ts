import { slugFromName } from '../../domain/catalog.js';
import type {
  AdminRepository,
  CategoryRecord,
} from '../../domain/admin.js';
import type { CreateCategoryDTO } from '../dtos/category_dto.js';

/** Caso de uso: crear una categoría del catálogo. */
export class CreateCategory {
  constructor(
    private readonly admin: Pick<AdminRepository, 'createCategory'>,
  ) {}

  execute(dto: CreateCategoryDTO): Promise<CategoryRecord> {
    // Regla de negocio única: si el slug no viene, se deriva del nombre.
    const slug = dto.slug ?? slugFromName(dto.name);
    return this.admin.createCategory(dto.name, slug);
  }
}
