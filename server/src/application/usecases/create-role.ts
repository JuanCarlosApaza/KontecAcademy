import type { RoleRecord, RolesRepository } from '../../domain/roles.js';
import { ValidationError } from '../errors.js';
import type { CreateRoleDTO } from '../dtos/role_dto.js';

/** Caso de uso: crea un rol nuevo en el panel (POST /admin/roles). */
export class CreateRole {
  constructor(
    private readonly roles: Pick<RolesRepository, 'createRole'>,
  ) {}

  async execute(dto: CreateRoleDTO): Promise<RoleRecord> {
    const role = await this.roles.createRole(dto.name, dto.description);
    if (!role) {
      throw new ValidationError(`El rol "${dto.name}" ya existe`);
    }
    return role;
  }
}
