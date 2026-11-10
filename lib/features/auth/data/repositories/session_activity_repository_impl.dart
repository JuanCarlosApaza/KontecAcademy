import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/session_activity.dart';
import '../../domain/repositories/session_activity_repository.dart';
import '../models/session_activity_model.dart';

/// Implementación con SharedPreferences: guarda las últimas
/// [maxActivities] acciones por usuario en el dispositivo.
class SessionActivityRepositoryImpl implements SessionActivityRepository {
  SessionActivityRepositoryImpl({this.maxActivities = 50});

  final int maxActivities;
  static const _keyPrefix = 'session_activities_';

  @override
  Future<List<SessionActivity>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SessionActivityModel.fromJson)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<void> save(String userId, List<SessionActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final limited = activities.take(maxActivities).toList();
    final encoded = jsonEncode(
      limited
          .map(SessionActivityModel.fromEntity)
          .map((m) => m.toJson())
          .toList(),
    );
    await prefs.setString('$_keyPrefix$userId', encoded);
  }
}
