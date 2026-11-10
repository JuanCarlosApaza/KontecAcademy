import { randomUUID } from 'node:crypto';
import { effectivePriceOf, type CatalogRepository } from '../domain/catalog.js';
import {
  durationHoursOf,
  pathPricingOf,
  type LearningPath,
  type LearningPathRepository,
  type NewPathInput,
  type PathCourse,
  type PathCourseEntry,
} from '../domain/learning-path.js';

/**
 * 🔌 DATOS — implementación en memoria de las rutas (tests / dev sin BD).
 * Resuelve los cursos del catálogo para armar las entradas de `setCourses`.
 */
export class InMemoryLearningPathRepository implements LearningPathRepository {
  private readonly paths: LearningPath[] = [];

  constructor(
    private readonly catalog: Pick<CatalogRepository, 'findById'>,
  ) {}

  /** Vista calculada: duración, precios y cursos ordenados. */
  private viewOf(path: LearningPath): LearningPath {
    const courses = [...path.courses].sort((a, b) => a.sortOrder - b.sortOrder);
    const pricing = pathPricingOf(courses, path.discountPercent);
    return {
      ...path,
      courses,
      durationHours: durationHoursOf(path, courses),
      totalCoursesPrice: pricing.totalCoursesPrice,
      price: pricing.price,
    };
  }

  async list(includeUnpublished = false): Promise<LearningPath[]> {
    return this.paths
      .filter((path) => includeUnpublished || path.isPublished)
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map((path) => this.viewOf(path));
  }

  async findBySlug(slug: string): Promise<LearningPath | null> {
    const path = this.paths.find(
      (candidate) => candidate.slug === slug && candidate.isPublished,
    );
    return path ? this.viewOf(path) : null;
  }

  async findById(id: string): Promise<LearningPath | null> {
    const path = this.paths.find((candidate) => candidate.id === id);
    return path ? this.viewOf(path) : null;
  }

  async create(input: NewPathInput): Promise<LearningPath> {
    const now = new Date().toISOString();
    const path: LearningPath = {
      id: randomUUID(),
      slug: input.slug,
      title: input.title,
      description: input.description,
      coverUrl: input.coverUrl,
      modality: input.modality,
      durationHours: input.durationHours ?? 0,
      accessMonths: input.accessMonths,
      discountPercent: input.discountPercent,
      totalCoursesPrice: 0,
      price: 0,
      sortOrder: input.sortOrder,
      isPublished: input.isPublished,
      createdAt: now,
      updatedAt: now,
      courses: [],
    };
    this.paths.push(path);
    return this.viewOf(path);
  }

  async update(id: string, input: NewPathInput): Promise<LearningPath | null> {
    const index = this.paths.findIndex((path) => path.id === id);
    if (index < 0) return null;

    const previous = this.paths[index]!;
    const updated: LearningPath = {
      ...previous,
      slug: input.slug,
      title: input.title,
      description: input.description,
      coverUrl: input.coverUrl,
      modality: input.modality,
      durationHours: input.durationHours ?? 0,
      accessMonths: input.accessMonths,
      discountPercent: input.discountPercent,
      sortOrder: input.sortOrder,
      isPublished: input.isPublished,
      updatedAt: new Date().toISOString(),
    };
    this.paths[index] = updated;
    return this.viewOf(updated);
  }

  async remove(id: string): Promise<boolean> {
    const index = this.paths.findIndex((path) => path.id === id);
    if (index < 0) return false;
    this.paths.splice(index, 1);
    return true;
  }

  async setCourses(pathId: string, entries: PathCourseEntry[]): Promise<void> {
    const path = this.paths.find((candidate) => candidate.id === pathId);
    if (!path) {
      throw new Error(`Ruta no encontrada: ${pathId}`);
    }

    const courses: PathCourse[] = [];
    for (const entry of entries) {
      const course = await this.catalog.findById(entry.courseId);
      if (!course) {
        throw new Error(`Curso no encontrado: ${entry.courseId}`);
      }
      courses.push({
        courseId: course.id,
        title: course.title,
        imageUrl: course.imageUrl,
        // Precio que se paga: con oferta aplicada si la hay (es la
        // referencia de la que parte el total de la ruta).
        price: effectivePriceOf(course),
        hours: course.totalHours,
        level: entry.level,
        sortOrder: entry.sortOrder,
      });
    }
    path.courses = courses;
    path.updatedAt = new Date().toISOString();
  }
}
