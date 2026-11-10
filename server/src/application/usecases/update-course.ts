import type { CatalogRepository, Course } from '../../domain/catalog.js';
import type { CourseDTO } from '../dtos/course_dto.js';
import { assertCategoryExists } from './assert-category-exists.js';

/**
 * Caso de uso: actualizar un curso (panel administrativo).
 * Null si el id no existe. El "eliminar" del panel es un CAMBIO DE
 * ESTADO (status: 'inactive'); nunca se borra la fila.
 */
export class UpdateCourse {
  constructor(private readonly catalog: CatalogRepository) {}

  async execute(id: string, dto: CourseDTO): Promise<Course | null> {
    await assertCategoryExists(this.catalog, dto.categoryId);
    return this.catalog.updateCourse(id, dto);
  }
}
