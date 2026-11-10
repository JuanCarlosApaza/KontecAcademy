import type { CatalogRepository, Course } from '../../domain/catalog.js';
import type { ListCoursesDTO } from '../dtos/course_dto.js';

/** Caso de uso: listar los cursos del catálogo (con filtros opcionales). */
export class ListCourses {
  constructor(private readonly catalog: CatalogRepository) {}

  execute(filter?: ListCoursesDTO): Promise<Course[]> {
    return this.catalog.findAllCourses(filter);
  }
}
