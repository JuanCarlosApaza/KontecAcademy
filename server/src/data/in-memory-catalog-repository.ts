import { randomUUID } from 'node:crypto';
import type {
  CatalogRepository,
  Category,
  Course,
  NewCourseInput,
} from '../domain/catalog.js';

/**
 * 🔌 DATOS — implementación en memoria (desarrollo sin BD / tests).
 * Sembrada con la forma real de Supabase para poder probar las rutas.
 */
export class InMemoryCatalogRepository implements CatalogRepository {
  private readonly categories: Category[] = [
    {
      id: 'a8a5e7cb-3308-4f22-9e77-e68bac666372',
      name: 'Estructuras y Concreto',
      slug: 'estructuras-y-concreto',
    },
    {
      id: '24999c81-5dfd-4265-a8b8-237e077f0d2a',
      name: 'Geotecnia y Vías',
      slug: 'geotecnia-y-vias',
    },
  ];

  private readonly courses: Course[] = [
    {
      id: 'a0000000-0000-0000-0000-000000000001',
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      description:
        'Aprende a calcular y diseñar elementos estructurales sismorresistentes bajo normas internacionales.',
      imageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18f154d',
      categoryId: 'a8a5e7cb-3308-4f22-9e77-e68bac666372',
      category: this.categories[0] ?? null,
      teacherId: null,
      modality: 'asynchronous',
      totalHours: 40,
      totalWeeks: 8,
      startDate: null,
      price: 150,
      compareAtPrice: 200,
      status: 'active',
      professorBio:
        'Ing. estructural con 12 años de experiencia en diseño sismorresistente y coordinación BIM.',
      teachingMethod:
        'Clases grabadas de alta calidad\nCasos reales de proyectos\nForo de consultas con el docente',
      targetAudience:
        'Ingenieros civiles\nArquitectos\nEstudiantes de últimos ciclos\nProyectistas',
      certificateInfo:
        'Certificado digital con código QR\nAcreditación en LinkedIn\nRegistro verificable en Kontec Academy',
      careerOpportunities:
        'Diseñador estructural\nCoordinador BIM\nSupervisor de obra\nConsultor en sismorresistencia',
      createdAt: '2026-10-21T12:59:11.701813+00:00',
      updatedAt: '2026-10-21T13:46:13.517059+00:00',
    },
  ];

  async findAllCategories(): Promise<Category[]> {
    return [...this.categories];
  }

  async findAllCourses(filter?: { status?: string; limit?: number }): Promise<Course[]> {
    let courses = [...this.courses];
    if (filter?.status) {
      courses = courses.filter((course) => course.status === filter.status);
    }
    if (filter?.limit !== undefined) {
      courses = courses.slice(0, filter.limit);
    }
    return courses;
  }

  async findById(id: string): Promise<Course | null> {
    return this.courses.find((course) => course.id === id) ?? null;
  }

  async createCourse(input: NewCourseInput): Promise<Course> {
    const now = new Date().toISOString();
    const course: Course = {
      id: randomUUID(),
      title: input.title,
      description: input.description,
      imageUrl: input.imageUrl,
      categoryId: input.categoryId,
      category: this.categories.find((c) => c.id === input.categoryId) ?? null,
      teacherId: null,
      modality: input.modality,
      totalHours: input.totalHours,
      totalWeeks: input.totalWeeks,
      startDate: null,
      price: input.price,
      compareAtPrice: input.compareAtPrice,
      status: input.status,
      professorBio: input.professorBio,
      teachingMethod: input.teachingMethod,
      targetAudience: input.targetAudience,
      certificateInfo: input.certificateInfo,
      careerOpportunities: input.careerOpportunities,
      createdAt: now,
      updatedAt: now,
    };
    // Los más recientes primero (igual que en Supabase).
    this.courses.unshift(course);
    return course;
  }

  async updateCourse(id: string, input: NewCourseInput): Promise<Course | null> {
    const index = this.courses.findIndex((course) => course.id === id);
    if (index < 0) return null;

    const previous = this.courses[index] as Course;
    const category =
      this.categories.find((c) => c.id === input.categoryId) ?? null;
    const updated: Course = {
      ...previous,
      title: input.title,
      description: input.description,
      imageUrl: input.imageUrl,
      categoryId: input.categoryId,
      category,
      modality: input.modality,
      totalHours: input.totalHours,
      totalWeeks: input.totalWeeks,
      price: input.price,
      compareAtPrice: input.compareAtPrice,
      status: input.status,
      professorBio: input.professorBio,
      teachingMethod: input.teachingMethod,
      targetAudience: input.targetAudience,
      certificateInfo: input.certificateInfo,
      careerOpportunities: input.careerOpportunities,
      updatedAt: new Date().toISOString(),
    };
    this.courses[index] = updated;
    return updated;
  }
}
