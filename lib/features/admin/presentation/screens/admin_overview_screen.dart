import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../../landing/presentation/viewmodels/courses_viewmodel.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/new_course.dart';
import '../viewmodels/admin_courses_viewmodel.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_course_form.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_price_cell.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// RESUMEN DEL PANEL: /admin
///
/// Tarjetas KPI, gráfico de horas por curso y la tabla del catálogo
/// con buscador y acceso rápido a "Nuevo curso".
class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Carga KPIs + estudiantes la primera vez que se entra al panel.
    Future.microtask(() => ref.read(adminViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(adminViewModelProvider);
    final stats = panel.stats;
    final courses = ref.watch(coursesViewModelProvider).courses;

    if (panel.isLoading && stats == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AdminPage(
      title: 'Resumen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (panel.error != null) ...[
            _ErrorBanner(message: panel.error!),
            const SizedBox(height: 16),
          ],
          // ── Tarjetas KPI ────────────────────────────────────────
          _KpiGrid(stats: stats),
          const SizedBox(height: 20),

          // ── Gráfico ─────────────────────────────────────────────
          if (courses.isNotEmpty) ...[
            _EnrollmentsChart(courses: courses.take(6).toList()),
            const SizedBox(height: 20),
          ],

          // ── Tabla del catálogo ──────────────────────────────────
          AdminTableCard<TrainingCourse>(
            title: 'Cursos del catálogo',
            subtitle: '${courses.length} cursos en la plataforma',
            items: courses,
            searchHint: 'Buscar por título o categoría…',
            searchText: (c) => '${c.title} ${c.category}',
            emptyMessage:
                'Aún no hay cursos. Crea el primero con "Nuevo curso".',
            rowsPerPage: 5,
            actions: [
              TextButton.icon(
                onPressed: () => context.go('/admin/cursos'),
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Ver todos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateCourseDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo curso'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            columns: [
              AdminColumn<TrainingCourse>(
                label: 'Curso',
                width: 320,
                sortValue: (c) => c.title.toLowerCase(),
                cell: (c) => Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              AdminColumn<TrainingCourse>(
                label: 'Modalidad',
                sortValue: (c) => courseModalityLabel(c.modality),
                cell: (c) => Text(
                  courseModalityLabel(c.modality),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              AdminColumn<TrainingCourse>(
                label: 'Horas',
                centered: true,
                width: 90,
                sortValue: (c) => c.hours,
                cell: (c) => Text('${c.hours} h'),
              ),
              AdminColumn<TrainingCourse>(
                label: 'Precio',
                sortValue: (c) => c.price,
                cell: (c) => AdminPriceCell(
                  price: c.price,
                  compareAt: c.compareAtPrice,
                ),
              ),
              AdminColumn<TrainingCourse>(
                label: 'Estado',
                width: 140,
                sortValue: (c) => c.status,
                cell: (c) => courseStatusBadge(c.status),
              ),
              AdminColumn<TrainingCourse>(
                label: 'Acciones',
                width: 110,
                isActions: true,
                cell: (c) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminActionButton(
                      tooltip: 'Editar',
                      icon: Icons.edit_outlined,
                      onPressed: () => _openEditCourseDialog(c),
                    ),
                    if (c.status == 'inactive')
                      AdminActionButton(
                        tooltip: 'Reactivar curso',
                        icon: Icons.restore,
                        onPressed: () => _toggleCourseStatus(c, activate: true),
                      )
                    else
                      AdminActionButton(
                        tooltip: 'Desactivar curso',
                        icon: Icons.visibility_off_outlined,
                        destructive: true,
                        onPressed: () =>
                            _toggleCourseStatus(c, activate: false),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Abre el diálogo con el formulario de creación de curso.
  Future<void> _openCreateCourseDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nuevo curso',
      subtitle:
          'Se agrega al catálogo de la plataforma. Los cursos en '
          '"Activo" son visibles para todo el sitio.',
      width: 680,
      child: const AdminCourseForm(),
    );

    if (created != true || !mounted) return;
    final title =
        ref.read(adminCoursesViewModelProvider).lastCreatedTitle ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title.isEmpty ? 'Curso creado ✅' : 'Curso creado: "$title" ✅',
        ),
      ),
    );
  }

  /// Abre el diálogo con el formulario precargado para editar el curso.
  Future<void> _openEditCourseDialog(TrainingCourse course) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar curso',
      subtitle: course.title,
      width: 680,
      child: AdminCourseForm(initial: course),
    );

    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Curso "${course.title}" actualizado ✅')),
    );
  }

  /// Desactivar/reactivar: es un CAMBIO DE ESTADO (borrado lógico),
  /// nunca se elimina el registro de la BD.
  Future<void> _toggleCourseStatus(
    TrainingCourse course, {
    required bool activate,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: activate ? Icons.restore : Icons.visibility_off_outlined,
      title: activate ? 'Reactivar curso' : 'Desactivar curso',
      message: activate
          ? 'El curso volverá a estar disponible en el catálogo público.'
          : 'El curso dejará de mostrarse en el sitio público. '
                'No se elimina ningún dato: podrás reactivarlo cuando quieras.',
      confirmLabel: activate ? 'Reactivar' : 'Desactivar',
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(adminCoursesViewModelProvider.notifier)
        .update(
          course.id,
          NewCourse(
            title: course.title,
            description: course.description.isEmpty ? null : course.description,
            imageUrl: course.imageUrl,
            categoryId: course.categoryId,
            modality: course.modality,
            totalHours: course.hours,
            totalWeeks: course.totalWeeks,
            price: course.price,
            compareAtPrice: course.compareAtPrice,
            status: activate ? 'active' : 'inactive',
            professorBio: course.professorBio,
            teachingMethod: course.teachingMethod,
            targetAudience: course.targetAudience,
            certificateInfo: course.certificateInfo,
            careerOpportunities: course.careerOpportunities,
          ),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? activate
                    ? 'Curso reactivado ✅'
                    : 'Curso desactivado (sigue en la BD) ✅'
              : 'No se pudo cambiar el estado del curso',
        ),
      ),
    );
  }
}

/// Rejilla responsiva de tarjetas KPI (5 indicadores).
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});

  final AdminStats? stats;

  @override
  Widget build(BuildContext context) {
    final kpis = <({String label, String value, IconData icon, Color color})>[
      (
        label: 'Estudiantes',
        value: '${stats?.students ?? 0}',
        icon: Icons.people_outline,
        color: const Color(0xFF6366F1),
      ),
      (
        label: 'Cursos',
        value: '${stats?.courses ?? 0}',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF0EA5E9),
      ),
      (
        label: 'Inscripciones',
        value: '${stats?.enrollments ?? 0}',
        icon: Icons.school_outlined,
        color: AppColors.primary,
      ),
      (
        label: 'Pagos por aprobar',
        value: '${stats?.pendingPayments ?? 0}',
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFFF59E0B),
      ),
      (
        label: 'Ingresos (USD)',
        value: _money(stats?.revenue ?? 0),
        icon: Icons.payments_outlined,
        color: const Color(0xFF10B981),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final kpi in kpis)
              SizedBox(
                width: cardWidth < 180
                    ? 180
                    : cardWidth > 280
                    ? 280
                    : cardWidth,
                child: _StatCard(
                  label: kpi.label,
                  value: kpi.value,
                  icon: kpi.icon,
                  color: kpi.color,
                ),
              ),
          ],
        );
      },
    );
  }

  static String _money(double value) {
    final fixed = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    return fixed.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
  }
}

/// Tarjeta KPI con icono de color, valor grande y etiqueta.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: adminCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de barras simple (CustomPaint) con la duración por curso.
class _EnrollmentsChart extends StatelessWidget {
  const _EnrollmentsChart({required this.courses});

  final List<TrainingCourse> courses;

  @override
  Widget build(BuildContext context) {
    final maxHours = courses.fold<int>(
      1,
      (max, c) => c.hours > max ? c.hours : max,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: adminCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horas totales por curso',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final course in courses)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${course.hours}h',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // La barra ocupa el espacio RESTANTE de la
                          // columna (Expanded = altura finita). Sin
                          // Expanded, el FractionallySizedBox recibiría
                          // altura infinita del Column y el layout
                          // revienta ("BoxConstraints forces an infinite
                          // height"), rompiendo toda la pantalla.
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: (course.hours / maxHours).toDouble(),
                              ),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) => Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: (t * 0.85 + 0.05).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withValues(
                                            alpha: 0.55,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: Text(
                              course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }
}
