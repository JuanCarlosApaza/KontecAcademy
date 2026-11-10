import '../../domain/entities/session_activity.dart';

/// DTO de persistencia de [SessionActivity] (SharedPreferences).
/// Único lugar con JSON; el dominio queda puro.
class SessionActivityModel {
  const SessionActivityModel({
    required this.action,
    required this.at,
    this.detail,
  });

  final String action;
  final String? detail;
  final DateTime at;

  factory SessionActivityModel.fromJson(Map<String, dynamic> json) {
    return SessionActivityModel(
      action: json['action'] as String? ?? '',
      detail: json['detail'] as String?,
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'detail': detail,
    'at': at.toIso8601String(),
  };

  /// Mapper entidad → DTO (para guardar).
  factory SessionActivityModel.fromEntity(SessionActivity activity) {
    return SessionActivityModel(
      action: activity.action,
      detail: activity.detail,
      at: activity.at,
    );
  }

  /// Mapper DTO → entidad (para leer).
  SessionActivity toEntity() =>
      SessionActivity(action: action, detail: detail, at: at);
}
