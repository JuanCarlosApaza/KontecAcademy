import type {
  DeleteRoleResult,
  RolesRepository,
} from '../../domain/roles.js';

/**
 * Caso de uso: borra un rol (DELETE /admin/roles/:id).
 * El repositorio decide el resultado (no existe / en uso / base);
 * el adaptador HTTP lo traduce a 404 / 409 / 400 / 200.
 */
export class DeleteRole {
  constructor(
    private readonly roles: Pick<RolesRepository, 'deleteRole'>,
  ) {}

  execute(roleId: string): Promise<DeleteRoleResult> {
    return this.roles.deleteRole(roleId);
  }
}
