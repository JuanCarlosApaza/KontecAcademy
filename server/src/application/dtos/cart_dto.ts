import { ValidationError } from '../errors.js';
import { asRecord, optionalText } from './parse.js';

/** Límite de ítems por carrito (por seguridad del body). */
const MAX_CART_ITEMS = 25;

/** Item del carrito tal como llega del front (PUT /cart). */
export interface SaveCartDTOItem {
  courseId: string;
  /** 'course' (default) | 'path' | 'membership' (id = plan_id). */
  type: 'course' | 'path' | 'membership';
}

/** Payload de PUT /cart (reemplaza el carrito completo del usuario). */
export interface SaveCartDTO {
  items: SaveCartDTOItem[];
}

/**
 * Valida el body de PUT /cart. Lanza [ValidationError].
 * Solo valida la forma: la existencia de cursos/rutas en sus tablas
 * se verifica en el repositorio (requiere consultar la BD).
 */
export function parseSaveCartDTO(body: unknown): SaveCartDTO {
  const record = asRecord(body);

  if (!Array.isArray(record?.items)) {
    throw new ValidationError('El campo "items" debe ser un array');
  }
  if (record.items.length > MAX_CART_ITEMS) {
    throw new ValidationError(
      `El carrito admite máximo ${MAX_CART_ITEMS} elementos`,
    );
  }

  const items: SaveCartDTOItem[] = [];
  for (const raw of record.items) {
    const item = asRecord(raw);
    const courseId = optionalText(item?.courseId);
    const type = optionalText(item?.type) ?? 'course';

    if (!courseId) {
      throw new ValidationError('Cada item necesita un "courseId" no vacío');
    }
    if (type !== 'course' && type !== 'path' && type !== 'membership') {
      throw new ValidationError(
        'El campo "type" debe ser course | path | membership',
      );
    }
    items.push({ courseId, type });
  }

  return { items };
}
