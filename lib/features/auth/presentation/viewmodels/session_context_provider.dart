import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth_injector.dart';
import '../../domain/entities/session_activity.dart';
import '../../domain/entities/session_context.dart';
import 'auth_providers.dart';

/// Contexto global de sesión (equivalente al React Context).
///
/// Una sola fuente de verdad para: quién tiene la sesión, cuándo entró
/// y qué ha hecho el estudiante (ver [SessionContext]). Se construye
/// solo al haber sesión y se limpia al cerrarla.
final sessionContextProvider =
    NotifierProvider<SessionContextNotifier, SessionContext?>(
      SessionContextNotifier.new,
    );

class SessionContextNotifier extends Notifier<SessionContext?> {
  /// Id del usuario con sesión activa (evita duplicar inicios cuando
  /// el stream de auth re-emite el mismo usuario).
  String? _activeUserId;

  @override
  SessionContext? build() {
    final user = ref.watch(authUserProvider).value;

    // Sin sesión → contexto vacío (nadie es rastreado).
    if (user == null) {
      _activeUserId = null;
      return null;
    }

    // Misma sesión re-emitiendo: conserva el contexto actual.
    if (_activeUserId == user.id && state != null) return state;

    _activeUserId = user.id;
    final fresh = SessionContext(
      userId: user.id,
      email: user.email,
      displayName: user.displayName,
      startedAt: DateTime.now(),
    );
    // Restaura el historial del dispositivo y anota el inicio de sesión
    // (asíncrono, sin bloquear el primer frame).
    Future.microtask(() => _startSession(fresh));
    return fresh;
  }

  Future<void> _startSession(SessionContext fresh) async {
    var history = const <SessionActivity>[];
    try {
      history = await ref
          .read(sessionActivityRepositoryProvider)
          .load(fresh.userId);
    } catch (_) {
      // Sin almacenamiento (tests / modo privado): solo memoria.
    }

    // La sesión cambió mientras se cargaba el historial: descartar.
    if (_activeUserId != fresh.userId) return;

    state = fresh.copyWith(activities: history);
    record('login', detail: fresh.email);
  }

  /// Registra una acción del estudiante en el contexto global.
  /// No-op si no hay sesión (solo se rastrea a usuarios identificados).
  void record(String action, {String? detail}) {
    final current = state;
    if (current == null) return;

    final activity = SessionActivity(
      action: action,
      detail: detail,
      at: DateTime.now(),
    );
    final activities = [activity, ...current.activities].take(50).toList();

    state = current.copyWith(activities: activities);
    _persist(current.userId, activities);
  }

  Future<void> _persist(String userId, List<SessionActivity> activities) async {
    try {
      await ref
          .read(sessionActivityRepositoryProvider)
          .save(userId, activities);
    } catch (_) {
      // Preferencias no disponibles: el rastro queda solo en memoria.
    }
  }
}
