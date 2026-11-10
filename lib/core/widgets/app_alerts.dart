import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

import '../theme/app_colors.dart';

/// Avisos del sistema con [QuickAlert], con la paleta de la marca.
/// Único lugar que conoce el paquete: las features solo llaman a esto.
enum AppAlertType { success, error, warning, info }

/// Cierra una alerta de [QuickAlert.show] en el navigator CORRECTO.
///
/// `showGeneralDialog` (que QuickAlert usa por dentro) empuja la alerta
/// en el **root** navigator (`useRootNavigator: true` por defecto).
/// Hacer `Navigator.of(context).pop()` con el contexto de la pantalla
/// apunta al navigator anidado del `ShellRoute` de GoRouter (todas las
/// pantallas /admin/*) y elimina la PÁGINA del router: assert de
/// GoRouter ("popped the last page off of the stack") y pantalla en
/// blanco. Por eso el pop va siempre al root.
void _dismissAlert(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

Future<void> showAppAlert(
  BuildContext context, {
  required AppAlertType type,
  required String title,
  String? message,
}) {
  return QuickAlert.show(
    context: context,
    type: switch (type) {
      AppAlertType.success => QuickAlertType.success,
      AppAlertType.error => QuickAlertType.error,
      AppAlertType.warning => QuickAlertType.warning,
      AppAlertType.info => QuickAlertType.info,
    },
    title: title,
    text: message,
    confirmBtnText: 'Entendido',
    confirmBtnColor: AppColors.primary,
    backgroundColor: Colors.white,
    titleColor: AppColors.textDark,
    textColor: AppColors.textMuted,
    onConfirmBtnTap: () => _dismissAlert(context),
  );
}

/// Atajos con la paleta ya aplicada.
Future<void> showAppSuccess(
  BuildContext context, {
  required String title,
  String? message,
}) => showAppAlert(
  context,
  type: AppAlertType.success,
  title: title,
  message: message,
);

Future<void> showAppError(
  BuildContext context, {
  required String title,
  String? message,
}) => showAppAlert(
  context,
  type: AppAlertType.error,
  title: title,
  message: message,
);

Future<void> showAppWarning(
  BuildContext context, {
  required String title,
  String? message,
}) => showAppAlert(
  context,
  type: AppAlertType.warning,
  title: title,
  message: message,
);

/// Muestra el spinner modal de [QuickAlert] mientras corre una acción
/// contra la base de datos, para que la pantalla "no se corte" sin
/// feedback. Devuelve la función que cierra el spinner.
VoidCallback showAppLoading(BuildContext context, {String text = 'Guardando…'}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  QuickAlert.show(
    context: context,
    type: QuickAlertType.loading,
    title: text,
    barrierDismissible: false,
    showConfirmBtn: false,
    backgroundColor: Colors.white,
    titleColor: AppColors.textDark,
  );
  return () {
    if (navigator.mounted && navigator.canPop()) navigator.pop();
  };
}

/// Ejecuta [action] con el spinner modal de [showAppLoading] visible.
///
/// Devuelve el resultado de [action]; el spinner se cierra siempre,
/// haya éxito o error (el caller decide qué alerta mostrar después).
Future<T?> runWithAppLoading<T>(
  BuildContext context,
  Future<T> action, {
  String text = 'Guardando…',
}) async {
  final hide = showAppLoading(context, text: text);
  try {
    return await action;
  } finally {
    hide();
  }
}

/// Confirmación de acción destructiva con [QuickAlert] (warning).
///
/// Devuelve true si el usuario confirma.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmText = 'Sí, continuar',
  String cancelText = 'Cancelar',
}) async {
  final result = await QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: title,
    text: message,
    confirmBtnText: confirmText,
    cancelBtnText: cancelText,
    confirmBtnColor: AppColors.primary,
    backgroundColor: Colors.white,
    titleColor: AppColors.textDark,
    textColor: AppColors.textMuted,
    // Mismo criterio que showAppAlert: la alerta vive en el root
    // navigator, así que el pop va al root (ver _dismissAlert).
    onConfirmBtnTap: () => Navigator.of(context, rootNavigator: true).pop(true),
    onCancelBtnTap: () => Navigator.of(context, rootNavigator: true).pop(false),
  );
  return result == true;
}
