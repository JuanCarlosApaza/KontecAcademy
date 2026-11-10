import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth_providers.dart';
import '../../../admin/presentation/viewmodels/admin_providers.dart';

/// PUENTE de entrada tras autenticarse: /auth-entrar
///
/// Se usa cuando un usuario CON sesión aterriza en /login o /registro
/// (típico al volver del login con Google, que recarga la app).
/// Comprueba roles y permisos en el backend y reenvía:
///  * tiene permisos del panel (rol admin incluido) → /admin
///  * el resto → / (inicio)
/// Si algo falla (backend caído, sin datos), va al inicio SIN errores.
class AuthEntryScreen extends ConsumerWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ¿Sigue sin sesión? (ej: sesión expirada) → volver al login.
    ref.listen(authUserProvider, (previous, next) {
      if (!next.isLoading && next.value == null) {
        context.go('/login');
      }
    });

    // Roles + permisos listos → decidir destino.
    ref.listen(sessionAccessProvider, (previous, next) {
      if (next.hasError) {
        context.go('/');
        return;
      }
      final access = next.value;
      if (access == null) return;
      context.go(access.hasAnyPermission ? '/admin' : '/');
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
