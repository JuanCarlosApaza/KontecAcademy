import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth_injector.dart';
import '../../domain/entities/auth_user.dart';

/// Usuario de la sesión actual, en caliente.
///
/// Emite en caliente (la sesión guardada al abrir la app) y en cada
/// cambio: login, logout o retorno del OAuth de Google.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// ¿Hay sesión activa? (atajo cómodo para guards y dialogs)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authUserProvider).value != null;
});

/// Token JWT actual (para llamadas autenticadas a la API).
///
/// ⚠️ Reacciona a la sesión: sin el `watch(authUserProvider)` el token
/// quedaría congelado (casi siempre null) y /me nunca se llamaría.
final accessTokenProvider = Provider<String?>((ref) {
  ref.watch(authUserProvider);
  return ref.watch(authRepositoryProvider).accessToken;
});
