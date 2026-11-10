import type { AdminRepository, UserRecord } from '../../domain/admin.js';
import type { UpdateAdminUserDTO } from '../dtos/user_dto.js';

/**
 * Caso de uso: editar un usuario del panel. Null si no existe.
 * isActive false = borrado lógico: la cuenta y sus datos se conservan.
 */
export class UpdateAdminUser {
  constructor(
    private readonly admin: Pick<AdminRepository, 'updateUser'>,
  ) {}

  execute(dto: UpdateAdminUserDTO): Promise<UserRecord | null> {
    return this.admin.updateUser({
      id: dto.id,
      fullName: dto.fullName,
      phone: dto.phone,
      role: dto.role,
      isActive: dto.isActive,
    });
  }
}
