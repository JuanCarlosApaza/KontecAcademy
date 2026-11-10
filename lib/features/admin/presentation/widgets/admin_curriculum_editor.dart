import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../domain/entities/admin_curriculum.dart';
import '../../domain/entities/new_module.dart';
import '../viewmodels/admin_curriculum_viewmodel.dart';
import '../viewmodels/admin_providers.dart';
import 'admin_dialog.dart';
import 'admin_lesson_editor.dart';
import 'admin_table.dart';

/// Borde estándar de los campos del editor de temario.
OutlineInputBorder _inputBorder({Color color = const Color(0xFFE5E7EB)}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

/// EDITOR DE TEMARIO — se abre desde "Temario" en la tabla de cursos.
///
/// Gestiona los módulos de un curso y sus lecciones: alta, edición,
/// borrado (con confirmación) y reorden con ↑/↓. Todo lo que se guarda
/// se vuelve a leer del servidor, que es quien asigna los `orderIndex`.
class AdminCurriculumEditor extends ConsumerStatefulWidget {
  const AdminCurriculumEditor({super.key, required this.course});

  final TrainingCourse course;

  @override
  ConsumerState<AdminCurriculumEditor> createState() =>
      _AdminCurriculumEditorState();
}

class _AdminCurriculumEditorState
    extends ConsumerState<AdminCurriculumEditor> {
  @override
  void initState() {
    super.initState();
    // El temario se pide al abrir el diálogo; el estado vive en el
    // ViewModel para sobrevivir a recargas del catálogo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCurriculumViewModelProvider.notifier).load(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCurriculumViewModelProvider);

    if (state.isLoading && state.modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = state.error;
    if (error != null) {
      return _LoadError(
        message: error.message,
        onRetry: () => ref
            .read(adminCurriculumViewModelProvider.notifier)
            .load(widget.course.id),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(
          state: state,
          onReload: () => ref
              .read(adminCurriculumViewModelProvider.notifier)
              .load(widget.course.id),
        ),
        const SizedBox(height: 16),
        for (final module in state.modules) ...[
          _ModuleCard(module: module, courseId: state.courseId ?? widget.course.id),
          const SizedBox(height: 12),
        ],
        if (state.modules.isEmpty) const _EmptyCurriculum(),
        const SizedBox(height: 12),
        const _ModuleForm(),
      ],
    );
  }
}

/// Resumen del temario: módulos, lecciones y recarga.
class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.onReload});

  final AdminCurriculumState state;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final lessons = state.modules.fold(0, (sum, m) => sum + m.lessons.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${state.modules.length} módulo'
              '${state.modules.length == 1 ? '' : 's'} · $lessons lección'
              '${lessons == 1 ? '' : 'es'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh, size: 19),
            onPressed: state.isLoading ? null : onReload,
          ),
        ],
      ),
    );
  }
}

/// Módulo con sus lecciones y acciones.
class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({required this.module, required this.courseId});

  final AdminModule module;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sin courses:create el temario se ve pero no se edita.
    final canEdit = ref.watch(permissionProvider('courses:create'));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(left: 16, right: 6, top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  AdminActionButton(
                    tooltip: 'Subir',
                    icon: Icons.arrow_upward,
                    onPressed: module.orderIndex <= 1
                        ? () {}
                        : () => ref
                              .read(adminCurriculumViewModelProvider.notifier)
                              .moveModule(module, up: true),
                  ),
                  AdminActionButton(
                    tooltip: 'Bajar',
                    icon: Icons.arrow_downward,
                    onPressed: () => ref
                        .read(adminCurriculumViewModelProvider.notifier)
                        .moveModule(module, up: false),
                  ),
                  AdminActionButton(
                    tooltip: 'Renombrar',
                    icon: Icons.edit_outlined,
                    onPressed: () => _rename(context, ref),
                  ),
                  AdminActionButton(
                    tooltip: 'Borrar módulo y sus lecciones',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onPressed: () => _delete(context, ref),
                  ),
                ],
              ],
            ),
          ),
          if (module.lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sin lecciones todavía.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            for (final lesson in module.lessons)
              _LessonRow(module: module, lesson: lesson),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addLesson(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir lección'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addLesson(BuildContext context, WidgetRef ref) async {
    final saved = await AdminLessonEditor.show(context, module: module);
    if (!saved || !context.mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    await showAppSuccess(
      context,
      title: 'Lección añadida',
      message: vm.successMessage,
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: module.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Renombrar módulo',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Título del módulo',
            isDense: true,
            border: _inputBorder(),
            enabledBorder: _inputBorder(),
            focusedBorder: _inputBorder(color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).maybePop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.of(dialogContext).maybePop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty || !context.mounted) return;

    final ok = await runWithAppLoading(
      context,
      ref
          .read(adminCurriculumViewModelProvider.notifier)
          .saveModule(
            NewModule(courseId: courseId, moduleId: module.id, title: title),
          ),
      text: 'Renombrando…',
    );
    if (!context.mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    if (ok == true) {
      await showAppSuccess(
        context,
        title: 'Módulo renombrado',
        message: vm.successMessage,
      );
    } else {
      await showAppError(
        context,
        title: 'No se pudo renombrar',
        message: vm.submitError ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: Icons.delete_outline,
      title: 'Borrar módulo',
      message: 'Se borrarán "${module.title}" y sus '
          '${module.lessons.length} lección(es), incluido el avance de '
          'los estudiantes. Esta acción no se puede deshacer.',
      confirmLabel: 'Borrar',
    );
    if (!confirmed || !context.mounted) return;

    final ok = await runWithAppLoading(
      context,
      ref.read(adminCurriculumViewModelProvider.notifier).deleteModule(module),
      text: 'Borrando módulo…',
    );
    if (!context.mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    if (ok == true) {
      await showAppSuccess(
        context,
        title: 'Módulo borrado',
        message: vm.successMessage,
      );
    } else {
      await showAppError(
        context,
        title: 'No se pudo borrar el módulo',
        message: vm.submitError ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }
}

/// Lección dentro de un módulo.
class _LessonRow extends ConsumerWidget {
  const _LessonRow({required this.module, required this.lesson});

  final AdminModule module;
  final AdminLesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = kContentTypeLabels[lesson.contentType] ?? lesson.contentType;
    final hasContent = lesson.hasContent;
    // Sin courses:create la lección se ve pero no se edita.
    final canEdit = ref.watch(permissionProvider('courses:create'));

    return Container(
      padding: const EdgeInsets.only(left: 30, right: 6, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Icon(
            lessonIcon(lesson.contentType),
            size: 17,
            color: hasContent ? AppColors.textDark : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  hasContent ? kind : '$kind · sin contenido',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: hasContent
                        ? AppColors.textMuted
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          if (canEdit) ...[
            AdminActionButton(
              tooltip: 'Subir',
              icon: Icons.arrow_upward,
              onPressed: lesson.orderIndex <= 1
                  ? () {}
                  : () => ref
                        .read(adminCurriculumViewModelProvider.notifier)
                        .moveLesson(module, lesson, up: true),
            ),
            AdminActionButton(
              tooltip: 'Bajar',
              icon: Icons.arrow_downward,
              onPressed: () => ref
                  .read(adminCurriculumViewModelProvider.notifier)
                  .moveLesson(module, lesson, up: false),
            ),
            AdminActionButton(
              tooltip: 'Editar lección',
              icon: Icons.edit_outlined,
              onPressed: () => _edit(context, ref),
            ),
            AdminActionButton(
              tooltip: 'Borrar lección',
              icon: Icons.delete_outline,
              destructive: true,
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await AdminLessonEditor.show(
      context,
      module: module,
      initial: lesson,
    );
    if (!saved || !context.mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    await showAppSuccess(
      context,
      title: 'Lección actualizada',
      message: vm.successMessage,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: Icons.delete_outline,
      title: 'Borrar lección',
      message: 'Se borrará "${lesson.title}" y el avance de los '
          'estudiantes. Esta acción no se puede deshacer.',
      confirmLabel: 'Borrar',
    );
    if (!confirmed || !context.mounted) return;

    final ok = await runWithAppLoading(
      context,
      ref.read(adminCurriculumViewModelProvider.notifier).deleteLesson(lesson),
      text: 'Borrando lección…',
    );
    if (!context.mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    if (ok == true) {
      await showAppSuccess(
        context,
        title: 'Lección borrada',
        message: vm.successMessage,
      );
    } else {
      await showAppError(
        context,
        title: 'No se pudo borrar la lección',
        message: vm.submitError ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }
}

/// Formulario de alta de módulo (va al final del editor).
class _ModuleForm extends ConsumerStatefulWidget {
  const _ModuleForm();

  @override
  ConsumerState<_ModuleForm> createState() => _ModuleFormState();
}

class _ModuleFormState extends ConsumerState<_ModuleForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCurriculumViewModelProvider);

    // Sin courses:create no se ofrece el alta de módulos.
    if (!ref.watch(permissionProvider('courses:create'))) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !state.isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Nuevo módulo (ej. "Módulo 1: Introducción")',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: _inputBorder(color: Colors.white),
                    enabledBorder: _inputBorder(color: Colors.white),
                    focusedBorder: _inputBorder(color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: state.isSubmitting ? null : _submit,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      await showAppWarning(
        context,
        title: 'Falta el título',
        message: 'Escribe el nombre del módulo antes de añadirlo.',
      );
      return;
    }

    final notifier = ref.read(adminCurriculumViewModelProvider.notifier);
    final courseId = ref.read(adminCurriculumViewModelProvider).courseId ?? '';

    final ok = await runWithAppLoading(
      context,
      notifier.saveModule(NewModule(courseId: courseId, title: title)),
      text: 'Añadiendo módulo…',
    );
    if (!mounted) return;

    final vm = ref.read(adminCurriculumViewModelProvider);
    if (ok == true) {
      _controller.clear();
      await showAppSuccess(
        context,
        title: 'Módulo añadido',
        message: vm.successMessage,
      );
    } else {
      await showAppError(
        context,
        title: 'No se pudo añadir el módulo',
        message: vm.submitError ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }
}

/// Sin módulos todavía: invita a crear el primero.
class _EmptyCurriculum extends ConsumerWidget {
  const _EmptyCurriculum();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(permissionProvider('courses:create'));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 34,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'Este curso aún no tiene temario',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canEdit
                ? 'Añade el primer módulo y sus lecciones: los estudiantes '
                      'verán\nel temario en el aula en cuanto su pago sea '
                      'aprobado.'
                : 'Este curso aún no tiene módulos publicados.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error de carga del temario + reintentar.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
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
