import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../auth_injector.dart';
import '../../domain/entities/sign_up_params.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/usecases/set_remembered_email.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import 'auth_providers.dart';

/// STATE del formulario de login/registro (errores, spinner y
/// "Recuérdame").
class AuthFormState {
  const AuthFormState({
    this.isLoading = false,
    this.error,
    this.savedEmail,
    this.rememberMe = true,
  });

  final bool isLoading;
  final Failure? error;

  /// Correo guardado por el checkbox "Recuérdame" (para prellenar).
  final String? savedEmail;

  /// Valor actual del checkbox "Recuérdame".
  final bool rememberMe;

  AuthFormState copyWith({
    bool? isLoading,
    Failure? error,
    String? savedEmail,
    bool? rememberMe,
    bool clearError = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      savedEmail: savedEmail ?? this.savedEmail,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

/// ViewModel (MVVM) del login y el registro.
///
/// La sesión en sí vive en [authUserProvider] (stream de Supabase);
/// este ViewModel solo maneja el envío de los formularios.
class AuthViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() {
    // "Recuérdame": precarga el correo guardado (async, no bloquea).
    Future.microtask(_loadRememberedEmail);
    return const AuthFormState();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final email = await ref.read(getRememberedEmailProvider)(NoParams());
      if (email != null && email.isNotEmpty) {
        state = state.copyWith(savedEmail: email, rememberMe: true);
      }
    } catch (_) {
      // Sin almacenamiento (tests / modo privado): sin correo guardado.
    }
  }

  /// Actualiza el checkbox "Recuérdame".
  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  /// Login con email + contraseña. Devuelve true si se pudo entrar.
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (user, failure) = await ref.read(signInWithEmailProvider)(
      SignInWithEmailParams(email: email, password: password),
    );

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return false;
    }

    // "Recuérdame": guarda (o borra) el correo para el próximo login.
    try {
      await ref.read(setRememberedEmailProvider)(
        SetRememberedEmailParams(email: email, remember: state.rememberMe),
      );
    } catch (_) {
      // Sin almacenamiento: el login no falla por esto.
    }

    state = AuthFormState(savedEmail: email, rememberMe: state.rememberMe);
    // La UI escucha authUserProvider; al firmar, el stream emite.
    ref.invalidate(authUserProvider);
    return user != null;
  }

  /// Registro con email + contraseña.
  /// Devuelve [SignUpResult] para que la UI avise si hay que confirmar
  /// el correo (Supabase con "Confirm email" activado).
  Future<(SignUpResult, Failure?)> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (result, failure) = await ref.read(signUpWithEmailProvider)(
      SignUpParams(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      ),
    );

    state = state.copyWith(isLoading: false, error: failure);
    if (failure == null) ref.invalidate(authUserProvider);
    return (result, failure);
  }

  /// Login con Google. En web/navegador la app SALE y vuelve con la
  /// sesión; authUserProvider se encarga del resto.
  Future<Failure?> signInWithGoogle({String? redirectTo}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (_, failure) = await ref.read(signInWithGoogleProvider)(
      SignInGoogleParams(redirectTo: redirectTo),
    );

    state = state.copyWith(isLoading: false, error: failure);
    return failure;
  }

  Future<Failure?> signOut() async {
    final failure = await ref.read(signOutProvider)(NoParams());
    ref.invalidate(authUserProvider);
    return failure;
  }

  /// Limpia el error visible (ej: al volver a escribir).
  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthFormState>(
  AuthViewModel.new,
);
