import type { AdminLesson, AdminRepository } from '../../domain/admin.js';
import type { CreateLessonDTO } from '../dtos/lesson_dto.js';

/** Caso de uso: añadir una lección a un módulo. */
export class CreateLesson {
  constructor(
    private readonly admin: Pick<AdminRepository, 'createLesson'>,
  ) {}

  execute(moduleId: string, dto: CreateLessonDTO): Promise<AdminLesson> {
    return this.admin.createLesson(moduleId, dto);
  }
}
