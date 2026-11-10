import 'package:equatable/equatable.dart';

/// KPIs del dashboard administrativo (`GET /admin/stats`).
class AdminStats extends Equatable {
  const AdminStats({
    this.students = 0,
    this.courses = 0,
    this.enrollments = 0,
    this.pendingPayments = 0,
    this.revenue = 0,
  });

  final int students;
  final int courses;
  final int enrollments;

  /// Pagos esperando aprobación de ticket.
  final int pendingPayments;

  /// Ingresos aprobados (USD).
  final double revenue;

  @override
  List<Object?> get props => [
    students,
    courses,
    enrollments,
    pendingPayments,
    revenue,
  ];
}
