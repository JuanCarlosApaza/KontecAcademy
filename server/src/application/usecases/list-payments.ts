import type { AdminRepository, PaymentRecord } from '../../domain/admin.js';

/** Caso de uso: listar pagos del panel filtrados por estado. */
export class ListPayments {
  constructor(private readonly admin: Pick<AdminRepository, 'listPayments'>) {}

  execute(status: string): Promise<PaymentRecord[]> {
    return this.admin.listPayments(status);
  }
}
