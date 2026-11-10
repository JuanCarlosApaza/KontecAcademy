import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type {
  CatalogRepository,
  Category,
  Course,
  CourseFilter,
  CourseModality,
  CourseStatus,
  NewCourseInput,
} from '../domain/catalog.js';
import { asRows } from './postgrest-rows.js';

/** Fila cruda de la tabla `courses` con la categoría embebida. */
interface CourseRow {
  id: string;
  title: string;
  description: string | null;
  image_url: string | null;
  category_id: string | null;
  teacher_id: string | null;
  modality: string;
  total_hours: number;
  total_weeks: number | null;
  start_date: string | null;
  price: number;
  compare_at_price: number | null;
  status: string;
  professor_bio: string | null;
  teaching_method: string | null;
  target_audience: string | null;
  certificate_info: string | null;
  career_opportunities: string | null;
  created_at: string;
  updated_at: string;
  categories: { id: string; name: string; slug: string } | null;
}

/** Mapper: fila (snake_case, valores crudos de la BD) → entidad Course. */
function toCourse(row: CourseRow): Course {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    imageUrl: row.image_url,
    categoryId: row.category_id,
    category: row.categories,
    teacherId: row.teacher_id,
    // La BD guarda los códigos crudos; el cast tolera filas heredadas.
    modality: row.modality as CourseModality,
    totalHours: row.total_hours,
    totalWeeks: row.total_weeks,
    startDate: row.start_date,
    price: row.price,
    compareAtPrice: row.compare_at_price,
    status: row.status as CourseStatus,
    professorBio: row.professor_bio,
    teachingMethod: row.teaching_method,
    targetAudience: row.target_audience,
    certificateInfo: row.certificate_info,
    careerOpportunities: row.career_opportunities,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

/**
 * 🔌 DATOS — implementación del catálogo con Supabase (Postgres).
 * Usa el cliente oficial @supabase/supabase-js vía la Service Role Key.
 * Es el ÚNICO lugar que conoce el esquema snake_case de la BD.
 */
export class SupabaseCatalogRepository implements CatalogRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async findAllCategories(): Promise<Category[]> {
    const { data, error } = await this.client
      .from('categories')
      .select('id, name, slug')
      .order('name', { ascending: true });

    if (error) {
      throw new Error(`Supabase findAllCategories: ${error.message}`);
    }
    return data ?? [];
  }

  async findAllCourses(filter?: CourseFilter): Promise<Course[]> {
    let query = this.client
      .from('courses')
      .select('*, categories(id, name, slug)')
      .order('created_at', { ascending: false });

    if (filter?.status) {
      query = query.eq('status', filter.status);
    }
    if (filter?.limit !== undefined) {
      query = query.limit(filter.limit);
    }

    const { data, error } = await query;
    if (error) {
      throw new Error(`Supabase findAllCourses: ${error.message}`);
    }
    return asRows<CourseRow>(data).map(toCourse);
  }

  async findById(id: string): Promise<Course | null> {
    const { data, error } = await this.client
      .from('courses')
      .select('*, categories(id, name, slug)')
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findById: ${error.message}`);
    }
    return data ? toCourse(data as CourseRow) : null;
  }

  async createCourse(input: NewCourseInput): Promise<Course> {
    const { data, error } = await this.client
      .from('courses')
      .insert({
        title: input.title,
        description: input.description,
        image_url: input.imageUrl,
        category_id: input.categoryId,
        modality: input.modality,
        total_hours: input.totalHours,
        total_weeks: input.totalWeeks,
        price: input.price,
        compare_at_price: input.compareAtPrice,
        status: input.status,
        professor_bio: input.professorBio,
        teaching_method: input.teachingMethod,
        target_audience: input.targetAudience,
        certificate_info: input.certificateInfo,
        career_opportunities: input.careerOpportunities,
      })
      // Devuelve la fila insertada con la categoría embebida (sin N+1).
      .select('*, categories(id, name, slug)')
      .single();

    if (error) {
      throw new Error(`Supabase createCourse: ${error.message}`);
    }
    return toCourse(data as CourseRow);
  }

  async updateCourse(id: string, input: NewCourseInput): Promise<Course | null> {
    const { data, error } = await this.client
      .from('courses')
      .update({
        title: input.title,
        description: input.description,
        image_url: input.imageUrl,
        category_id: input.categoryId,
        modality: input.modality,
        total_hours: input.totalHours,
        total_weeks: input.totalWeeks,
        price: input.price,
        compare_at_price: input.compareAtPrice,
        status: input.status,
        professor_bio: input.professorBio,
        teaching_method: input.teachingMethod,
        target_audience: input.targetAudience,
        certificate_info: input.certificateInfo,
        career_opportunities: input.careerOpportunities,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select('*, categories(id, name, slug)')
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase updateCourse: ${error.message}`);
    }
    return data ? toCourse(data as CourseRow) : null;
  }
}
