import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session_access.dart';
import '../../domain/repositories/admin_session_repository.dart';
import '../datasources/admin_session_remote_datasource.dart';

/// Implementación concreta del repositorio de sesión del panel admin.
///
/// Traduce excepciones (`data`) en fallas (`domain`).
final adminSessionRepositoryProvider = Provider<AdminSessionRepository>(
  (ref) => AdminSessionRepositoryImpl(
    ref.watch(adminSessionRemoteDataSourceProvider),
  ),
);

class AdminSessionRepositoryImpl implements AdminSessionRepository {
  AdminSessionRepositoryImpl(this._remote);

  final AdminSessionRemoteDataSource _remote;

  @override
  Future<(SessionAccess, Failure?)> getSession() async {
    const empty = SessionAccess();
    try {
      final model = await _remote.fetchSession();
      if (model == null) return (empty, null);

      return (
        SessionAccess(roles: model.roles, permissions: model.permissions),
        null,
      );
    } on ServerException catch (e) {
      return (empty, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (empty, NetworkFailure(e.message));
    } catch (e) {
      return (empty, UnknownFailure(e.toString()));
    }
  }
}
