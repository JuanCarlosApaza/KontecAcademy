import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/checkout_data.dart';
import '../../domain/entities/checkout_result.dart';
import '../models/checkout_result_model.dart';

/// 🔌 DATOS — llama a `POST /checkout` de la API Node autenticándose
/// con el JWT de Supabase del usuario. El backend escribe en la BD con
/// la service_role (el front jamás la ve).
class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._dio);

  final Dio _dio;

  /// Crea la inscripción en el backend y devuelve el resultado
  /// traducido a entidad de dominio.
  Future<CheckoutResult> enroll({
    required List<CartItem> items,
    required CheckoutData data,
    required String accessToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/checkout',
        data: {
          'fullName': data.fullName,
          'email': data.email,
          'phone': data.phone,
          'nationality': data.nationality,
          'documentNumber': data.documentNumber,
          'items': [
            for (final item in items)
              {
                'courseId': item.courseId,
                'amount': item.price,
                'type': item.type,
              },
          ],
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final body = response.data as Map<String, dynamic>;
      return CheckoutResultModel.fromJson(body).toEntity();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = (e.response?.data is Map)
          ? (e.response!.data['error'] as String?)
          : null;
      throw ServerException(
        message ?? 'No se pudo registrar la inscripción',
        statusCode: status,
      );
    }
  }
}

final checkoutRemoteDataSourceProvider = Provider<CheckoutRemoteDataSource>(
  (ref) => CheckoutRemoteDataSource(ref.watch(dioProvider)),
);
