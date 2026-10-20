import 'package:api/todo_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// Instancia única del repositorio para TODAS las peticiones.
/// Si cambias a base de datos, solo se sustituye la implementación aquí.
final _repository = InMemoryTodoRepository();

const _corsHeaders = {
  // ⚠️ En producción conviene restringir al dominio exacto del frontend:
  // 'access-control-allow-origin': 'https://mi-app.com',
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

Handler middleware(Handler handler) {
  return handler
      .use(provider<TodoRepository>((_) => _repository))
      // CORS: necesario para que el navegador (Flutter web) permita
      // llamar a esta API desde otro origen (ej: localhost:8080 -> :3000).
      .use((handler) => (context) async {
            if (context.request.method == HttpMethod.options) {
              // Preflight: responde 204 con los permisos y sin cuerpo.
              return Response(statusCode: 204, headers: _corsHeaders);
            }
            final response = await handler(context);
            return response.copyWith(
              headers: {...response.headers, ..._corsHeaders},
            );
          });
}
