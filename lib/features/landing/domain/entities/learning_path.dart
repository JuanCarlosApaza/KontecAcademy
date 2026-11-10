/// Curso dentro de una ruta de entrenamiento (miniatura de la tarjeta
/// y fila del detalle: título, imagen, precio, horas y nivel).
class PathCourse {
  const PathCourse({
    required this.courseId,
    required this.title,
    this.imageUrl,
    this.price = 0,
    this.hours = 0,
    this.level,
    this.sortOrder = 0,
  });

  final String courseId;
  final String title;
  final String? imageUrl;
  final double price;
  final int hours;

  /// Nivel dentro de la ruta ('Introductorio' | 'Intermedio' |
  /// 'Avanzado' | null = sin nivel).
  final String? level;
  final int sortOrder;
}

/// Ruta de entrenamiento: agrupación ORDENADA de cursos con nivel.
/// Precio propio: `totalCoursesPrice` = suma de los precios EFECTIVOS
/// de sus cursos (ofertas ya aplicadas); `price` = total con el
/// `discountPercent` de la ruta aplicado. Informativa: el botón lleva
/// a los cursos (cada uno se compra por su cuenta).
class LearningPath {
  const LearningPath({
    required this.id,
    required this.slug,
    required this.title,
    this.description = '',
    this.coverUrl,
    this.modality = 'asynchronous',
    this.durationHours = 0,
    this.accessMonths = 12,
    this.discountPercent = 0,
    this.totalCoursesPrice = 0,
    this.price = 0,
    this.sortOrder = 0,
    this.isPublished = true,
    this.courses = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String description;

  /// Portada de la ruta (null = la tarjeta usa un gradiente de marca).
  final String? coverUrl;

  /// Código crudo de la API: 'asynchronous' | 'live'.
  final String modality;

  /// Horas totales (derivadas de los cursos salvo override manual).
  final int durationHours;

  /// Meses de acceso anunciados (dato informativo de la ruta).
  final int accessMonths;

  /// % de rebaja (0-100) que aplica la ruta sobre su total.
  final int discountPercent;

  /// Total de referencia (precursos con oferta aplicada); se muestra tachado.
  final double totalCoursesPrice;

  /// Precio final de la ruta (total con la rebaja aplicada).
  final double price;

  final int sortOrder;
  final bool isPublished;

  /// Cursos de la ruta YA ORDENADOS por sortOrder.
  final List<PathCourse> courses;
}
