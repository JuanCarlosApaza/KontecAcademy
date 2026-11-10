/**
 * 🧠 DOMINIO — catálogo de cursos y categorías.
 * Sin dependencias de Express, ni base de datos, ni frameworks.
 * (Equivalente a lib/features/landing/domain/... del front)
 */
export interface Category {
  id: string;
  name: string;
  slug: string;
}

/** Modalidad de un curso (código crudo de la BD; la etiqueta vive en la UI). */
export type CourseModality = 'asynchronous' | 'live';

/** Estado de publicación de un curso (código crudo de la BD). */
export type CourseStatus = 'draft' | 'upcoming' | 'active' | 'inactive';

export interface Course {
  id: string;
  title: string;
  description: string | null;
  imageUrl: string | null;
  categoryId: string | null;
  /** Categoría embebida (join con categories) para pintar la UI sin N+1. */
  category: Category | null;
  teacherId: string | null;
  modality: CourseModality;
  totalHours: number;
  /** Duración en semanas (null = no definida). */
  totalWeeks: number | null;
  startDate: string | null;
  price: number;
  compareAtPrice: number | null;
  status: CourseStatus;
  /** Secciones de la plantilla de landing (null = aún sin contenido). */
  professorBio: string | null;
  teachingMethod: string | null;
  /** Una opción por línea (la UI la pinta como viñetas). */
  targetAudience: string | null;
  certificateInfo: string | null;
  /** Una opción por línea (la UI la pinta como lista). */
  careerOpportunities: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Filtros opcionales de listado (query string). */
export interface CourseFilter {
  status?: string;
  limit?: number;
}

/** Datos para crear un curso (formulario del panel admin). */
export interface NewCourseInput {
  title: string;
  description: string | null;
  imageUrl: string | null;
  categoryId: string | null;
  modality: CourseModality;
  totalHours: number;
  totalWeeks: number | null;
  price: number;
  compareAtPrice: number | null;
  status: CourseStatus;
  professorBio: string | null;
  teachingMethod: string | null;
  targetAudience: string | null;
  certificateInfo: string | null;
  careerOpportunities: string | null;
}

/**
 * Contrato de acceso al catálogo. Los route handlers solo ven esta interfaz:
 * cambiar de Supabase a otra BD obliga a implementar esta interfaz, no a tocar rutas.
 */
export interface CatalogRepository {
  findAllCategories(): Promise<Category[]>;
  findAllCourses(filter?: CourseFilter): Promise<Course[]>;
  /** Curso por id; null si no existe. */
  findById(id: string): Promise<Course | null>;
  createCourse(input: NewCourseInput): Promise<Course>;
  /** Actualiza un curso existente; null si el id no existe. */
  updateCourse(id: string, input: NewCourseInput): Promise<Course | null>;
}

/**
 * Regla de precios — MISMA que el front (course_display.dart).
 *
 * `price` = precio GENERAL · `compareAtPrice` = precio de OFERTA.
 * Hay oferta cuando la oferta existe, es > 0 y es MENOR que el general
 * (un descuento real). Si vienen invertidos son datos inconsistentes y
 * se ignora: no se cobra/pinta un "descuento" que no existe.
 */
export function offerPriceOf(
  course: Pick<Course, 'price' | 'compareAtPrice'>,
): number | null {
  const offer = course.compareAtPrice;
  if (offer === null || offer <= 0 || offer >= course.price) return null;
  return offer;
}

/** Precio que paga el cliente: la oferta si la hay, si no el general. */
export function effectivePriceOf(
  course: Pick<Course, 'price' | 'compareAtPrice'>,
): number {
  return offerPriceOf(course) ?? course.price;
}

/**
 * Regla de negocio: slug de una categoría a partir de su nombre
 * ("Geotecnia y Vías" → "geotecnia-y-vías"). La usan los casos de uso
 * CreateCategory/UpdateCategory cuando el slug no viene indicado.
 */
export function slugFromName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, '-');
}
