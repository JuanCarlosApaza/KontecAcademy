import type { AdminRepository, UserRecord } from '../../domain/admin.js';

/** Caso de uso: listar todos los usuarios + sus roles (panel). */
export class ListAdminUsers {
  constructor(private readonly admin: Pick<AdminRepository, 'findUsers'>) {}

  execute(): Promise<UserRecord[]> {
    return this.admin.findUsers();
  }
}
