import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { ValidationError } from '../application/errors.js';
import type {
  CartEntry,
  CartItemInput,
  CartItemType,
  CartRepository,
} from '../domain/cart.js';
import { effectivePriceOf } from '../domain/catalog.js';
import { pathPricingOf } from '../domain/learning-path.js';
import { asRows } from './postgrest-rows.js';

/** Curso embebido en el join carts → courses (muchos-a-uno). */
interface EmbeddedCourse {
  title: string;
  price: number | string;
  compare_at_price: number | string | null;
  modality: string;
  image_url: string | null;
}

/** Curso embebido dentro de learning_paths (para el precio del combo). */
interface EmbeddedPathCourse {
  price: number | string;
  compare_at_price: number | string | null;
}

/** Fila de `carts` con el curso embebido. */
interface CartRow {
  course_id: string;
  item_type: string | null;
  added_at: string;
  courses: EmbeddedCourse | null;
}

/** Fila mínima para validar la existencia de ids. */
interface IdRow {
  id: string;
}

/** Ruta embebida con sus cursos (para resolver precio de combo). */
interface PathRow {
  id: string;
  title: string;
  modality: string;
  cover_url: string | null;
  discount_percent: number;
  path_courses: Array<{ courses: EmbeddedPathCourse | null }> | null;
}

const PATH_SELECT =
  'id, title, modality, cover_url, discount_percent, '
  + 'path_courses(courses(price, compare_at_price))';

/**
 * 🔌 DATOS — carrito de compras con Supabase (estilo WooCommerce).
 *
 * Persiste SOLO (user_id, course_id, item_type, added_at) en
 * `public.carts`; el título/precio/modalidad/imagen se derivan al
 * LEER (de `courses` o de `learning_paths` + `path_courses`), así el
 * precio mostrado es siempre el de la BD y nunca el del cliente.
 *
 * ⚠️ Requiere las migraciones004 (carts) y010 (item_type, sin FK).
 * Se usa con la Service Role Key (solo en el servidor) para saltar la RLS.
 */
export class SupabaseCartRepository implements CartRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async list(userId: string): Promise<CartEntry[]> {
    const { data, error } = await this.client
      .from('carts')
      .select(
        'course_id, item_type, added_at, courses ( title, price, compare_at_price, modality, image_url )',
      )
      .eq('user_id', userId)
      .order('added_at', { ascending: true });

    if (error) {
      throw new Error(`Supabase list (carts): ${error.message}`);
    }

    const rows = asRows<CartRow>(data);
    const idsOfType = (type: string) => [
      ...new Set(
        rows
          .filter((row) => (row.item_type ?? 'course') === type)
          .map((row) => row.course_id),
      ),
    ];

    // Precios de las rutas del carrito, resueltos en el servidor.
    const pathsById = new Map<string, { entry: Omit<CartEntry, 'courseId' | 'itemType' | 'addedAt'> }>();
    const pathIds = idsOfType('path');
    if (pathIds.length > 0) {
      const { data: pathData, error: pathError } = await this.client
        .from('learning_paths')
        .select(PATH_SELECT)
        .in('id', pathIds);

      if (pathError) {
        throw new Error(`Supabase list (paths): ${pathError.message}`);
      }

      for (const row of asRows<PathRow>(pathData)) {
        const courses = (row.path_courses ?? [])
          .map((entry) => entry.courses)
          .filter((course): course is EmbeddedPathCourse => course !== null)
          .map((course) => ({
            price: Number(course.price),
            compareAtPrice:
              course.compare_at_price === null
                ? null
                : Number(course.compare_at_price),
          }));

        // Precio del combo: suma de precios efectivos con la rebaja.
        const pricing = pathPricingOf(
          courses.map((course) => ({
            courseId: '',
            title: '',
            imageUrl: null,
            price: effectivePriceOf(course),
            hours: 0,
            level: null,
            sortOrder: 0,
          })),
          row.discount_percent ?? 0,
        );

        pathsById.set(row.id, {
          entry: {
            title: row.title,
            price: pricing.price,
            modality: row.modality,
            imageUrl: row.cover_url,
          },
        });
      }
    }

    // Precios de los planes de membresía, resueltos en el servidor.
    const plansById = new Map<string, { entry: Omit<CartEntry, 'courseId' | 'itemType' | 'addedAt'> }>();
    const planIds = idsOfType('membership');
    if (planIds.length > 0) {
      const { data: planData, error: planError } = await this.client
        .from('membership_plans')
        .select('id, name, price, months')
        .in('id', planIds);

      if (planError) {
        throw new Error(
          `Supabase list (membership_plans): ${planError.message}`,
        );
      }

      for (const row of asRows<{
        id: string;
        name: string;
        price: number | string;
        months: number;
      }>(planData)) {
        plansById.set(row.id, {
          entry: {
            title: row.name,
            price: Number(row.price),
            modality: 'Membresía',
            imageUrl: null,
          },
        });
      }
    }

    // Filas cuyo curso/ruta/plan ya no existe (join nulo) → fuera.
    return rows.flatMap((row): CartEntry[] => {
      const rawType = row.item_type ?? 'course';

      if (rawType === 'path') {
        const resolved = pathsById.get(row.course_id);
        if (!resolved) return [];
        return [
          {
            courseId: row.course_id,
            itemType: 'path' as const,
            ...resolved.entry,
            addedAt: row.added_at,
          },
        ];
      }

      if (rawType === 'membership') {
        const resolved = plansById.get(row.course_id);
        if (!resolved) return [];
        return [
          {
            courseId: row.course_id,
            itemType: 'membership' as const,
            ...resolved.entry,
            addedAt: row.added_at,
          },
        ];
      }

      const course = row.courses;
      if (course === null) return [];
      return [
        {
          courseId: row.course_id,
          itemType: 'course' as const,
          title: course.title,
          // Se cobra el precio de oferta si existe; si no, el general.
          price: effectivePriceOf({
            price: Number(course.price),
            compareAtPrice:
              course.compare_at_price === null
                ? null
                : Number(course.compare_at_price),
          }),
          modality: course.modality,
          imageUrl: course.image_url,
          addedAt: row.added_at,
        },
      ];
    });
  }

  async replace(userId: string, items: CartItemInput[]): Promise<number> {
    // Unicidad defensiva por (id, type) (la PK de la tabla garantiza id).
    const unique = new Map<string, CartItemInput>();
    for (const item of items) {
      unique.set(`${item.type}:${item.id}`, item);
    }
    const entries = [...unique.values()];

    const courseIds = entries
      .filter((item) => item.type === 'course')
      .map((item) => item.id);
    const pathIds = entries
      .filter((item) => item.type === 'path')
      .map((item) => item.id);
    const planIds = entries
      .filter((item) => item.type === 'membership')
      .map((item) => item.id);

    // 1. Valida existencia por tipo (cualquier status).
    await this.assertExist('courses', courseIds, 'Curso');
    await this.assertExist('learning_paths', pathIds, 'Ruta');
    await this.assertExist('membership_plans', planIds, 'Plan de membresía');

    // 2. Reemplaza el carrito COMPLETO: borra el anterior del usuario.
    const { error: deleteError } = await this.client
      .from('carts')
      .delete()
      .eq('user_id', userId);

    if (deleteError) {
      throw new Error(`Supabase replace (carts delete): ${deleteError.message}`);
    }

    // 3. Inserta los ítems nuevos (added_at lo pone el default de la BD).
    if (entries.length > 0) {
      const { error: insertError } = await this.client.from('carts').insert(
        entries.map((item) => ({
          user_id: userId,
          course_id: item.id,
          item_type: item.type,
        })),
      );

      if (insertError) {
        throw new Error(`Supabase replace (carts insert): ${insertError.message}`);
      }
    }

    return entries.length;
  }

  /** Valida que TODOS los ids existan en la tabla indicada. */
  private async assertExist(
    table: 'courses' | 'learning_paths' | 'membership_plans',
    ids: string[],
    label: string,
  ): Promise<void> {
    if (ids.length === 0) return;

    const { data, error } = await this.client
      .from(table)
      .select('id')
      .in('id', ids);

    if (error) {
      throw new Error(`Supabase replace (${table}): ${error.message}`);
    }

    const existing = new Set((data ?? []).map((row) => (row as IdRow).id));
    for (const id of ids) {
      if (!existing.has(id)) {
        throw new ValidationError(`${label} no encontrado: ${id}`);
      }
    }
  }
}
