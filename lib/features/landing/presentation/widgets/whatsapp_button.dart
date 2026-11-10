import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Botón flotante de WhatsApp compartido por todas las páginas.
/// TODO(back): sustituir por el número real de la cuenta (abrir wa.me).
class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.whatsapp,
      foregroundColor: Colors.white,
      tooltip: 'Escríbenos por WhatsApp',
      onPressed: () {},
      child: const Icon(Icons.chat),
    );
  }
}
