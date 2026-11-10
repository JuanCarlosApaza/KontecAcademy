import type { AdminCurriculum, AdminRepository } from '../../domain/admin.js';

/** Caso de uso: temario completo de un curso para el panel. */
export class GetAdminCurriculum {
  constructor(
    private readonly admin: Pick<AdminRepository, 'getCourseCurriculum'>,
  ) {}

  /** null = el curso no existe (la ruta responde 404). */
  execute(courseId: string): Promise<AdminCurriculum | null> {
    return this.admin.getCourseCurriculum(courseId);
  }
}
