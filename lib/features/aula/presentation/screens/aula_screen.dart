import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../../domain/entities/course_curriculum.dart';
import '../viewmodels/curriculum_providers.dart';
import '../widgets/lesson_content.dart';

/// AULA: /capacitaciones/:id/aula
///
/// Temario del curso para el estudiante. El backend calcula el acceso
/// desde su inscripción, así que la misma pantalla sirve para:
///  * `full`     → temario navegable + contenido + progreso.
///  * `pending`  → aviso "pago en verificación" (sin contenido).
///  * `rejected` → aviso "pago rechazado".
///  * `none`     → invita a iniciar sesión.
class AulaScreen extends ConsumerWidget {
  const AulaScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider(courseId));

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          curriculumAsync.when(
            loading: () => const _LoadingView(),
            error: (error, _) => _ErrorView(
              message: error is Failure ? error.message : null,
              onRetry: () => ref.invalidate(curriculumProvider(courseId)),
            ),
            data: (curriculum) => curriculum == null
                ? const _NotFoundView()
                : curriculum.hasAccess
                ? _AulaView(curriculum: curriculum)
                : _AccessGateView(curriculum: curriculum, courseId: courseId),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

/// Temario navegable + contenido de la lección seleccionada.
class _AulaView extends ConsumerStatefulWidget {
  const _AulaView({required this.curriculum});

  final CourseCurriculum curriculum;

  @override
  ConsumerState<_AulaView> createState() => _AulaViewState();
}

class _AulaViewState extends ConsumerState<_AulaView> {
  String? _selectedLessonId;

  CourseCurriculum get curriculum => widget.curriculum;

  @override
  void didUpdateWidget(covariant _AulaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El temario se recarga tras marcar una lección: si la seleccionada
    // desapareció (o cambió de curso), se vuelve a la primera.
    if (oldWidget.curriculum != curriculum && !_contains(_selectedLessonId)) {
      _selectedLessonId = null;
    }
  }

  bool _contains(String? lessonId) =>
      lessonId != null && curriculum.lessons.any((l) => l.id == lessonId);

  CurriculumLesson? get _selected {
    final lessons = curriculum.lessons;
    if (lessons.isEmpty) return null;
    for (final lesson in lessons) {
      if (lesson.id == _selectedLessonId) return lesson;
    }
    return lessons.first;
  }

  void _select(String lessonId) => setState(() => _selectedLessonId = lessonId);

  Future<void> _toggle(CurriculumLesson lesson) async {
    final ok = await ref
        .read(lessonProgressViewModelProvider.notifier)
        .toggle(
          courseId: curriculum.courseId,
          lessonId: lesson.id,
          completed: !lesson.isCompleted,
        );
    if (!ok || !mounted) return;
    // La recarga del temario llega por el provider; aquí solo se avisa.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lesson.isCompleted
              ? 'Lección marcada como pendiente'
              : 'Lección completada ✅',
        ),
      ),
    );
  }

  /// Auto-marca al terminar el video embebido (estilo Tutor LMS):
  /// solo completa, nunca desmarca, y no avisa si ya estaba hecha.
  Future<void> _markCompleted(CurriculumLesson lesson) async {
    if (lesson.isCompleted || !mounted) return;
    await ref
        .read(lessonProgressViewModelProvider.notifier)
        .toggle(
          courseId: curriculum.courseId,
          lessonId: lesson.id,
          completed: true,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lección completada ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final lesson = _selected;

    final sidebar = _CurriculumOutline(
      curriculum: curriculum,
      selectedLessonId: lesson?.id,
      onSelect: _select,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 32, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AulaHeader(curriculum: curriculum),
          const SizedBox(height: 16),
          if (narrow) ...[
            sidebar,
            const SizedBox(height: 16),
            if (lesson != null)
              _LessonPanel(
                key: ValueKey(lesson.id),
                lesson: lesson,
                curriculum: curriculum,
                onSelect: _select,
                onToggle: () => _toggle(lesson),
                onVideoEnded: () => _markCompleted(lesson),
              ),
          ] else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 340, child: sidebar),
                  const SizedBox(width: 24),
                  Expanded(
                    child: lesson == null
                        ? const SizedBox.shrink()
                        : _LessonPanel(
                            key: ValueKey(lesson.id),
                            lesson: lesson,
                            curriculum: curriculum,
                            onSelect: _select,
                            onToggle: () => _toggle(lesson),
                            onVideoEnded: () => _markCompleted(lesson),
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

/// Banda superior: título del curso + progreso.
class _AulaHeader extends StatelessWidget {
  const _AulaHeader({required this.curriculum});

  final CourseCurriculum curriculum;

  @override
  Widget build(BuildContext context) {
    final completed = curriculum.completedLessons;
    final total = curriculum.totalLessons;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF1F1A17)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            curriculum.courseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (total > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: curriculum.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFF6A00),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completed de $total lecciones',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Este curso aún no tiene lecciones publicadas.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13.5,
              ),
            ),
        ],
      ),
    );
  }
}

/// Temario: módulos con sus lecciones y estado de cada una.
class _CurriculumOutline extends StatelessWidget {
  const _CurriculumOutline({
    required this.curriculum,
    required this.selectedLessonId,
    required this.onSelect,
  });

  final CourseCurriculum curriculum;
  final String? selectedLessonId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (curriculum.modules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'El docente aún no publicó el temario de este curso.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
        ),
      );
    }

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
          for (final module in curriculum.modules) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: AppColors.surface,
              child: Text(
                module.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            for (final lesson in module.lessons)
              _LessonTile(
                lesson: lesson,
                selected: lesson.id == selectedLessonId,
                onTap: () => onSelect(lesson.id),
              ),
          ],
        ],
      ),
    );
  }
}

/// Fila del temario: número, título y estado de la lección.
class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.selected,
    required this.onTap,
  });

  final CurriculumLesson lesson;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF4EC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                lesson.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: lesson.isCompleted
                    ? const Color(0xFF16A34A)
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel de la lección: contenido + acciones.
class _LessonPanel extends StatelessWidget {
  const _LessonPanel({
    super.key,
    required this.lesson,
    required this.curriculum,
    required this.onSelect,
    required this.onToggle,
    this.onVideoEnded,
  });

  final CurriculumLesson lesson;
  final CourseCurriculum curriculum;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggle;

  /// Auto-marca la lección cuando termina el video embebido.
  final VoidCallback? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    final siblings = curriculum.lessons;
    final index = siblings.indexWhere((item) => item.id == lesson.id);
    final previous = index > 0 ? siblings[index - 1] : null;
    final next = index >= 0 && index < siblings.length - 1
        ? siblings[index + 1]
        : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lesson.contentType,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            LessonContent(lesson: lesson, onVideoEnded: onVideoEnded),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      lesson.isCompleted
                          ? Icons.restart_alt
                          : Icons.check_rounded,
                    ),
                    label: Text(
                      lesson.isCompleted
                          ? 'Marcar como pendiente'
                          : 'Marcar como completada',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: lesson.isCompleted
                          ? AppColors.surface
                          : const Color(0xFF16A34A),
                      foregroundColor: lesson.isCompleted
                          ? AppColors.textDark
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _NavButton(
                  icon: Icons.arrow_back_rounded,
                  enabled: previous != null,
                  onTap: previous == null ? null : () => onSelect(previous.id),
                ),
                const SizedBox(width: 6),
                _NavButton(
                  icon: Icons.arrow_forward_rounded,
                  enabled: next != null,
                  onTap: next == null ? null : () => onSelect(next.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColors.surface : const Color(0xFFF3F4F6),
        foregroundColor: enabled ? AppColors.textDark : AppColors.textMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Gate de acceso: el pago manda. Sin aprobación no hay temario.
class _AccessGateView extends StatelessWidget {
  const _AccessGateView({required this.curriculum, required this.courseId});

  final CourseCurriculum curriculum;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final (
      icon,
      color,
      background,
      title,
      message,
    ) = switch (curriculum.access) {
      'pending' => (
        Icons.schedule,
        const Color(0xFFD97706),
        const Color(0xFFFFFBEB),
        'Pago en verificación',
        'Solicistaste "${curriculum.courseTitle}". Cuando el pago sea '
            'revisado y aprobado por el equipo, el contenido del curso '
            'aparecerá aquí.',
      ),
      'rejected' => (
        Icons.info_outline,
        const Color(0xFFDC2626),
        const Color(0xFFFEF2F2),
        'Pago rechazado',
        'El pago de "${curriculum.courseTitle}" fue rechazado. Puedes '
            'solicitar el curso de nuevo desde el catálogo.',
      ),
      _ => (
        Icons.lock_outline,
        AppColors.textMuted,
        AppColors.surface,
        'Inicia sesión para ver tu curso',
        'Esta capacitación es parte de tu inscripción. Inicia sesión con '
            'la cuenta con la que la solicitaste para acceder al contenido.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go('/mis-cursos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Ir a Mis cursos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 96),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// El curso no existe (404 de la API).
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 14),
          const Text(
            'No encontramos ese curso',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/capacitaciones'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver capacitaciones'),
          ),
        ],
      ),
    );
  }
}

/// Error de carga + botón reintentar.
class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(
            message ?? 'No se pudo cargar el curso.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
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
