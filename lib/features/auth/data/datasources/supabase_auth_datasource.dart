import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/auth_user_model.dart';

/// Cliente de Supabase ya inicializado (se inicializa en main()).
SupabaseClient get supabase => Supabase.instance.client;

/// 🔌 DATOS — todo lo que habla con Supabase Auth pasa por aquí.
class SupabaseAuthDataSource {
  /// Sesión en caliente: emite el usuario actual y cada cambio de sesión
  /// (login, logout, refresh, retorno del OAuth de Google).
  Stream<AuthUserModel> authStateChanges() {
    return supabase.auth.onAuthStateChange.map((event) {
      return AuthUserModel.fromSupabase(event.session?.user);
    });
  }

  AuthUserModel? get currentUser {
    final user = supabase.auth.currentUser;
    return user == null ? null : AuthUserModel.fromSupabase(user);
  }

  String? get accessToken => supabase.auth.currentSession?.accessToken;

  Future<AuthUserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const ServerException('No se pudo iniciar sesión');
      }
      return AuthUserModel.fromSupabase(user);
    } on AuthException catch (e) {
      throw ServerException(_translate(e.message));
    }
  }

  /// Registra la cuenta. Si la confirmación de email está activada,
  /// Supabase devuelve sesión null → [SignUpData.needsEmailConfirmation].
  Future<SignUpData> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          // Teléfono con prefijo internacional (dropdown de registro).
          if (phone != null && phone.trim().isNotEmpty)
            'phone': phone.trim(),
        },
      );
      return SignUpData(
        user: response.user == null
            ? null
            : AuthUserModel.fromSupabase(response.user),
        needsEmailConfirmation: response.session == null,
      );
    } on AuthException catch (e) {
      throw ServerException(_translate(e.message));
    }
  }

  /// Google OAuth por redirect: en web el navegador vuelve a la app con
  /// los tokens en la URL (supabase_flutter los detecta solo); en Android
  /// vuelve por el deep link `kontec://login-callback`.
  Future<void> signInWithGoogle({String? redirectTo}) async {
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo ?? defaultRedirectUri(),
      );
    } on AuthException catch (e) {
      throw ServerException(_translate(e.message));
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(_translate(e.message));
    }
  }

  /// URL de retorno por plataforma.
  ///  * Web → la propia URL de la app (Supabase la detecta como fragment).
  ///  * Móvil → deep link registrado en AndroidManifest (host login-callback).
  static String defaultRedirectUri() {
    return kIsWeb ? Uri.base.toString() : 'kontec://login-callback';
  }

  /// Mensajes de error de Supabase → texto claro para el usuario.
  static String _translate(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Tu correo aún no está confirmado. Revisa tu bandeja de entrada.';
    }
    if (lower.contains('already registered')) {
      return 'Ese email ya está registrado. Inicia sesión o recupera tu contraseña.';
    }
    if (lower.contains('password should be')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return message;
  }
}

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>(
  (ref) => SupabaseAuthDataSource(),
);
