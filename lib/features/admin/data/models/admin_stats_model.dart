import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_stats.dart';

/// DTO de los KPIs del dashboard (`GET /admin/stats`).
///
/// Único lugar del feature que conoce el JSON de las estadísticas;
/// la UI y el dominio solo ven la entidad [AdminStats].
class AdminStatsModel extends Equatable {
  const AdminStatsModel({
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

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) =>
      AdminStatsModel(
        students: (json['students'] as num?)?.toInt() ?? 0,
        courses: (json['courses'] as num?)?.toInt() ?? 0,
        enrollments: (json['enrollments'] as num?)?.toInt() ?? 0,
        pendingPayments: (json['pendingPayments'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      );

  /// Traduce a entidad de dominio (mapper).
  AdminStats toEntity() => AdminStats(
    students: students,
    courses: courses,
    enrollments: enrollments,
    pendingPayments: pendingPayments,
    revenue: revenue,
  );

  @override
  List<Object?> get props => [
    students,
    courses,
    enrollments,
    pendingPayments,
    revenue,
  ];
}
