import type { RolesRepository } from '../../domain/roles.js';
import { ValidationError } from '../errors.js';

/**
 * Caso de uso: reemplaza los permisos de un rol (PUT /admin/roles/:id).
 * Devuelve false si el rol no existe (el adaptador responde 404).
 *
 * Reglas: el rol `admin` es inmutable (así nadie —ni un admin por
 * error— se queda sin poder entrar al panel) y todo código debe
 * pertenecer al catálogo `permissions`.
 */
export class SaveRolePermissions {
  constructor(
    private readonly roles: Pick<RolesRepository, 'listMatrix' | 'setRolePermissions'>,
  ) {}

  async execute(roleId: string, codes: string[]): Promise<boolean> {
    const matrix = await this.roles.listMatrix();

    const role = matrix.roles.find((candidate) => candidate.id === roleId);
    if (!role) return false;

    if (role.name === 'admin') {
      throw new ValidationError(
        'El rol admin tiene todos los permisos y no se puede modificar.',
      );
    }

    const known = new Set(
      matrix.permissions.map((permission) => permission.code),
    );
    const unknown = codes.filter((code) => !known.has(code));
    if (unknown.length > 0) {
      throw new ValidationError(
        `Código(s) de permiso desconocido(s): ${unknown.join(', ')}`,
      );
    }

    return this.roles.setRolePermissions(roleId, codes);
  }
}
