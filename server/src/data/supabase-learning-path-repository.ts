import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { effectivePriceOf } from '../domain/catalog.js';
import {
  durationHoursOf,
  pathPricingOf,
  type LearningPath,
  type LearningPathRepository,
  type NewPathInput,
  type PathCourse,
  type PathCourseEntry,
  type PathModality,
} from '../domain/learning-path.js';
import { asRows } from './postgrest-rows.js';

/** Fila cruda de `path_courses` con el curso embebido. */
interface PathCourseRow {
  course_id: string;
  sort_order: number;
  level: string | null;
  courses: {
    id: string;
    title: string;
    image_url: string | null;
    price: number;
    compare_at_price: number | null;
    total_hours: number;
  } | null;
}

/** Fila cruda de `learning_paths` con sus cursos embebidos. */
interface LearningPathRow {
  id: string;
  slug: string;
  title: string;
  description: string;
  cover_url: string | null;
  modality: string;
  duration_hours: number | null;
  access_months: number;
  discount_percent: number;
  sort_order: number;
  is_published: boolean;
  created_at: string;
  updated_at: string;
  path_courses: PathCourseRow[] | PathCourseRow | null;
}

/** Select con la ruta y sus cursos (join por FK), sin N+1. */
const PATH_SELECT =
  '*, path_courses(course_id, sort_order, level, courses(id, title, image_url, price, compare_at_price, total_hours))';

/** Mapper: filas embebidas → cursos ordenados. Fila huérfana sin curso → fuera. */
function toPathCourses(embedded: LearningPathRow['path_courses']): PathCourse[] {
  const rows = Array.isArray(embedded)
    ? embedded
    : embedded
      ? [embedded]
      : [];

  return rows
    .filter((row) => row.courses !== null)
    .map((row) => ({
      courseId: row.course_id,
      title: row.courses!.title,
      imageUrl: row.courses!.image_url,
      // Lo que se PAGA por el curso: oferta aplicada si la hay
      // (es la referencia para el total de la ruta).
      price: effectivePriceOf({
        price: row.courses!.price,
        compareAtPrice: row.courses!.compare_at_price,
      }),
      hours: row.courses!.total_hours,
      level: row.level,
      sortOrder: row.sort_order,
    }))
    .sort((a, b) => a.sortOrder - b.sortOrder);
}

/** Mapper: fila (snake_case) → entidad LearningPath. */
function toLearningPath(row: LearningPathRow): LearningPath {
  const courses = toPathCourses(row.path_courses);
  const pricing = pathPricingOf(courses, row.discount_percent ?? 0);
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    description: row.description,
    coverUrl: row.cover_url,
    modality: row.modality as PathModality,
    durationHours: durationHoursOf(
      { durationHours: row.duration_hours ?? 0 },
      courses,
    ),
    accessMonths: row.access_months,
    discountPercent: row.discount_percent ?? 0,
    totalCoursesPrice: pricing.totalCoursesPrice,
    price: pricing.price,
    sortOrder: row.sort_order,
    isPublished: row.is_published,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    courses,
  };
}

function toInputColumns(input: NewPathInput) {
  return {
    slug: input.slug,
    title: input.title,
    description: input.description,
    cover_url: input.coverUrl,
    modality: input.modality,
    duration_hours: input.durationHours,
    access_months: input.accessMonths,
    discount_percent: input.discountPercent,
    sort_order: input.sortOrder,
    is_published: input.isPublished,
    updated_at: new Date().toISOString(),
  };
}

/**
 * 🔌 DATOS — rutas de entrenamiento con Supabase (Postgres).
 * Usa el cliente oficial @supabase/supabase-js vía la Service Role Key.
 * Es el ÚNICO lugar que conoce el esquema snake_case de estas tablas.
 */
export class SupabaseLearningPathRepository implements LearningPathRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async list(includeUnpublished = false): Promise<LearningPath[]> {
    let query = this.client
      .from('learning_paths')
      .select(PATH_SELECT)
      .order('sort_order', { ascending: true })
      .order('sort_order', { referencedTable: 'path_courses' });

    if (!includeUnpublished) {
      query = query.eq('is_published', true);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Supabase listPaths: ${error.message}`);
    }
    return asRows<LearningPathRow>(data).map(toLearningPath);
  }

  async findBySlug(slug: string): Promise<LearningPath | null> {
    const { data, error } = await this.client
      .from('learning_paths')
      .select(PATH_SELECT)
      .eq('slug', slug)
      .eq('is_published', true)
      .order('sort_order', { referencedTable: 'path_courses' })
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findPathBySlug: ${error.message}`);
    }
    return data ? toLearningPath(data as LearningPathRow) : null;
  }

  async findById(id: string): Promise<LearningPath | null> {
    const { data, error } = await this.client
      .from('learning_paths')
      .select(PATH_SELECT)
      .eq('id', id)
      .order('sort_order', { referencedTable: 'path_courses' })
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findPathById: ${error.message}`);
    }
    return data ? toLearningPath(data as LearningPathRow) : null;
  }

  async create(input: NewPathInput): Promise<LearningPath> {
    const { data, error } = await this.client
      .from('learning_paths')
      .insert({
        ...toInputColumns(input),
        created_at: new Date().toISOString(),
      })
      .select(PATH_SELECT)
      .single();

    if (error) {
      throw new Error(`Supabase createPath: ${error.message}`);
    }
    return toLearningPath(data as LearningPathRow);
  }

  async update(id: string, input: NewPathInput): Promise<LearningPath | null> {
    const { data, error } = await this.client
      .from('learning_paths')
      .update(toInputColumns(input))
      .eq('id', id)
      .select(PATH_SELECT)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updatePath: ${error.message}`);
    }
    return data ? toLearningPath(data as LearningPathRow) : null;
  }

  async remove(id: string): Promise<boolean> {
    const { data, error } = await this.client
      .from('learning_paths')
      .delete()
      .eq('id', id)
      .select('id');

    if (error) {
      throw new Error(`Supabase deletePath: ${error.message}`);
    }
    return (data ?? []).length > 0;
  }

  async setCourses(pathId: string, entries: PathCourseEntry[]): Promise<void> {
    const { error: clearError } = await this.client
      .from('path_courses')
      .delete()
      .eq('path_id', pathId);

    if (clearError) {
      throw new Error(`Supabase setCourses: ${clearError.message}`);
    }
    if (entries.length === 0) return;

    const { error } = await this.client.from('path_courses').insert(
      entries.map((entry) => ({
        path_id: pathId,
        course_id: entry.courseId,
        sort_order: entry.sortOrder,
        level: entry.level,
      })),
    );

    if (error) {
      throw new Error(`Supabase setCourses: ${error.message}`);
    }
  }
}
