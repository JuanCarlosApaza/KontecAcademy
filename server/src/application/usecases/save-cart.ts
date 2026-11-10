import type { CartRepository } from '../../domain/cart.js';
import type { AuthenticatedUser } from '../../domain/checkout.js';
import type { SaveCartDTO } from '../dtos/cart_dto.js';

/** Caso de uso: reemplazar el carrito completo del usuario (PUT /cart). */
export class SaveCart {
  constructor(private readonly cart: Pick<CartRepository, 'replace'>) {}

  async execute(
    user: AuthenticatedUser,
    dto: SaveCartDTO,
  ): Promise<{ count: number }> {
    const items = dto.items.map((item) => ({
      id: item.courseId,
      type: item.type,
    }));
    const count = await this.cart.replace(user.id, items);
    return { count };
  }
}
