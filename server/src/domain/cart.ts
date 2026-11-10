/**
 * 🧠 DOMINIO — carrito de compras persistido por usuario (estilo WooCommerce).
 * Solo se persisten (user_id, course_id, item_type, added_at); título,
 * precio, modalidad e imagen se derivan del catálogo (o de la ruta) al
 * LEER, para mostrar siempre el precio actual de la BD y nunca el que
 * envía el cliente.
 *
 * item_type: 'course' → id en public.courses · 'path' → id en
 * public.learning_paths (combo con su % de rebaja ya aplicado).
 */

export type CartItemType = 'course' | 'path' | 'membership';

/** Ítem del carrito ya resuelto contra el catálogo (GET /cart). */
export interface CartEntry {
  /** Id del curso O de la ruta según [itemType]. */
  courseId: string;
  itemType: CartItemType;
  title: string;
  /** Precio que se paga hoy (oferta del curso o ruta con descuento). */
  price: number;
  modality: string;
  imageUrl: string | null;
  /** ISO 8601 (UTC) en que el usuario agregó el ítem. */
  addedAt: string;
}

/** Ítem tal como lo guarda/reemplaza el cliente (PUT /cart). */
export interface CartItemInput {
  id: string;
  type: CartItemType;
}

/**
 * Contrato del carrito. Lo implementa Supabase (producción) y una
 * versión en memoria (tests / desarrollo sin credenciales).
 */
export interface CartRepository {
  /** Carrito del usuario con el catálogo resuelto (orden addedAt asc). */
  list(userId: string): Promise<CartEntry[]>;
  /** Reemplaza el carrito completo; devuelve cuántos ítems quedaron. */
  replace(userId: string, items: CartItemInput[]): Promise<number>;
}
