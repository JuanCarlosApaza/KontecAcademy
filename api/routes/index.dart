import 'package:dart_frog/dart_frog.dart';

/// GET / — health check de la API.
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'app': 'Kontec API',
      'status': 'ok',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    },
  );
}
