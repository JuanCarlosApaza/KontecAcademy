import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/membership_plan.dart';

/// Membresía con usuario y plan resueltos (tabla del panel).
class MembershipRecord {
  const MembershipRecord({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    required this.months,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userEmail;
  final String planId;
  final String planName;
  final int months;

  /// pending_payment | active | rejected | expired | revoked
  final String status;
  final String? startDate;
  final String? endDate;
  final String createdAt;

  /// true si está vigente (active y con fin futuro).
  bool get isActive => status == 'active';
}

/// Datos para crear/editar un plan (formulario del panel).
class AdminPlanInput {
  const AdminPlanInput({
    required this.name,
    this.slug,
    required this.months,
    required this.price,
    this.isActive = true,
    this.sortOrder = 0,
    this.imageUrl,
  });

  final String name;
  final String? slug;
  final int months;
  final double price;
  final bool isActive;
  final int sortOrder;
  final String? imageUrl;
}

/// Otorgamiento manual de membresía (usuario + plan).
class AdminGrantInput {
  const AdminGrantInput({required this.userId, required this.planId});

  final String userId;
  final String planId;
}

/// Contrato del CRUD de membresías/planes del panel.
abstract interface class MembershipsRepository {
  /// Todos los planes (incluye inactivos).
  Future<(List<MembershipPlan>, Failure?)> listPlans();
  Future<(MembershipPlan?, Failure?)> createPlan(AdminPlanInput input);
  Future<(MembershipPlan?, Failure?)> updatePlan(
    String id,
    AdminPlanInput input,
  );

  /// false = el plan no existía.
  Future<(bool, Failure?)> deletePlan(String id);

  /// Todas las membresías (usuario + plan resueltos).
  Future<(List<MembershipRecord>, Failure?)> listMemberships();

  /// Alta manual → activa con fechas calculadas por el backend.
  Future<(MembershipRecord?, Failure?)> grant(AdminGrantInput input);

  /// Cambia estado/fechas (revocar, reactivar…); null = no existe.
  Future<(MembershipRecord?, Failure?)> updateMembership(
    String id,
    Map<String, dynamic> patch,
  );
}
