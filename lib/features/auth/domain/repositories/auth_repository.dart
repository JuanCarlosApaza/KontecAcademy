import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../entities/sign_up_params.dart';
import '../entities/sign_up_result.dart';

/// Contrato de autenticación (dominio).
///
/// La implementación (data) usa Supabase Auth; el dominio solo ve
/// esta interfaz y las fallas de negocio.
abstract class AuthRepository {
  /// Flujo continuo de sesión: emite el usuario actual (o null al cerrar
  /// sesión). La primera emisión llega en caliente con la sesión guardada.
  Stream<AuthUser?> authStateChanges();

  /// Usuario de la sesión actual (null si no hay sesión).
  AuthUser? get currentUser;

  /// Token JWT de la sesión actual (para llamar a la API autenticada).
  String? get accessToken;

  /// Login con email + contraseña.
  Future<(AuthUser?, Failure?)> signInWithEmail(String email, String password);

  /// Registro con email + contraseña. Si Supabase tiene confirmación de
  /// email activada, el resultado trae `session == null` y hay que avisar
  /// al usuario que revise su correo.
  Future<(SignUpResult, Failure?)> signUpWithEmail(SignUpParams params);

  /// Login con Google (OAuth). En web usa redirect del navegador; en
  /// Android abre el navegador del dispositivo con el callback de la app.
  Future<(AuthUser?, Failure?)> signInWithGoogle({String? redirectTo});

  /// Cierra la sesión. Devuelve una Falla solo si algo salió mal.
  Future<Failure?> signOut();
}
