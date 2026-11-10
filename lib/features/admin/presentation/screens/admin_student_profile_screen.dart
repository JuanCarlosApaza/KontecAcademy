import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../admin_injector.dart';
import '../../domain/entities/student_profile.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// PERFIL DEL ESTUDIANTE: /admin/estudiantes/:id
///
/// Muestra los datos del estudiante y sus cursos inscritos. Desde aquí
/// el admin puede QUITAR o RESTAURAR el acceso a un curso (cambia el
/// estado de la inscripción), p. ej. si no terminó de pagar.
class AdminStudentProfileScreen extends ConsumerWidget {
  const AdminStudentProfileScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentProfileProvider(studentId));

    return AdminPage(
      title: 'Perfil del estudiante',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _LoadError(
          message: 'No se pudo cargar el perfil: $error',
          onRetry: () => ref.invalidate(studentProfileProvider(studentId)),
        ),
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(profile: profile),
            const SizedBox(height: 18),
            _EnrollmentsCard(
              profile: profile,
              onChanged: () =>
                  ref.invalidate(studentProfileProvider(studentId)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera con los datos del estudiante.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar con iniciales.
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    userStatusBadge(profile.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _InfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: profile.phone ?? '—',
                    ),
                    _InfoItem(
                      icon: Icons.public_outlined,
                      label: 'Nacionalidad',
                      value: profile.nationality ?? '—',
                    ),
                    _InfoItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Registro',
                      value: profile.createdAt == null
                          ? '—'
                          : _formatDate(profile.createdAt!),
                    ),
                    _InfoItem(
                      icon: Icons.school_outlined,
                      label: 'Cursos',
                      value: '${profile.enrollments.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dato suelto de la cabecera (icono + etiqueta + valor).
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Lista de cursos inscritos con la acción de acceso por fila.
class _EnrollmentsCard extends ConsumerWidget {
  const _EnrollmentsCard({required this.profile, required this.onChanged});

  final StudentProfile profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: const Text(
              'Cursos inscritos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (profile.enrollments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Este estudiante aún no tiene cursos inscritos.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            for (final enrollment in profile.enrollments) ...[
              _EnrollmentRow(
                enrollment: enrollment,
                studentId: profile.id,
                studentName: profile.fullName,
                onChanged: onChanged,
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
        ],
      ),
    );
  }
}

/// Fila de una inscripción: curso, estado, fecha y acción de acceso.
class _EnrollmentRow extends ConsumerWidget {
  const _EnrollmentRow({
    required this.enrollment,
    required this.studentId,
    required this.studentName,
    required this.onChanged,
  });

  final StudentEnrollment enrollment;
  final String studentId;
  final String studentName;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revoked = enrollment.isRevoked;
    // Quitar/restaurar acceso usa PATCH /admin/students/.../enrollments.
    final canManage = ref.watch(permissionProvider('students:manage'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enrollment.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                enrollment.enrolledAt == null
                    ? 'Sin fecha'
                    : 'Inscrito el ${_formatDate(enrollment.enrolledAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );

          final badge = enrollmentStatusBadge(enrollment.status);

          final button = !canManage
              ? null
              : revoked
              ? OutlinedButton.icon(
                  onPressed: () => _toggleAccess(context, ref, revoke: false),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Restaurar acceso'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _toggleAccess(context, ref, revoke: true),
                  icon: const Icon(Icons.block_outlined, size: 16),
                  label: const Text('Quitar acceso'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                );

          // En filas angostas badge y botón pasan a su propia línea:
          // en una Row el título queda en ~17 px o desborda.
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [badge, ?button],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              badge,
              const SizedBox(width: 12),
              ?button,
            ],
          );
        },
      ),
    );
  }

  /// Quita o restaura el acceso con confirmación + spinner + alerta.
  Future<void> _toggleAccess(
    BuildContext context,
    WidgetRef ref, {
    required bool revoke,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: revoke ? Icons.block_outlined : Icons.restore,
      title: revoke ? 'Quitar acceso' : 'Restaurar acceso',
      message: revoke
          ? '$studentName dejará de ver el contenido de '
                '"${enrollment.title}" en el aula. No se elimina ningún '
                'dato ni se modifica su pago: puedes restaurarlo cuando '
                'quieras.'
          : '$studentName volverá a tener acceso a "${enrollment.title}".',
      confirmLabel: revoke ? 'Quitar acceso' : 'Restaurar',
    );
    if (!confirmed || !context.mounted) return;

    final ok = await runWithAppLoading(
      context,
      ref
          .read(setEnrollmentAccessProvider)
          .call(
            SetEnrollmentAccessParams(
              studentId: studentId,
              courseId: enrollment.courseId,
              revoke: revoke,
            ),
          ),
      text: revoke ? 'Quitando acceso…' : 'Restaurando acceso…',
    );
    if (!context.mounted) return;

    final (success, failure) = ok ?? (false, null);
    if (success) {
      onChanged();
      await showAppSuccess(
        context,
        title: revoke ? 'Acceso quitado' : 'Acceso restaurado',
        message: revoke
            ? '"${enrollment.title}" quedó sin acceso para este estudiante.'
            : '"${enrollment.title}" ya tiene acceso de nuevo.',
      );
    } else {
      await showAppError(
        context,
        title: 'No se pudo cambiar el acceso',
        message: failure?.message ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }
}

/// Error de carga + reintentar.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 38, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
