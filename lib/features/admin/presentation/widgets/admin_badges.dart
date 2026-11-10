import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Re-exporta la fuente única de etiquetas de modalidad
/// (`core/format/course_labels.dart`, compartida con landing y cart).
export '../../../../core/format/course_labels.dart';

/// Etiqueta compacta con color propio (estados de curso, roles…).
/// El TEXTO siempre es negro (legible sobre los fondos claros);
/// el color semántico vive en el icono.
class AdminBadge extends StatelessWidget {
  const AdminBadge({
    super.key,
    required this.label,
    required this.background,
    this.foreground = AppColors.textDark,
    this.icon,
    this.iconColor,
  });

  final String label;

  /// Color del texto: negro por defecto (paleta blanco/negro del panel).
  final Color foreground;
  final Color background;
  final IconData? icon;

  /// Color del icono (el acento semántico); null = mismo que el texto.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? foreground),
            const SizedBox(width: 4),
          ],
          // Flexible + elipsis: en columnas angostas (tablas) el texto
          // se recorta en vez de desbordar el badge.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estados posibles de un curso (clave de la BD → etiqueta en español).
const kCourseStatusLabels = <String, String>{
  'draft': 'Borrador',
  'upcoming': 'Próximamente',
  'active': 'Activo',
  'inactive': 'Inactivo',
};

/// Badge del estado de un curso (texto negro + icono semántico).
AdminBadge courseStatusBadge(String status) {
  final (iconColor, background, icon) = switch (status) {
    'active' => (
      const Color(0xFF059669),
      const Color(0xFFECFDF5),
      Icons.check_circle_outline,
    ),
    'draft' => (
      const Color(0xFFB45309),
      const Color(0xFFFEF3C7),
      Icons.edit_note_outlined,
    ),
    'upcoming' => (
      const Color(0xFF0369A1),
      const Color(0xFFE0F2FE),
      Icons.schedule_outlined,
    ),
    _ => (
      AppColors.textMuted,
      const Color(0xFFF1F5F9),
      Icons.pause_circle_outline,
    ),
  };

  return AdminBadge(
    label: kCourseStatusLabels[status] ?? status,
    background: background,
    icon: icon,
    iconColor: iconColor,
  );
}

/// Badge del estado de cuenta de un usuario (activo / inactivo).
/// El "eliminar" del panel es este estado: nunca se borra el registro.
AdminBadge userStatusBadge(bool isActive) => AdminBadge(
  label: isActive ? 'Activo' : 'Inactivo',
  background: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
  icon: isActive ? Icons.check_circle_outline : Icons.block_outlined,
  iconColor: isActive ? const Color(0xFF059669) : AppColors.textMuted,
);

/// Estados de una INSCRIPCIÓN (clave de la BD → etiqueta en español).
/// Etiquetas cortas para que el badge quepa en columnas angostas.
const kEnrollmentStatusLabels = <String, String>{
  'pending_payment': 'En revisión',
  'approved': 'Con acceso',
  'rejected': 'Rechazado',
  'finished': 'Finalizado',
  'revoked': 'Revocado',
  'membership': 'Con membresía',
  'active': 'Activa',
  'expired': 'Vencida',
};

/// Badge del estado de una inscripción (acceso al curso).
AdminBadge enrollmentStatusBadge(String status) {
  final (iconColor, background, icon) = switch (status) {
    'approved' => (
      const Color(0xFF059669),
      const Color(0xFFECFDF5),
      Icons.check_circle_outline,
    ),
    'membership' => (
      const Color(0xFF7C3AED),
      const Color(0xFFF3E8FF),
      Icons.workspace_premium_outlined,
    ),
    'active' => (
      const Color(0xFF7C3AED),
      const Color(0xFFF3E8FF),
      Icons.workspace_premium_outlined,
    ),
    'finished' => (
      const Color(0xFF0369A1),
      const Color(0xFFE0F2FE),
      Icons.emoji_events_outlined,
    ),
    'pending_payment' => (
      const Color(0xFFB45309),
      const Color(0xFFFEF3C7),
      Icons.schedule_outlined,
    ),
    'rejected' => (
      const Color(0xFFDC2626),
      const Color(0xFFFEF2F2),
      Icons.cancel_outlined,
    ),
    'revoked' => (
      const Color(0xFFB91C1C),
      const Color(0xFFFEF2F2),
      Icons.block_outlined,
    ),
    'expired' => (
      AppColors.textMuted,
      const Color(0xFFF1F5F9),
      Icons.event_busy_outlined,
    ),
    _ => (
      AppColors.textMuted,
      const Color(0xFFF1F5F9),
      Icons.help_outline,
    ),
  };

  return AdminBadge(
    label: kEnrollmentStatusLabels[status] ?? status,
    background: background,
    icon: icon,
    iconColor: iconColor,
  );
}

/// Badge de rol de usuario (admin / teacher / student / sin rol).
AdminBadge roleBadge(String role) {
  final (iconColor, background) = switch (role) {
    'admin' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
    'teacher' => (const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
    'student' => (const Color(0xFF059669), const Color(0xFFECFDF5)),
    _ => (AppColors.textMuted, const Color(0xFFF1F5F9)),
  };

  return AdminBadge(
    label: kRoleLabels[role] ?? role,
    background: background,
    iconColor: iconColor,
  );
}

/// Roles del sistema (clave de la BD → etiqueta en español).
const kRoleLabels = <String, String>{
  'admin': 'admin',
  'teacher': 'docente',
  'student': 'estudiante',
};
