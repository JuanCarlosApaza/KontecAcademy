import type { CatalogRepository, Course } from '../../domain/catalog.js';
import type { CourseDTO } from '../dtos/course_dto.js';
import { assertCategoryExists } from './assert-category-exists.js';

/** Caso de uso: crear un curso (panel administrativo). */
export class CreateCourse {
  constructor(private readonly catalog: CatalogRepository) {}

  async execute(dto: CourseDTO): Promise<Course> {
    await assertCategoryExists(this.catalog, dto.categoryId);
    return this.catalog.createCourse(dto);
  }
}
