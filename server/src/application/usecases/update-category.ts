import { slugFromName } from '../../domain/catalog.js';
import type {
  AdminRepository,
  CategoryRecord,
} from '../../domain/admin.js';
import type { UpdateCategoryDTO } from '../dtos/category_dto.js';

/** Caso de uso: renombrar una categoría. Null si el id no existe. */
export class UpdateCategory {
  constructor(
    private readonly admin: Pick<AdminRepository, 'updateCategory'>,
  ) {}

  execute(dto: UpdateCategoryDTO): Promise<CategoryRecord | null> {
    const slug = dto.slug ?? slugFromName(dto.name);
    return this.admin.updateCategory(dto.id, dto.name, slug);
  }
}
