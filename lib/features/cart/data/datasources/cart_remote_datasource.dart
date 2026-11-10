import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/auth_injector.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

/// 🔌 DATOS — carrito remoto (`GET/PUT /cart` del server Node).
///
/// El servidor guarda SOLO los courseIds y devuelve cada ítem con el
/// título/precio/modalidad/imagen VIGENTES de la BD: el precio nunca
/// viaja del cliente al servidor (así no se puede manipular).
class CartRemoteDataSource {
  CartRemoteDataSource(this._dio, this._auth);

  final Dio _dio;
  final AuthRepository _auth;

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer ${_auth.accessToken}'});

  /// Carrito del usuario del JWT (orden de addedAt asc).
  Future<List<CartItemModel>> fetchCart() async {
    try {
      final response = await _dio.get<dynamic>('/cart', options: _authOptions);
      final rows = response.data as List<dynamic>;
      return rows
          .map((row) => CartItemModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo cargar el carrito');
    }
  }

  /// Reemplaza el carrito COMPLETO en el servidor (ids + tipo).
  /// Devuelve la cantidad de ítems que quedaron guardados.
  Future<int> replaceCart(List<CartItem> items) async {
    try {
      final response = await _dio.put<dynamic>(
        '/cart',
        data: {
          'items': [
            for (final item in items)
              {'courseId': item.courseId, 'type': item.type},
          ],
        },
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>?;
      return (data?['count'] as num?)?.toInt() ?? items.length;
    } on DioException catch (e) {
      throw _serverOrNetwork(e, 'No se pudo guardar el carrito');
    }
  }

  /// Conexión caída → [NetworkException]; otro caso → [ServerException]
  /// con el mensaje que devolvió la API.
  Exception _serverOrNetwork(DioException e, String fallback) {
    final type = e.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return NetworkException(e.message ?? 'Sin conexión con el servidor');
    }

    final data = e.response?.data;
    final apiMessage = data is Map && data['error'] is String
        ? data['error'] as String
        : null;

    return ServerException(
      apiMessage ?? e.message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>(
  (ref) => CartRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  ),
);
