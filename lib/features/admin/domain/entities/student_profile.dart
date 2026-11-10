import 'package:equatable/equatable.dart';

/// Inscripción del estudiante en un curso (fila del perfil).
class StudentEnrollment extends Equatable {
  const StudentEnrollment({
    required this.courseId,
    required this.title,
    required this.status,
    this.enrolledAt,
  });

  final String courseId;
  final String title;

  /// Estado de la INSCRIPCIÓN: pending_payment | approved | rejected
  /// | finished | revoked (sin acceso).
  final String status;

  final DateTime? enrolledAt;

  /// true = el estudiante tiene ACCESO al aula.
  bool get hasAccess => status == 'approved' || status == 'finished';

  /// true = el admin le quitó el acceso.
  bool get isRevoked => status == 'revoked';

  @override
  List<Object?> get props => [courseId, title, status, enrolledAt];
}

/// Perfil del estudiante + sus cursos (pantalla de detalle del panel).
class StudentProfile extends Equatable {
  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.createdAt,
    this.isActive = true,
    this.enrollments = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? nationality;
  final DateTime? createdAt;

  /// false = cuenta desactivada (no puede iniciar sesión).
  final bool isActive;

  final List<StudentEnrollment> enrollments;

  /// Iniciales para el avatar de la cabecera (ej: "Carla Quispe" → "CQ").
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    if (parts.isEmpty) return '?';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    nationality,
    createdAt,
    isActive,
    enrollments,
  ];
}
