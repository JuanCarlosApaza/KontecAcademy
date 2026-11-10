import { ValidationError } from '../application/errors.js';
import type { CartEntry, CartItemType, CartRepository } from '../domain/cart.js';
import { effectivePriceOf, type CatalogRepository } from '../domain/catalog.js';
import type { LearningPathRepository } from '../domain/learning-path.js';
import type { MembershipRepository } from '../domain/membership.js';

/** Ítem crudo como lo guarda la "BD" en memoria: id + tipo + fecha. */
interface StoredCartItem {
  courseId: string;
  itemType: CartItemType;
  addedAt: string;
}

/**
 * 🔌 DATOS — carrito en memoria (tests y desarrollo sin Supabase).
 * Replica la persistencia real: solo guarda (courseId, itemType,
 * addedAt) y resuelve título/precio/modalidad/imagen contra el
 * catálogo o la ruta al leer.
 */
export class InMemoryCartRepository implements CartRepository {
  /** Carrito por usuario (PK en memoria: user_id + course_id). */
  private readonly carts = new Map<string, StoredCartItem[]>();

  constructor(
    private readonly catalog: CatalogRepository,
    private readonly paths?: Pick<
      LearningPathRepository,
      'findById'
    >,
    private readonly plans?: Pick<
      MembershipRepository,
      'planById'
    >,
  ) {}

  async list(userId: string): Promise<CartEntry[]> {
    const stored = this.storedItemsOf(userId);
    const entries: CartEntry[] = [];

    for (const item of stored) {
      if (item.itemType === 'membership') {
        const plan = await this.plans?.planById(item.courseId);
        // El plan ya no existe → no se muestra (join nulo).
        if (!plan) continue;

        entries.push({
          courseId: item.courseId,
          itemType: 'membership',
          title: plan.name,
          price: plan.price,
          modality: 'Membresía',
          imageUrl: null,
          addedAt: item.addedAt,
        });
        continue;
      }

      if (item.itemType === 'path') {
        const path = await this.paths?.findById(item.courseId);
        // La ruta ya no existe → no se muestra (join nulo).
        if (!path) continue;

        entries.push({
          courseId: item.courseId,
          itemType: 'path',
          title: path.title,
          // Precio del combo YA con la rebaja aplicada (lo calcula el
          // repositorio de rutas al leer).
          price: path.price,
          modality: path.modality,
          imageUrl: path.coverUrl,
          addedAt: item.addedAt,
        });
        continue;
      }

      // El curso ya no existe en el catálogo → no se muestra (join nulo).
      const course = await this.catalog.findById(item.courseId);
      if (!course) continue;

      entries.push({
        courseId: item.courseId,
        itemType: 'course',
        title: course.title,
        // Se cobra el precio de oferta si existe; si no, el general.
        price: effectivePriceOf(course),
        modality: course.modality,
        imageUrl: course.imageUrl,
        addedAt: item.addedAt,
      });
    }

    // Orden por addedAt asc (sort estable: conserva el orden de inserción
    // cuando dos ítems comparten fecha, igual que la BD con la PK).
    return entries.sort((a, b) => a.addedAt.localeCompare(b.addedAt));
  }

  async replace(
    userId: string,
    items: Array<{ id: string; type: CartItemType }>,
  ): Promise<number> {
    // Unicidad defensiva (la PK real de carts también lo garantiza).
    const unique = new Map<string, { id: string; type: CartItemType }>();
    for (const item of items) {
      unique.set(`${item.type}:${item.id}`, item);
    }
    const entries = [...unique.values()];

    // Valida existencia por tipo (cualquier status).
    for (const item of entries) {
      if (item.type === 'membership') {
        const plan = await this.plans?.planById(item.id);
        if (!plan) {
          throw new ValidationError(
            `Plan de membresía no encontrado: ${item.id}`,
          );
        }
        continue;
      }
      if (item.type === 'path') {
        const path = await this.paths?.findById(item.id);
        if (!path) throw new ValidationError(`Ruta no encontrada: ${item.id}`);
        continue;
      }
      const course = await this.catalog.findById(item.id);
      if (!course) {
        throw new ValidationError(`Curso no encontrado: ${item.id}`);
      }
    }

    // Reemplaza el carrito COMPLETO del usuario.
    const stored: StoredCartItem[] = entries.map((item) => ({
      courseId: item.id,
      itemType: item.type,
      addedAt: new Date().toISOString(),
    }));
    this.carts.set(userId, stored);

    return stored.length;
  }

  /** Ítems crudos del usuario (array vacío si no tiene carrito). */
  private storedItemsOf(userId: string): StoredCartItem[] {
    return this.carts.get(userId) ?? [];
  }
}
