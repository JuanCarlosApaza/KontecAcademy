import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/course_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../../data/datasources/my_membership_remote_datasource.dart';
import '../../domain/entities/enrolled_course.dart';
import '../viewmodels/my_courses_providers.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// MIS CURSOS: /mis-cursos
///
/// Lista las capacitaciones del estudiante según el estado de su
/// inscripción:
///  * `approved`/`finished` → tarjeta con botón "Entrar al curso".
///  * `pending_payment` → aviso "pago en verificación" (el admin aún
///    no ha revisado el pago manualmente).
///  * `rejected` → aviso de pago rechazado.
class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myCoursesProvider);

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
                constraints: const BoxConstraints(maxWidth: 1280),
                child: coursesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _ErrorView(
                    onRetry: () => ref.invalidate(myCoursesProvider),
                  ),
                  data: (courses) => _CourseList(courses: courses),
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
            'Mis cursos',
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
              'Tus capacitaciones aprobadas en un solo lugar: entra al '
              'curso cuando quieras. Si acabas de solicitar uno, aquí '
              'verás el estado de tu pago.',
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

/// Contenido según los estados de las inscripciones.
class _CourseList extends ConsumerWidget {
  const _CourseList({required this.courses});

  final List<EnrolledCourse> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (courses.isEmpty) return const _EmptyState();

    final access = [
      for (final c in courses)
        if (c.hasAccess) c,
    ];
    final pending = [
      for (final c in courses)
        if (c.isPendingReview) c,
    ];
    final rejected = [
      for (final c in courses)
        if (c.status == 'rejected') c,
    ];
    final revoked = [
      for (final c in courses)
        if (c.isRevoked) c,
    ];

    // Membresía vigente: banner + el grid ya incluye TODO el catálogo
    // (el servidor lo devuelve con status 'membership').
    final membership = ref.watch(myMembershipProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (membership != null) ...[
          _NoticeCard(
            icon: Icons.workspace_premium_outlined,
            iconColor: const Color(0xFF7C3AED),
            background: const Color(0xFFF3E8FF),
            title: 'Membresía ${membership.planName} activa',
            message:
                'Tienes acceso a todos los cursos hasta el '
                '${membership.endDateLabel}. Aparecen todos aquí con el '
                'badge de membresía.',
          ),
          const SizedBox(height: 16),
        ],
        if (pending.isNotEmpty) ...[
          _NoticeCard(
            icon: Icons.schedule,
            iconColor: const Color(0xFFD97706),
            background: const Color(0xFFFFFBEB),
            title: pending.length == 1
                ? 'Pago en verificación'
                : '${pending.length} pagos en verificación',
            message: pending.length == 1
                ? 'Solicistaste "${pending.first.title}". Cuando el pago '
                      'sea revisado y aprobado, el curso aparecerá aquí con '
                      'acceso.'
                : 'Solicistaste: ${pending.map((c) => c.title).join(' · ')}. '
                      'Aparecerán aquí con acceso cuando el pago sea aprobado.',
          ),
          const SizedBox(height: 16),
        ],
        if (rejected.isNotEmpty) ...[
          _NoticeCard(
            icon: Icons.info_outline,
            iconColor: const Color(0xFFDC2626),
            background: const Color(0xFFFEF2F2),
            title: rejected.length == 1
                ? 'Pago rechazado'
                : '${rejected.length} pagos rechazados',
            message: rejected.length == 1
                ? 'El pago de "${rejected.first.title}" fue rechazado. '
                      'Puedes solicitar el curso de nuevo desde el catálogo.'
                : 'Pagos rechazados: '
                      '${rejected.map((c) => c.title).join(' · ')}. '
                      'Puedes solicitarlos de nuevo desde el catálogo.',
          ),
          const SizedBox(height: 16),
        ],
        if (revoked.isNotEmpty) ...[
          _NoticeCard(
            icon: Icons.block_outlined,
            iconColor: const Color(0xFFB91C1C),
            background: const Color(0xFFFFF5F5),
            title: revoked.length == 1
                ? 'Acceso revocado'
                : '${revoked.length} accesos revocados',
            message: revoked.length == 1
                ? 'El acceso a "${revoked.first.title}" fue retirado por '
                      'un administrador. Si crees que es un error o ya '
                      'regularizaste tu pago, contacta a soporte.'
                : 'El acceso a estos cursos fue retirado por un '
                      'administrador: '
                      '${revoked.map((c) => c.title).join(' · ')}. '
                      'Contacta a soporte si ya regularizaste tu pago.',
          ),
          const SizedBox(height: 16),
        ],
        if (access.isEmpty)
          const _AccessPendingState()
        else ...[
          Text(
            access.length == 1
                ? '1 capacitación disponible'
                : '${access.length} capacitaciones disponibles',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              // 380 deja holgura para la barra de progreso y para
              // textos crecidos (escala de fuente ≥ 1.3).
              mainAxisExtent: 380,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: access.length,
            itemBuilder: (context, index) =>
                _EnrolledCard(course: access[index]),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta de un curso con acceso (+ botón "Entrar al curso").
class _EnrolledCard extends StatelessWidget {
  const _EnrolledCard({required this.course});

  final EnrolledCourse course;

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
          Expanded(child: _Cover(imageUrl: course.imageUrl)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                // Wrap: en celdas angostas el chip y la fecha pasan a
                // dos líneas en vez de desbordar (spaceBetween = a la
                // derecha cuando caben en una sola línea).
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ModalityChip(label: courseModalityLabel(course.modality)),
                    if (course.enrolledAt != null)
                      Text(
                        'Solicitado ${_formatDate(course.enrolledAt!)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (course.hasAccess && course.totalLessons > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFF6A00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${course.completedLessons} de ${course.totalLessons} '
                    'lecciones',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // El aula es la única pantalla con el temario y el
                    // contenido; la ficha del curso es la de venta.
                    onPressed: () =>
                        context.go('/capacitaciones/${course.courseId}/aula'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Entrar al curso'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portada del curso (o placeholder si no hay imagen).
class _Cover extends StatelessWidget {
  const _Cover({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.surface,
      child: Icon(Icons.school_outlined, size: 40, color: AppColors.textMuted),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Etiqueta compacta de modalidad.
class _ModalityChip extends StatelessWidget {
  const _ModalityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

/// Aviso de estado (pago en revisión / rechazado).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiene solicitudes, pero todavía ningún curso con acceso.
class _AccessPendingState extends StatelessWidget {
  const _AccessPendingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Tus cursos aprobados aparecerán aquí con su botón de acceso.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
      ),
    );
  }
}

/// Cero inscripciones: invita a explorar el catálogo.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no has solicitado ningún curso.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explora el catálogo y solicita la capacitación que quieras:\n'
            'la verás aquí en cuanto tu pago sea aprobado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/capacitaciones'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Explorar capacitaciones'),
          ),
        ],
      ),
    );
  }
}

/// Error de carga + botón reintentar.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No se pudieron cargar tus cursos.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
