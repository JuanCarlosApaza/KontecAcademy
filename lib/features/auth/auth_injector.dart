import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/remember_email_repository_impl.dart';
import 'data/repositories/session_activity_repository_impl.dart';
import 'domain/repositories/session_activity_repository.dart';
import 'domain/usecases/get_remembered_email.dart';
import 'domain/usecases/set_remembered_email.dart';
import 'domain/usecases/sign_in_with_email.dart';
import 'domain/usecases/sign_in_with_google.dart';
import 'domain/usecases/sign_out.dart';
import 'domain/usecases/sign_up_with_email.dart';

/// Composition root del feature `auth`.
/// Aquí se ensamblan las capas; el dominio no importa data.
export 'data/repositories/auth_repository_impl.dart'
    show authRepositoryProvider;

final signInWithEmailProvider = Provider<SignInWithEmail>(
  (ref) => SignInWithEmail(ref.watch(authRepositoryProvider)),
);

final signUpWithEmailProvider = Provider<SignUpWithEmail>(
  (ref) => SignUpWithEmail(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleProvider = Provider<SignInWithGoogle>(
  (ref) => SignInWithGoogle(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

// "Recuérdame": correo del último login (solo el correo, jamás la
// contraseña).
final getRememberedEmailProvider = Provider<GetRememberedEmail>(
  (ref) => GetRememberedEmail(ref.watch(rememberEmailRepositoryProvider)),
);

final setRememberedEmailProvider = Provider<SetRememberedEmail>(
  (ref) => SetRememberedEmail(ref.watch(rememberEmailRepositoryProvider)),
);

// Rastro de actividad del estudiante (contexto de sesión).
final sessionActivityRepositoryProvider = Provider<SessionActivityRepository>(
  (ref) => SessionActivityRepositoryImpl(),
);
