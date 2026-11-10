import 'package:equatable/equatable.dart';

/// Pago del panel administrativo, con el usuario y el curso ya
/// resueltos (para la tabla "Pagos por aprobar").
class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.pathId,
    this.pathTitle,
  });

  final String id;
  final String userId;
  final String email;
  final String fullName;
  final String courseId;
  final String courseTitle;

  /// Monto en USD registrado en el pago.
  final double amount;

  /// 'pending_approval' | 'approved' | 'rejected'
  final String status;
  final DateTime? createdAt;

  /// Pago de COMBO: id/título de la ruta comprada (null = curso suelto).
  /// El mismo ticket aprueba TODOS los cursos de la ruta.
  final String? pathId;
  final String? pathTitle;

  /// true si el pago espera aprobación de ticket.
  bool get isPending => status == 'pending_approval';

  /// true si es el ticket de una ruta (combo).
  bool get isPath => pathId != null;

  @override
  List<Object?> get props => [
    id,
    userId,
    email,
    fullName,
    courseId,
    courseTitle,
    amount,
    status,
    createdAt,
    pathId,
    pathTitle,
  ];
}
