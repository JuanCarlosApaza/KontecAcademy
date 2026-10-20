import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';

/// Cliente HTTP único de la aplicación.
///
/// Aquí se centralizan: base URL, timeouts, headers, interceptores
/// (logs, auth, errores). La capa de datos NUNCA construye su propio Dio.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Solo loguea en modo desarrollo.
  assert(() {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
    return true;
  }());

  return dio;
});
