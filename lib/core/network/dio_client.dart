import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'error_logging_interceptor.dart';

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

  // Errores SIEMPRE (también en release): traza única de fallos de API.
  dio.interceptors.add(const ErrorLoggingInterceptor());

  // Solo loguea en modo desarrollo.
  assert(() {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    return true;
  }());

  return dio;
});
