/**
 * 🧠 DOMINIO — rutas de entrenamiento (learning paths).
 * Una ruta agrupa cursos ORDENADOS con un nivel por curso y tiene
 * precio propio: total = suma de los precios EFECTIVOS de sus cursos
 * (con oferta aplicada) y un % de rebaja por adquirir la ruta.
 * (Equivalente a lib/features/landing/domain/... del front)
 */
import { slugFromName } from './catalog.js';

/** Modalidad con los mismos códigos crudos que Course ('domain/catalog.ts'). */
export type PathModality = 'asynchronous' | 'live';

/** Niveles admitidos por curso dentro de una ruta. */
export const PATH_LEVELS = ['Introductorio', 'Intermedio', 'Avanzado'] as const;
export type PathLevel = (typeof PATH_LEVELS)[number];

/** Curso dentro de una ruta (datos suficientes para pintar la tarjeta). */
export interface PathCourse {
  courseId: string;
  title: string;
  imageUrl: string | null;
  /** Precio que se PAGA por el curso (oferta aplicada si la hay). */
  price: number;
  /** Horas del curso (para derivar la duración total de la ruta). */
  hours: number;
  level: string | null;
  sortOrder: number;
}

export interface LearningPath {
  id: string;
  slug: string;
  title: string;
  description: string;
  coverUrl: string | null;
  modality: PathModality;
  /** Horas totales: el valor guardado o, si es null, la suma de cursos. */
  durationHours: number;
  accessMonths: number;
  /** % de rebaja (0-100) que aplica la ruta sobre su total. */
  discountPercent: number;
  /**
   * Total de referencia: suma de los precios EFECTIVOS de los cursos
   * (ya con sus ofertas individuales). Es lo que se muestra tachado.
   */
  totalCoursesPrice: number;
  /** Precio final de la ruta: total con el % de rebaja aplicado. */
  price: number;
  sortOrder: number;
  isPublished: boolean;
  createdAt: string;
  updatedAt: string;
  /** Cursos ordenados por sortOrder. */
  courses: PathCourse[];
}

/** Datos para crear/actualizar una ruta (formulario del panel admin). */
export interface NewPathInput {
  slug: string;
  title: string;
  description: string;
  coverUrl: string | null;
  modality: PathModality;
  durationHours: number | null;
  accessMonths: number;
  discountPercent: number;
  sortOrder: number;
  isPublished: boolean;
}

/** Entrada del selector de cursos del panel admin. */
export interface PathCourseEntry {
  courseId: string;
  level: string | null;
  sortOrder: number;
}

/**
 * Contrato de acceso a las rutas. Los route handlers solo ven esta
 * interfaz: cambiar de Supabase a otra BD obliga a implementarla, no
 * a tocar rutas.
 */
export interface LearningPathRepository {
  /** Listado; includeUnpublished = true solo lo usa el panel admin. */
  list(includeUnpublished?: boolean): Promise<LearningPath[]>;
  /** Ruta por slug; null si no existe (o no está publicada). */
  findBySlug(slug: string): Promise<LearningPath | null>;
  /** Ruta por id (para responder tras un update en el admin). */
  findById(id: string): Promise<LearningPath | null>;
  create(input: NewPathInput): Promise<LearningPath>;
  /** Actualiza la cabecera; null si el id no existe. */
  update(id: string, input: NewPathInput): Promise<LearningPath | null>;
  /** Borra la ruta (cursos en cascada); false si no existía. */
  remove(id: string): Promise<boolean>;
  /** Reemplaza TODOS los cursos de la ruta (borra y reinserta). */
  setCourses(pathId: string, entries: PathCourseEntry[]): Promise<void>;
}

/**
 * Duración de la ruta: la guardada a mano o, si no, la suma de las
 * horas de sus cursos.
 */
export function durationHoursOf(
  path: Pick<LearningPath, 'durationHours'>,
  courses: PathCourse[],
): number {
  if (path.durationHours > 0) return path.durationHours;
  return courses.reduce((total, course) => total + course.hours, 0);
}

/**
 * Precio de la ruta a partir de su total y su % de rebaja.
 * `totalCoursesPrice` = suma de precios EFECTIVOS de los cursos.
 * `price` = total × (100 − discount) /100, redondeado a2 decimales.
 * Sin cursos el precio es0 (la tarjeta no pinta precio).
 */
export function pathPricingOf(
  courses: PathCourse[],
  discountPercent: number,
): { totalCoursesPrice: number; price: number } {
  const total = courses.reduce((sum, course) => sum + course.price, 0);
  const discount = Math.min(Math.max(discountPercent,0),100);
  const price = Math.round(total * (100 - discount)) /100;
  return { totalCoursesPrice: Math.round(total *100) /100, price };
}

/**
 * Slug de una ruta a partir de su título ("Estructuras y diseño" →
 * "estructuras-y-diseno"): minúsculas, sin tildes ni espacios.
 * Igual que slugFromName de catalog.ts pero SIN acentos, para que los
 * slugs de las URLs siempre sean ASCII.
 */
export function slugFromPathTitle(title: string): string {
  // NFD + quitar marcas diacríticas: "diseño" → "diseno".
  return slugFromName(
    title.normalize('NFD').replace(/[̀-ͯ]/g, ''),
  );
}
