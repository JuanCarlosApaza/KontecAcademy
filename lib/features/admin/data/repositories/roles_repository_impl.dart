import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/roles_matrix.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_remote_datasource.dart';

/// Implementación concreta del repositorio de roles.
///
/// Traduce excepciones (`data`) en fallas (`domain`).
final rolesRepositoryProvider = Provider<RolesRepository>(
  (ref) => RolesRepositoryImpl(ref.watch(rolesRemoteDataSourceProvider)),
);

class RolesRepositoryImpl implements RolesRepository {
  RolesRepositoryImpl(this._remote);

  final RolesRemoteDataSource _remote;

  @override
  Future<(RolesMatrix?, Failure?)> getMatrix() async {
    try {
      final model = await _remote.fetchMatrix();
      return (model.matrix, null);
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(RoleRecord?, Failure?)> createRole({
    required String name,
    required String description,
  }) async {
    try {
      final json = await _remote.createRole(
        name: name,
        description: description,
      );
      final record = RoleRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        userCount: (json['userCount'] as num?)?.toInt() ?? 0,
        system: json['system'] as bool? ?? false,
      );
      return (record, null);
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<Failure?> savePermissions({
    required String roleId,
    required List<String> codes,
  }) async {
    try {
      await _remote.savePermissions(roleId: roleId, codes: codes);
      return null;
    } catch (e) {
      return _failure(e);
    }
  }

  @override
  Future<Failure?> deleteRole(String roleId) async {
    try {
      await _remote.deleteRole(roleId);
      return null;
    } catch (e) {
      return _failure(e);
    }
  }

  Failure _failure(Object error) {
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    return UnknownFailure(error.toString());
  }
}
