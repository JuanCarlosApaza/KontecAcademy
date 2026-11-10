import type { AdminModule, AdminRepository } from '../../domain/admin.js';
import type { CreateModuleDTO } from '../dtos/module_dto.js';

/** Caso de uso: añadir un módulo al temario de un curso. */
export class CreateModule {
  constructor(
    private readonly admin: Pick<AdminRepository, 'createModule'>,
  ) {}

  execute(courseId: string, dto: CreateModuleDTO): Promise<AdminModule> {
    return this.admin.createModule(courseId, dto.title);
  }
}
