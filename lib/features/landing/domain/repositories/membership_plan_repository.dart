import '../../../../core/error/failures.dart';
import '../entities/membership_plan.dart';

/// Contrato de acceso a los planes de membresía (público).
abstract interface class MembershipPlanRepository {
  /// Planes activos con sus precios (pantalla /membresias).
  Future<(List<MembershipPlan>, Failure?)> getPlans();
}
