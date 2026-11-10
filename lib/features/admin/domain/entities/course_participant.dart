import 'package:equatable/equatable.dart';

/// Participante de un curso: la inscripción de un estudiante con sus
/// datos de contacto (sección "Participantes" del panel).
class CourseParticipant extends Equatable {
  const CourseParticipant({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.status,
    this.enrolledAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String? phone;

  /// Estado de la INSCRIPCIÓN: pending_payment | approved | rejected
  /// | finished | revoked (sin acceso).
  final String status;

  /// Cuándo se inscribió por primera vez.
  final DateTime? enrolledAt;

  /// true = el estudiante tiene ACCESO al aula (pago aprobado).
  bool get hasAccess => status == 'approved' || status == 'finished';

  /// true = el admin le quitó el acceso (pago incompleto u otro motivo).
  bool get isRevoked => status == 'revoked';

  @override
  List<Object?> get props => [
    userId,
    fullName,
    email,
    phone,
    status,
    enrolledAt,
  ];
}

/// Lista de participantes de un curso, con su título (respuesta de
/// `GET /admin/courses/:id/participants`).
class CourseParticipants extends Equatable {
  const CourseParticipants({
    required this.courseId,
    required this.courseTitle,
    this.participants = const [],
  });

  final String courseId;
  final String courseTitle;
  final List<CourseParticipant> participants;

  @override
  List<Object?> get props => [courseId, courseTitle, participants];
}
