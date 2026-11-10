import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/remember_email_repository.dart';

/// Guarda/borra el correo "recordado" en el dispositivo.
/// Solo el correo: la contraseña NUNCA se persiste.
class RememberEmailRepositoryImpl implements RememberEmailRepository {
  static const _key = 'login_remember_email';

  @override
  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> setRememberedEmail(
    String email, {
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_key, email);
    } else {
      await prefs.remove(_key);
    }
  }
}

final rememberEmailRepositoryProvider = Provider<RememberEmailRepository>(
  (ref) => RememberEmailRepositoryImpl(),
);
