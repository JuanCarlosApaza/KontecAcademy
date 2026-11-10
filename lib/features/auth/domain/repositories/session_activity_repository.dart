import '../entities/session_activity.dart';

/// Contrato de persistencia del rastro de actividad de la sesión.
/// La impl (data) guarda las últimas acciones por usuario en el
/// dispositivo; el dominio solo define QUÉ se guarda.
abstract interface class SessionActivityRepository {
  /// Últimas acciones registradas del usuario (más reciente primero).
  Future<List<SessionActivity>> load(String userId);

  /// Reemplaza el historial del usuario (se guarda acotado).
  Future<void> save(String userId, List<SessionActivity> activities);
}
