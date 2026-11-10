import type { AdminRepository } from '../../domain/admin.js';
import type { CreateAdminUserDTO } from '../dtos/user_dto.js';

/** Caso de uso: crear un usuario (auth + perfil + rol). */
export class CreateAdminUser {
  constructor(
    private readonly admin: Pick<AdminRepository, 'createUser'>,
  ) {}

  execute(dto: CreateAdminUserDTO): Promise<{ id: string; email: string }> {
    return this.admin.createUser({
      email: dto.email,
      password: dto.password,
      fullName: dto.fullName,
      phone: dto.phone,
      role: dto.role,
    });
  }
}
