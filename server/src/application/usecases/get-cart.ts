import type { CartEntry, CartRepository } from '../../domain/cart.js';
import type { AuthenticatedUser } from '../../domain/checkout.js';

/** Caso de uso: carrito del usuario de la sesión (GET /cart). */
export class GetCart {
  constructor(private readonly cart: Pick<CartRepository, 'list'>) {}

  execute(user: AuthenticatedUser): Promise<CartEntry[]> {
    return this.cart.list(user.id);
  }
}
