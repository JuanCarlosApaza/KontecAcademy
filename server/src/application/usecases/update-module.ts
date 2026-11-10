import type { AdminModule, AdminRepository } from '../../domain/admin.js';
import type { UpdateModuleDTO } from '../dtos/module_dto.js';

/** Caso de uso: editar título/posición de un módulo. */
export class UpdateModule {
  constructor(
    private readonly admin: Pick<AdminRepository, 'updateModule'>,
  ) {}

  /** null = el módulo no existe (la ruta responde 404). */
  execute(
    moduleId: string,
    dto: UpdateModuleDTO,
  ): Promise<AdminModule | null> {
    return this.admin.updateModule(moduleId, dto);
  }
}
