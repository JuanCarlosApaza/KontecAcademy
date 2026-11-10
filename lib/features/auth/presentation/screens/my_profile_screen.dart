import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../admin/domain/entities/student_profile.dart';
import '../../../admin/presentation/viewmodels/admin_providers.dart';
import '../../../admin/presentation/widgets/admin_badges.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../viewmodels/auth_providers.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Iniciales a partir de un nombre (o del email si no hay nombre).
String _initialsOf(String name) {
  final source = name.trim();
  if (source.isEmpty) return '?';
  final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final words = source.contains('@') && source.split(RegExp(r'\s+')).length == 1
      ? [source]
      : parts.toList();
  if (words.isEmpty) return '?';
  if (source.contains('@') && words.length == 1) {
    return words.first[0].toUpperCase();
  }
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}

/// MI PERFIL: /perfil
///
/// Vista del USUARIO sobre su propia cuenta: nombre, correo, teléfono,
/// nacionalidad, fecha de registro y sus cursos inscritos con el estado
/// de cada inscripción. Sin acciones de administrador (no puede quitar
/// accesos).
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    // Nombre de respaldo desde la sesión (usuarios que solo se
    // registraron y aún no tienen fila en public.users).
    final authName = ref.watch(authUserProvider).value?.displayName;

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _ErrorView(
                    message: 'No se pudo cargar tu perfil: $error',
                    onRetry: () => ref.invalidate(myProfileProvider),
                  ),
                  data: (profile) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(
                        profile: profile,
                        fallbackName: authName,
                      ),
                      const SizedBox(height: 18),
                      _EnrollmentsCard(enrollments: profile.enrollments),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

/// Banda superior oscura con el título de la sección.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF1F1A17)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: width < 800 ? 24 : 72,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mi perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Tus datos de cuenta y el estado de los cursos en los que '
              'estás inscrito.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de cabecera con los datos de la cuenta.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile, this.fallbackName});

  final StudentProfile profile;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final displayName =
        profile.fullName.isNotEmpty
        ? profile.fullName
        : (fallbackName?.isNotEmpty == true ? fallbackName! : profile.email);
    final initials = _initialsOf(displayName);

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
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
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
                        displayName,
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
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
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

/// Lista de cursos inscritos con su estado (sin acciones de admin).
class _EnrollmentsCard extends StatelessWidget {
  const _EnrollmentsCard({required this.enrollments});

  final List<StudentEnrollment> enrollments;

  @override
  Widget build(BuildContext context) {
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
          if (enrollments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Todavía no te has inscrito a ningún curso. Explora el '
                'catálogo para empezar.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else
            for (final enrollment in enrollments) ...[
              _EnrollmentRow(enrollment: enrollment),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
        ],
      ),
    );
  }
}

/// Fila de una inscripción: curso, fecha y estado (solo lectura).
class _EnrollmentRow extends StatelessWidget {
  const _EnrollmentRow({required this.enrollment});

  final StudentEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
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
            ),
          ),
          const SizedBox(width: 12),
          enrollmentStatusBadge(enrollment.status),
        ],
      ),
    );
  }
}

/// Error de carga + reintentar.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
