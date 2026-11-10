import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/sign_up_params.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_datasource.dart';

/// Implementación concreta del repositorio de autenticación.
///
/// Traduce excepciones (`data`) en fallas (`domain`) y modelos en
/// entidades. Nada más.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(supabaseAuthDataSourceProvider)),
);

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final SupabaseAuthDataSource _remote;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _remote.authStateChanges().map((model) => model.toEntity());
  }

  @override
  AuthUser? get currentUser => _remote.currentUser?.toEntity();

  @override
  String? get accessToken => _remote.accessToken;

  @override
  Future<(AuthUser?, Failure?)> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final model = await _remote.signInWithEmail(email, password);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(SignUpResult, Failure?)> signUpWithEmail(SignUpParams params) async {
    try {
      final data = await _remote.signUpWithEmail(
        email: params.email.trim(),
        password: params.password,
        fullName: params.fullName.trim(),
        phone: params.phone,
      );
      return (
        SignUpResult(
          user: data.user?.toEntity(),
          emailConfirmationRequired: data.needsEmailConfirmation,
        ),
        null,
      );
    } on ServerException catch (e) {
      return (
        const SignUpResult(),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return (const SignUpResult(), UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AuthUser?, Failure?)> signInWithGoogle({String? redirectTo}) async {
    try {
      // El OAuth por redirect NO devuelve sesión aquí: el navegador sale
      // de la app. authStateChanges() emite al volver con los tokens.
      await _remote.signInWithGoogle(redirectTo: redirectTo);
      return (_remote.currentUser?.toEntity(), null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Failure?> signOut() async {
    try {
      await _remote.signOut();
      return null;
    } on ServerException catch (e) {
      return ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
