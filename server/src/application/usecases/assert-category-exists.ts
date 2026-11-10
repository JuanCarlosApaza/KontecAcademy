import type { CatalogRepository } from '../../domain/catalog.js';
import { ValidationError } from '../errors.js';

/**
 * Verifica que la categoría exista (regla compartida por los casos de
 * uso CreateCourse y UpdateCourse). Lanza [ValidationError] si no.
 */
export async function assertCategoryExists(
  catalog: CatalogRepository,
  categoryId: string | null,
): Promise<void> {
  if (!categoryId) return;

  const categories = await catalog.findAllCategories();
  if (!categories.some((category) => category.id === categoryId)) {
    throw new ValidationError('La categoría indicada no existe');
  }
}
