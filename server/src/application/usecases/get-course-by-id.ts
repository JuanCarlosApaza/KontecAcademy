import type { CatalogRepository, Course } from '../../domain/catalog.js';

/** Los ids de curso son UUIDs de la BD. */
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Caso de uso: detalle de un curso. Null si el id no existe (o si no
 * tiene formato UUID: no hay curso posible y se evita el error de BD).
 */
export class GetCourseById {
  constructor(private readonly catalog: CatalogRepository) {}

  execute(id: string): Promise<Course | null> {
    if (!UUID_PATTERN.test(id)) {
      return Promise.resolve(null);
    }
    return this.catalog.findById(id);
  }
}
