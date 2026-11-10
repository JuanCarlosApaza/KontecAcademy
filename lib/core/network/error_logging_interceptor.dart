import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Registro global de TODAS las respuestas fallidas de la API.
///
/// Se sitúa en `dioProvider` para que ningún datasource tenga que
/// loguear por su cuenta: cada error queda trazado con método, ruta,
/// status y mensaje del servidor en un solo formato `[API ERROR] …`.
///
/// NO cambia el tipo de excepción: `err` sigue siendo un [DioException],
/// así los `on DioException` de cada datasource y el mapeo a `Failure`
/// de los repositorios siguen funcionando igual.
class ErrorLoggingInterceptor extends Interceptor {
  const ErrorLoggingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final status = err.response?.statusCode ?? 'sin respuesta';
    final serverMessage = _serverMessage(err);

    debugPrint(
      '[API ERROR] ${request.method} ${request.uri.path} → $status'
      '${serverMessage != null ? ' · $serverMessage' : ''}'
      '${err.message != null ? ' · ${err.message}' : ''}',
    );

    handler.next(err);
  }

  /// Mensaje de error que devolvió la API (`{error|message: "…"}`), si lo hay.
  String? _serverMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
