import 'package:equatable/equatable.dart';

/// Estudiante (usuario registrado) del panel admin.
class StudentRecord extends Equatable {
  const StudentRecord({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.createdAt,
    this.enrolledCourses = 0,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? nationality;
  final DateTime? createdAt;

  /// Cursos en los que está inscrito.
  final int enrolledCourses;

  /// false = cuenta desactivada (borrado lógico; los datos se conservan).
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    nationality,
    createdAt,
    enrolledCourses,
    isActive,
  ];
}
