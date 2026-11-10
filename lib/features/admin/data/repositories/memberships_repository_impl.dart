import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../landing/data/models/membership_plan_model.dart';
import '../../../landing/domain/entities/membership_plan.dart';
import '../../data/datasources/memberships_admin_remote_datasource.dart';
import '../../domain/repositories/memberships_repository.dart';

/// Implementación del CRUD de membresías del panel (API REST).
final membershipsRepositoryProvider = Provider<MembershipsRepository>(
  (ref) => MembershipsRepositoryImpl(
    ref.watch(membershipsAdminRemoteDataSourceProvider),
  ),
);

class MembershipsRepositoryImpl implements MembershipsRepository {
  MembershipsRepositoryImpl(this._remote);

  final MembershipsAdminRemoteDataSource _remote;

  @override
  Future<(List<MembershipPlan>, Failure?)> listPlans() async {
    try {
      final rows = await _remote.listPlans();
      return (
        rows
            .map((row) => MembershipPlanModel.fromJson(row).toEntity())
            .toList(),
        null,
      );
    } catch (e) {
      return (<MembershipPlan>[], _failure(e));
    }
  }

  @override
  Future<(MembershipPlan?, Failure?)> createPlan(AdminPlanInput input) async {
    try {
      final row = await _remote.createPlan(_planBody(input));
      return (MembershipPlanModel.fromJson(row).toEntity(), null);
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(MembershipPlan?, Failure?)> updatePlan(
    String id,
    AdminPlanInput input,
  ) async {
    try {
      final row = await _remote.updatePlan(id, _planBody(input));
      return (MembershipPlanModel.fromJson(row).toEntity(), null);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return (null, null);
      return (null, _failure(e));
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(bool, Failure?)> deletePlan(String id) async {
    try {
      await _remote.deletePlan(id);
      return (true, null);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return (false, null);
      return (false, _failure(e));
    } catch (e) {
      return (false, _failure(e));
    }
  }

  @override
  Future<(List<MembershipRecord>, Failure?)> listMemberships() async {
    try {
      final rows = await _remote.listMemberships();
      return (rows.map(_toRecord).toList(), null);
    } catch (e) {
      return (<MembershipRecord>[], _failure(e));
    }
  }

  @override
  Future<(MembershipRecord?, Failure?)> grant(AdminGrantInput input) async {
    try {
      final row = await _remote.grant({
        'userId': input.userId,
        'planId': input.planId,
        'status': 'active',
      });
      return (_toRecord(row), null);
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(MembershipRecord?, Failure?)> updateMembership(
    String id,
    Map<String, dynamic> patch,
  ) async {
    try {
      final row = await _remote.updateMembership(id, patch);
      return (_toRecord(row), null);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return (null, null);
      return (null, _failure(e));
    } catch (e) {
      return (null, _failure(e));
    }
  }

  MembershipRecord _toRecord(Map<String, dynamic> row) => MembershipRecord(
    id: row['id'] as String? ?? '',
    userId: row['userId'] as String? ?? '',
    userEmail: row['userEmail'] as String? ?? '',
    planId: row['planId'] as String? ?? '',
    planName: row['planName'] as String? ?? '',
    months: (row['months'] as num?)?.toInt() ?? 0,
    status: row['status'] as String? ?? '',
    startDate: row['startDate'] as String?,
    endDate: row['endDate'] as String?,
    createdAt: row['createdAt'] as String? ?? '',
  );

  Map<String, dynamic> _planBody(AdminPlanInput input) => {
    'name': input.name,
    if (input.slug != null && input.slug!.isNotEmpty) 'slug': input.slug,
    'months': input.months,
    'price': input.price,
    'isActive': input.isActive,
    'sortOrder': input.sortOrder,
    'imageUrl': input.imageUrl,
  };

  Failure _failure(Object error) {
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    return UnknownFailure(error.toString());
  }
}
