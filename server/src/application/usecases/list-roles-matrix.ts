import type { RolesMatrix, RolesRepository } from '../../domain/roles.js';

/**
 * Caso de uso: matriz rol × permiso para la pantalla /admin/roles.
 *
 * El rol `admin` sale SIEMPRE con todos los códigos: es el mismo bypass
 * que aplica `getPermissions()` en las rutas, calculado aquí para que la
 * UI lo muestre bloqueado en `true` sin depender del seed de grants.
 */
export class ListRolesMatrix {
  constructor(
    private readonly roles: Pick<RolesRepository, 'listMatrix'>,
  ) {}

  async execute(): Promise<RolesMatrix> {
    const matrix = await this.roles.listMatrix();
    const all = matrix.permissions.map((permission) => permission.code);

    if (matrix.grants.admin) {
      matrix.grants.admin = all;
    }

    return matrix;
  }
}
