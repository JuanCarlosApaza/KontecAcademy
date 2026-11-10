import 'package:equatable/equatable.dart';

import '../../domain/entities/learning_path.dart';

/// Curso embebido dentro de una ruta (`courses[]` de `GET /paths`).
class PathCourseModel extends Equatable {
  const PathCourseModel({
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
  final String? level;
  final int sortOrder;

  factory PathCourseModel.fromJson(Map<String, dynamic> json) =>
      PathCourseModel(
        courseId: json['courseId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        hours: (json['hours'] as num?)?.toInt() ?? 0,
        level: json['level'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  PathCourse toEntity() => PathCourse(
    courseId: courseId,
    title: title,
    imageUrl: imageUrl,
    price: price,
    hours: hours,
    level: level,
    sortOrder: sortOrder,
  );

  @override
  List<Object?> get props => [courseId, title, level, sortOrder, hours];
}

/// Modelo de ruta de entrenamiento.
///
/// Único lugar del feature que conoce el JSON de la API REST
/// (camelCase: `coverUrl`, `durationHours`, `accessMonths`, ...).
class LearningPathModel extends Equatable {
  const LearningPathModel({
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
  final String? coverUrl;
  final String modality;
  final int durationHours;
  final int accessMonths;
  final int discountPercent;
  final double totalCoursesPrice;
  final double price;
  final int sortOrder;
  final bool isPublished;
  final List<PathCourseModel> courses;

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      modality: json['modality'] as String? ?? 'asynchronous',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      accessMonths: (json['accessMonths'] as num?)?.toInt() ?? 12,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      totalCoursesPrice:
          (json['totalCoursesPrice'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPublished: json['isPublished'] as bool? ?? true,
      courses: [
        for (final course in (json['courses'] as List?) ?? const [])
          PathCourseModel.fromJson(course as Map<String, dynamic>),
      ],
    );
  }

  /// Convierte a entidad de dominio (la UI solo ve entidades).
  LearningPath toEntity() => LearningPath(
    id: id,
    slug: slug,
    title: title,
    description: description,
    coverUrl: coverUrl,
    modality: modality,
    durationHours: durationHours,
    accessMonths: accessMonths,
    discountPercent: discountPercent,
    totalCoursesPrice: totalCoursesPrice,
    price: price,
    sortOrder: sortOrder,
    isPublished: isPublished,
    courses: [for (final course in courses) course.toEntity()],
  );

  @override
  List<Object?> get props => [
    id,
    slug,
    title,
    discountPercent,
    totalCoursesPrice,
    price,
    sortOrder,
    courses,
  ];
}
