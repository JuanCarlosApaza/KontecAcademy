import 'package:equatable/equatable.dart';

import 'session_activity.dart';

/// Contexto global de sesión — el equivalente a un React Context.
///
/// Responde, en un solo lugar, las preguntas globales:
///  * ¿Quién tiene la sesión abierta? ([userId], [email], [displayName])
///  * ¿Cuándo entró? ([startedAt])
///  * ¿Qué ha hecho hasta ahora? ([activities], más reciente primero)
///
/// Lo consume cualquier pantalla/viewmodel vía `sessionContextProvider`;
/// se limpia solo al cerrar sesión. Entidad pura: sin JSON ni Flutter.
class SessionContext extends Equatable {
  const SessionContext({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.startedAt,
    this.activities = const [],
  });

  final String userId;
  final String email;
  final String displayName;

  /// Momento en que comenzó la sesión actual.
  final DateTime startedAt;

  /// Rastro de actividad del estudiante (más reciente primero).
  final List<SessionActivity> activities;

  SessionContext copyWith({List<SessionActivity>? activities}) {
    return SessionContext(
      userId: userId,
      email: email,
      displayName: displayName,
      startedAt: startedAt,
      activities: activities ?? this.activities,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    startedAt,
    activities,
  ];
}
