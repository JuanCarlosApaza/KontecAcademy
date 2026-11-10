import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/checkout_data.dart';
import '../../domain/entities/checkout_result.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_datasource.dart';

/// Implementación concreta del repositorio de checkout.
///
/// Traduce excepciones (`data`) en fallas (`domain`) y adjunta el JWT
/// de la sesión actual a cada petición.
final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepositoryImpl(
    ref.watch(checkoutRemoteDataSourceProvider),
    ref.watch(authRepositoryProvider),
  ),
);

class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl(this._remote, this._auth);

  final CheckoutRemoteDataSource _remote;
  final AuthRepository _auth;

  @override
  Future<(CheckoutResult, Failure?)> enroll({
    required List<CartItem> items,
    required CheckoutData data,
  }) async {
    final token = _auth.accessToken;
    if (token == null) {
      return (
        const CheckoutResult(enrollmentIds: [], paymentIds: [], total: 0),
        const UnknownFailure('Tu sesión expiró. Inicia sesión de nuevo.'),
      );
    }

    try {
      final result = await _remote.enroll(
        items: items,
        data: data,
        accessToken: token,
      );
      return (result, null);
    } on ServerException catch (e) {
      return (
        const CheckoutResult(enrollmentIds: [], paymentIds: [], total: 0),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return (
        const CheckoutResult(enrollmentIds: [], paymentIds: [], total: 0),
        UnknownFailure(e.toString()),
      );
    }
  }
}
