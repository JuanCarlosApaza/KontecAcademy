import type { AdminRepository } from '../../domain/admin.js';

/** Caso de uso: borrar un módulo y todo su contenido (cascada). */
export class DeleteModule {
  constructor(
    private readonly admin: Pick<AdminRepository, 'deleteModule'>,
  ) {}

  /** false = el módulo no existe (la ruta responde 404). */
  execute(moduleId: string): Promise<boolean> {
    return this.admin.deleteModule(moduleId);
  }
}
