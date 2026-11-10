import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/repositories/membership_plan_repository.dart';
import '../datasources/membership_plan_remote_datasource.dart';

/// Implementación del repositorio de planes: habla con la API REST.
final membershipPlanRepositoryProvider = Provider<MembershipPlanRepository>(
  (ref) => MembershipPlanRepositoryImpl(
    ref.watch(membershipPlanRemoteDataSourceProvider),
  ),
);

class MembershipPlanRepositoryImpl implements MembershipPlanRepository {
  MembershipPlanRepositoryImpl(this._remote);

  final MembershipPlanRemoteDataSource _remote;

  @override
  Future<(List<MembershipPlan>, Failure?)> getPlans() async {
    try {
      final models = await _remote.fetchPlans();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (<MembershipPlan>[], ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (<MembershipPlan>[], NetworkFailure(e.message));
    } catch (e) {
      return (<MembershipPlan>[], UnknownFailure(e.toString()));
    }
  }
}
