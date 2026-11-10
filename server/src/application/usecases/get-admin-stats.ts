import type { AdminRepository, AdminStats } from '../../domain/admin.js';

/** Caso de uso: KPIs del dashboard administrativo. */
export class GetAdminStats {
  constructor(private readonly admin: Pick<AdminRepository, 'getStats'>) {}

  execute(): Promise<AdminStats> {
    return this.admin.getStats();
  }
}
