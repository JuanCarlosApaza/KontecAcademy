import type {
  AdminRepository,
  CourseParticipant,
} from '../../domain/admin.js';
import type { CatalogRepository } from '../../domain/catalog.js';

/** Participantes de un curso con su título (respuesta del endpoint). */
export interface CourseParticipants {
  courseId: string;
  courseTitle: string;
  participants: CourseParticipant[];
}

/**
 * Caso de uso: participantes de un curso (inscripción + datos del
 * estudiante) para la sección "Participantes" del panel.
 */
export class ListCourseParticipants {
  constructor(
    private readonly admin: Pick<AdminRepository, 'listCourseParticipants'>,
    private readonly catalog: Pick<CatalogRepository, 'findById'>,
  ) {}

  /** null = el curso no existe (la ruta responde 404). */
  async execute(courseId: string): Promise<CourseParticipants | null> {
    const course = await this.catalog.findById(courseId);
    if (!course) return null;

    const participants = await this.admin.listCourseParticipants(courseId);
    return { courseId, courseTitle: course.title, participants };
  }
}
