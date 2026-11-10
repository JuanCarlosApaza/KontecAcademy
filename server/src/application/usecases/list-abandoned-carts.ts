import type {
  AbandonedCartItem,
  AdminRepository,
} from '../../domain/admin.js';

/** Caso de uso: listar carritos abandonados (solo carritos no vacíos). */
export class ListAbandonedCarts {
  constructor(
    private readonly admin: Pick<AdminRepository, 'listAbandonedCarts'>,
  ) {}

  execute(): Promise<AbandonedCartItem[]> {
    return this.admin.listAbandonedCarts();
  }
}
