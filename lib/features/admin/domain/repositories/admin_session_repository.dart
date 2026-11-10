import '../../../../core/error/failures.dart';
import '../entities/session_access.dart';

/// Contrato de la sesión actual en el panel admin (`GET /me`).
///
/// Implementación (data): llama a la API Node con el JWT de Supabase
/// y devuelve los roles + permisos del usuario autenticado.
abstract class AdminSessionRepository {
  /// Roles y permisos del usuario actual.
  ///
  /// Vacío si no hay sesión o la petición falla (fail-closed: sin
  /// respuesta confiable no se otorgan permisos).
  Future<(SessionAccess, Failure?)> getSession();
}
