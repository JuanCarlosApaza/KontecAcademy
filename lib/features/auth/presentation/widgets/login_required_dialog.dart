import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/auth_providers.dart';

/// Guard de autenticación para acciones restringidas
/// (agregar al carrito, ir al pago, etc.).
///
/// Si hay sesión → true y el llamador continúa.
/// Si NO hay sesión → muestra el dialog "Inicia sesión para continuar" y,
/// si el usuario acepta, navega a /login recordando de dónde vino
/// (tras entrar, vuelve a la página original).
///
/// [redirect] permite forzar el destino tras el login (p. ej. el botón
/// "Continuar con el pago" del carrito vuelve DIRECTO a /checkout para
/// que la compra continúe, no al carrito).
Future<bool> ensureAuthenticated(
  BuildContext context,
  WidgetRef ref, {
  required String action,
  String? redirect,
}) async {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  if (isLoggedIn) return true;

  final goToLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Inicia sesión'),
      content: Text('Debes iniciar sesión para $action.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );

  if (goToLogin != true || !context.mounted) return false;

  // Recordamos la página actual para volver tras el login.
  final from = redirect ?? GoRouterState.of(context).uri.toString();
  context.go('/login?redirect=${Uri.encodeComponent(from)}');
  return false;
}
