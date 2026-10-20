/// Configuración de la API.
///
/// Por defecto apunta a la API local (terminal 1: tool\dev-api.ps1).
/// Para producción u otro entorno, compila con:
///   flutter build web --dart-define=API_URL=https://mi-api.com
///   flutter run -d chrome --dart-define=API_URL=https://mi-api.com
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );
}
