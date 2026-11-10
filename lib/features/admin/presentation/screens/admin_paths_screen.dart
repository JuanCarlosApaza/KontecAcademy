import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../../landing/landing_injector.dart';
import '../../../landing/presentation/widgets/course_display.dart';
import '../../admin_injector.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// RUTAS DE ENTRENAMIENTO: /admin/rutas
///
/// Tabla con las rutas del catálogo (públicas y borradores). La alta y
/// la edición usan un diálogo con el formulario de cabecera + selector
/// ORDENABLE de cursos con nivel por curso.
class AdminPathsScreen extends ConsumerStatefulWidget {
  const AdminPathsScreen({super.key});

  @override
  ConsumerState<AdminPathsScreen> createState() => _AdminPathsScreenState();
}

class _AdminPathsScreenState extends ConsumerState<AdminPathsScreen> {
  List<LearningPath> _paths = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (paths, failure) = await ref.read(listPathsProvider)(NoParams());
    if (!mounted) return;
    setState(() {
      _paths = failure == null ? paths : const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sin courses:view no se muestra la sección (mismo guard del server).
    if (!ref.watch(permissionProvider('courses:view'))) {
      return const AdminAccessDenied(
        message: 'Tu cuenta no tiene el permiso "courses:view" para '
            'gestionar las rutas de entrenamiento.',
        buttonLabel: 'Volver al sitio',
        destination: '/',
      );
    }
    final canCreate = ref.watch(permissionProvider('courses:create'));

    return AdminPage(
      title: 'Rutas de entrenamiento',
      child: AdminTableCard<LearningPath>(
        title: 'Rutas del catálogo',
        subtitle: '${_paths.length} en total',
        isLoading: _loading,
        items: _paths,
        searchHint: 'Buscar por título o slug…',
        searchText: (p) => '${p.title} ${p.slug}',
        emptyMessage:
            'Aún no hay rutas. Crea la primera con "Nueva ruta" para '
            'agrupar cursos con nivel y orden.',
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (canCreate)
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva ruta'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
        columns: [
          AdminColumn<LearningPath>(
            label: 'Título',
            width: 300,
            sortValue: (p) => p.title.toLowerCase(),
            cell: (p) => Row(
              children: [
                const Icon(
                  Icons.signpost_outlined,
                  size: 16,
                  color: AppColors.textDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AdminColumn<LearningPath>(
            label: 'Cursos',
            width: 90,
            sortValue: (p) => p.courses.length,
            cell: (p) => Text(
              '${p.courses.length}',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          AdminColumn<LearningPath>(
            label: 'Duración',
            width: 110,
            sortValue: (p) => p.durationHours,
            cell: (p) => Text(
              '${p.durationHours} h',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          AdminColumn<LearningPath>(
            label: 'Precio',
            width: 120,
            sortValue: (p) => p.price,
            cell: (p) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDollars(p.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (p.discountPercent > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '-${p.discountPercent}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AdminColumn<LearningPath>(
            label: 'Estado',
            width: 120,
            sortValue: (p) => p.isPublished ? 0 : 1,
            cell: (p) => _StatusBadge(published: p.isPublished),
          ),
          AdminColumn<LearningPath>(
            label: 'Acciones',
            width: 110,
            isActions: true,
            cell: (p) => canCreate
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminActionButton(
                        tooltip: 'Editar ruta',
                        icon: Icons.edit_outlined,
                        onPressed: () => _openEditDialog(p),
                      ),
                      const SizedBox(width: 6),
                      AdminActionButton(
                        tooltip: 'Eliminar ruta',
                        icon: Icons.delete_outline,
                        destructive: true,
                        onPressed: () => _confirmDelete(p),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nueva ruta',
      subtitle: 'El slug se genera del título; los cursos se ordenan con ↑↓.',
      width: 720,
      child: const _PathForm(),
    );

    if (created != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Ruta creada',
      message: 'Ya puedes verla en /rutas y ajustar sus cursos.',
    );
    await _load();
  }

  Future<void> _openEditDialog(LearningPath path) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar ruta',
      subtitle: path.title,
      width: 720,
      child: _PathForm(initial: path),
    );

    if (saved != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Ruta actualizada',
      message: 'Los cambios ya están publicados en la página de rutas.',
    );
    await _load();
  }

  Future<void> _confirmDelete(LearningPath path) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Eliminar la ruta "${path.title}"',
      message: 'Se quitarán sus cursos de la ruta (los cursos en sí no '
          'se borran). Esta acción no se puede deshacer.',
      confirmText: 'Eliminar ruta',
    );
    if (!confirmed || !mounted) return;

    final result = await runWithAppLoading<(bool, Failure?)>(
      context,
      ref.read(deletePathProvider)(path.id),
      text: 'Eliminando ruta…',
    );
    if (!mounted || result == null) return;
    final (deleted, failure) = result;

    if (failure != null) {
      await showAppError(
        context,
        title: 'No se pudo eliminar la ruta',
        message: failure.message,
      );
      return;
    }

    if (deleted == false) {
      await showAppWarning(
        context,
        title: 'Ruta no encontrada',
        message: 'Puede que ya se haya eliminado.',
      );
    } else {
      await showAppSuccess(
        context,
        title: 'Ruta eliminada',
        message: 'La ruta "${path.title}" ya no existe.',
      );
    }
    await _load();
  }
}

/// Badge de estado de la ruta (Publicada / Borrador).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.published});

  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? const Color(0xFF15803D) : const Color(0xFFB45309);
    final background = published
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFF1E0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        published ? 'Publicada' : 'Borrador',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Formulario dentro del diálogo: cabecera + selector de cursos.
/// Con [initial] edita la ruta en vez de crear una nueva.
class _PathForm extends ConsumerStatefulWidget {
  const _PathForm({this.initial});

  /// Ruta a editar; null = creación.
  final LearningPath? initial;

  @override
  ConsumerState<_PathForm> createState() => _PathFormState();
}

class _PathFormState extends ConsumerState<_PathForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _durationController;
  late final TextEditingController _accessMonthsController;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _discountController;

  String _modality = 'asynchronous';
  bool _isPublished = true;

  /// Cursos ELEGIDOS en orden (la posición de la lista es el orden).
  List<PathCourseAssignment> _selected = const [];

  /// Todos los cursos del catálogo (selector).
  List<TrainingCourse> _allCourses = const [];
  bool _loadingCourses = true;

  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _coverUrlController = TextEditingController(text: initial?.coverUrl ?? '');
    _durationController = TextEditingController(
      text: (initial?.durationHours ?? 0) > 0 ? '${initial!.durationHours}' : '',
    );
    _accessMonthsController = TextEditingController(
      text: '${initial?.accessMonths ?? 12}',
    );
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    _discountController = TextEditingController(
      text: '${initial?.discountPercent ?? 0}',
    );
    _modality = initial?.modality ?? 'asynchronous';
    _isPublished = initial?.isPublished ?? true;
    _selected = [
      for (final course in initial?.courses ?? const <PathCourse>[])
        PathCourseAssignment(
          courseId: course.courseId,
          level: course.level,
          sortOrder: course.sortOrder,
        ),
    ];
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final (courses, _) = await ref.read(getAllCoursesProvider)(NoParams());
    if (!mounted) return;
    setState(() {
      _allCourses = courses;
      _loadingCourses = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _durationController.dispose();
    _accessMonthsController.dispose();
    _sortOrderController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  TrainingCourse? _courseById(String id) {
    for (final course in _allCourses) {
      if (course.id == id) return course;
    }
    return null;
  }

  List<TrainingCourse> get _remainingCourses {
    final chosen = {for (final entry in _selected) entry.courseId};
    return _allCourses.where((course) => !chosen.contains(course.id)).toList();
  }

  /// Total en vivo: suma de los precios EFECTIVOS de los cursos
  /// elegidos (con oferta aplicada) y el precio con el % del campo.
  String get _pricingHint {
    if (_selected.isEmpty) {
      return 'Agrega cursos para ver el total de la ruta.';
    }
    var total = 0.0;
    for (final entry in _selected) {
      total += _courseById(entry.courseId)?.effectivePrice ?? 0;
    }
    final percent = (int.tryParse(_discountController.text.trim()) ?? 0)
        .clamp(0, 100);
    final finalPrice = total * (100 - percent) / 100;
    final base = 'Total ${formatDollars(total)}';
    return percent > 0
        ? '$base → con -$percent%: ${formatDollars(finalPrice)}'
        : '$base (sin rebaja)';
  }

  int? _parseInt(TextEditingController controller, String field) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    final value = int.tryParse(raw);
    if (value == null || value < 0) {
      _error = 'El campo "$field" debe ser un número entero ≥ 0';
      return null;
    }
    return value;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'El título es obligatorio');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final duration = _parseInt(_durationController, 'Duración');
    final accessMonths = _parseInt(_accessMonthsController, 'Acceso') ?? 12;
    final sortOrder = _parseInt(_sortOrderController, 'Orden') ?? 0;
    final discount = _parseInt(_discountController, 'Descuento') ?? 0;
    if (discount > 100) {
      _error = 'El descuento no puede superar el 100%';
    }
    if (_error != null) {
      setState(() => _submitting = false);
      return;
    }

    final input = AdminPathInput(
      title: title,
      description: _descriptionController.text.trim(),
      coverUrl: _coverUrlController.text.trim().isEmpty
          ? null
          : _coverUrlController.text.trim(),
      modality: _modality,
      durationHours: duration,
      accessMonths: accessMonths < 1 ? 1 : accessMonths,
      discountPercent: discount,
      sortOrder: sortOrder,
      isPublished: _isPublished,
    );

    // 1) Cabecera (crear o editar).
    final (path, headerFailure) = _isEditing
        ? await ref.read(updatePathProvider)(
            UpdatePathParams(id: widget.initial!.id, input: input),
          )
        : await ref.read(createPathProvider)(input);

    if (!mounted) return;
    if (headerFailure != null) {
      setState(() {
        _submitting = false;
        _error = headerFailure.message;
      });
      return;
    }
    if (path == null) {
      setState(() {
        _submitting = false;
        _error = 'La ruta ya no existe (¿la borraron en otra pestaña?).';
      });
      return;
    }

    // 2) Cursos (reemplazo completo, con orden por posición).
    final (saved, coursesFailure) = await ref.read(savePathCoursesProvider)(
      SavePathCoursesParams(
        id: path.id,
        courses: [
          for (var i = 0; i < _selected.length; i++)
            PathCourseAssignment(
              courseId: _selected[i].courseId,
              level: _selected[i].level,
              sortOrder: i,
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (coursesFailure != null) {
      setState(() {
        _submitting = false;
        _error = coursesFailure.message;
      });
      return;
    }
    if (saved == null) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          autofocus: !_isEditing,
          decoration: const InputDecoration(
            labelText: 'Título *',
            hintText: 'Ej. Especialista BIM en edificaciones',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Qué aprenderá quien siga esta ruta…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _coverUrlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL de la portada (opcional)',
            hintText: 'https://… (si se deja vacío, gradiente de marca)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        // Modalidad + duración (vacío = derivada de los cursos).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _modality,
                decoration: const InputDecoration(
                  labelText: 'Modalidad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'asynchronous',
                    child: Text('Asíncrono'),
                  ),
                  DropdownMenuItem(value: 'live', child: Text('En vivo')),
                ],
                onChanged: (value) =>
                    setState(() => _modality = value ?? 'asynchronous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas totales',
                  hintText: 'Vacío = suma de cursos',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _accessMonthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Acceso (meses)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Orden en la lista',
                  hintText: '0 = primero',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // % de rebaja por adquirir la ruta (sobre el total de cursos).
        TextField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '% de rebaja por adquirir la ruta',
            hintText: 'Ej. 20 (0 = sin rebaja)',
            helperText: 'El total usa los precios CON oferta de cada curso.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _pricingHint,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Publicada (visible en /rutas)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          value: _isPublished,
          activeThumbColor: AppColors.primary,
          onChanged: (value) => setState(() => _isPublished = value),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          'Cursos de la ruta (${_selected.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'El orden de la lista es el orden de la ruta; el nivel va por curso.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        if (_selected.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Sin cursos aún. Agrega el primero con el selector de abajo.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          for (var i = 0; i < _selected.length; i++)
            _SelectedCourseTile(
              position: i + 1,
              course: _courseById(_selected[i].courseId),
              level: _selected[i].level,
              canMoveUp: i > 0,
              canMoveDown: i < _selected.length - 1,
              onLevelChanged: (level) => setState(
                () => _selected[i] = PathCourseAssignment(
                  courseId: _selected[i].courseId,
                  level: level,
                  sortOrder: i,
                ),
              ),
              onMoveUp: () => _move(i, i - 1),
              onMoveDown: () => _move(i, i + 1),
              onRemove: () => setState(() => _selected.removeAt(i)),
            ),
        const SizedBox(height: 8),
        if (_loadingCourses)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_remainingCourses.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _pendingCourseId,
                  decoration: const InputDecoration(
                    labelText: 'Agregar curso',
                    hintText: 'Elegir del catálogo…',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final course in _remainingCourses)
                      DropdownMenuItem(
                        value: course.id,
                        child: Text(course.title),
                      ),
                  ],
                  onChanged: (id) =>
                      setState(() => _pendingCourseId = id),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _pendingCourseId == null
                    ? null
                    : _addPendingCourse,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        AdminDialogActions(
          confirmLabel: _isEditing ? 'Guardar cambios' : 'Crear ruta',
          confirmIcon: _isEditing ? Icons.check : Icons.add,
          isSubmitting: _submitting,
          onConfirm: _submit,
        ),
      ],
    );
  }

  /// Curso elegido en el selector (se añade con el botón "Añadir").
  String? _pendingCourseId;

  void _addPendingCourse() {
    final id = _pendingCourseId;
    if (id == null) return;
    setState(() {
      _pendingCourseId = null;
      _selected = [
        ..._selected,
        PathCourseAssignment(courseId: id, sortOrder: _selected.length),
      ];
    });
  }

  void _move(int from, int to) {
    setState(() {
      final list = [..._selected];
      final item = list.removeAt(from);
      list.insert(to, item);
      _selected = [
        for (var i = 0; i < list.length; i++)
          PathCourseAssignment(
            courseId: list[i].courseId,
            level: list[i].level,
            sortOrder: i,
          ),
      ];
    });
  }
}

/// Curso elegido: título + controles (mover / nivel / quitar).
class _SelectedCourseTile extends StatelessWidget {
  const _SelectedCourseTile({
    required this.position,
    required this.course,
    required this.level,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onLevelChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int position;
  final TrainingCourse? course;
  final String? level;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  static const _levels = ['Introductorio', 'Intermedio', 'Avanzado'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course?.title ?? 'Curso no encontrado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              AdminActionButton(
                tooltip: 'Subir',
                icon: Icons.arrow_upward,
                onPressed: canMoveUp ? onMoveUp : null,
              ),
              AdminActionButton(
                tooltip: 'Bajar',
                icon: Icons.arrow_downward,
                onPressed: canMoveDown ? onMoveDown : null,
              ),
              AdminActionButton(
                tooltip: 'Quitar de la ruta',
                icon: Icons.close,
                destructive: true,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Nivel:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: level,
                  isDense: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final option in _levels)
                      DropdownMenuItem(value: option, child: Text(option)),
                  ],
                  onChanged: onLevelChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
