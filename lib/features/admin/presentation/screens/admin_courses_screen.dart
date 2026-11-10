import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/domain/entities/category.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../../landing/landing_injector.dart';
import '../../../landing/presentation/viewmodels/courses_viewmodel.dart';
import '../../domain/entities/new_course.dart';
import '../viewmodels/admin_courses_viewmodel.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_course_form.dart';
import '../widgets/admin_curriculum_editor.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_price_cell.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// CURSOS: /admin/cursos
///
/// Tabla del catálogo con buscador, filtros de estado/categoría y
/// paginación. El alta se hace con un botón que despliega un diálogo
/// con el formulario (título, categoría, precios, imagen…).
class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  /// Filtros de la tabla.
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  /// Categorías reales (para el filtro y el formulario).
  List<Category> _categories = const [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final (categories, failure) = await ref.read(getCategoriesProvider)(
      NoParams(),
    );
    if (!mounted) return;
    setState(() {
      _categories = failure == null ? categories : const [];
      _loadingCategories = false;
    });
  }

  List<TrainingCourse> _applyFilters(List<TrainingCourse> courses) =>
      courses.where((course) {
        final matchStatus =
            _statusFilter == 'all' || course.status == _statusFilter;
        final matchCategory =
            _categoryFilter == 'all' || course.category == _categoryFilter;
        return matchStatus && matchCategory;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(coursesViewModelProvider);
    // Ver el catálogo es courses:view; crear/editar exige courses:create.
    final canWrite = ref.watch(permissionProvider('courses:create'));

    return AdminPage(
      title: 'Cursos',
      child: AdminTableCard<TrainingCourse>(
        title: 'Catálogo de cursos',
        subtitle: '${catalogState.courses.length} cursos en la plataforma',
        isLoading: catalogState.isLoading && catalogState.courses.isEmpty,
        items: _applyFilters(catalogState.courses),
        searchHint: 'Buscar por título o categoría…',
        searchText: (c) => '${c.title} ${c.category}',
        emptyMessage: _statusFilter == 'all' && _categoryFilter == 'all'
            ? 'Aún no hay cursos. Crea el primero con "Nuevo curso".'
            : 'Ningún curso coincide con los filtros seleccionados.',
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: catalogState.isLoading
                ? null
                : () =>
                      ref.read(coursesViewModelProvider.notifier).loadCourses(),
            icon: const Icon(Icons.refresh),
          ),
          if (canWrite)
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo curso'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
        filters: [
          // Estado.
          _statusChip('Todos', 'all'),
          for (final entry in kCourseStatusLabels.entries)
            _statusChip(entry.value, entry.key),
          const SizedBox(width: 8),
          // Categoría.
          Builder(
            builder: (context) {
              final names = [for (final c in _categories) c.name];
              return SizedBox(
                height: 32,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: names.contains(_categoryFilter)
                        ? _categoryFilter
                        : 'all',
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todas las categorías'),
                      ),
                      for (final name in names)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: _loadingCategories
                        ? null
                        : (value) =>
                              setState(() => _categoryFilter = value ?? 'all'),
                  ),
                ),
              );
            },
          ),
        ],
        columns: [
          AdminColumn<TrainingCourse>(
            label: 'Curso',
            width: 320,
            sortValue: (c) => c.title.toLowerCase(),
            cell: (c) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  c.category.isEmpty ? 'Sin categoría' : c.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
            // Precio de oferta (lo que se paga) + precio oficial tachado.
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
            width: canWrite ? 185 : 110,
            isActions: true,
            cell: (c) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminActionButton(
                  tooltip: 'Participantes',
                  icon: Icons.people_outline,
                  onPressed: () =>
                      context.push('/admin/cursos/${c.id}/participantes'),
                ),
                AdminActionButton(
                  tooltip: 'Temario',
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openCurriculumDialog(c),
                ),
                if (canWrite) ...[
                  AdminActionButton(
                    tooltip: 'Editar',
                    icon: Icons.edit_outlined,
                    onPressed: () => _openEditDialog(c),
                  ),
                  if (c.status == 'inactive')
                    AdminActionButton(
                      tooltip: 'Reactivar curso',
                      icon: Icons.restore,
                      onPressed: () => _toggleStatus(c, activate: true),
                    )
                  else
                    AdminActionButton(
                      tooltip: 'Desactivar curso',
                      icon: Icons.visibility_off_outlined,
                      destructive: true,
                      onPressed: () => _toggleStatus(c, activate: false),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.black,
      side: BorderSide(
        color: selected ? AppColors.black : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  /// Abre el diálogo con el formulario de creación de curso.
  Future<void> _openCreateDialog() async {
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
    await showAppSuccess(
      context,
      title: 'Curso creado',
      message: title.isEmpty ? 'Ya está en el catálogo.' : '"$title".',
    );
  }

  /// Abre el diálogo con el formulario precargado para editar el curso.
  Future<void> _openEditDialog(TrainingCourse course) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar curso',
      subtitle: course.title,
      width: 680,
      child: AdminCourseForm(initial: course),
    );

    if (saved != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Curso actualizado',
      message: '"${course.title}" ya tiene los cambios.',
    );
  }

  /// Temario del curso: módulos y lecciones que verá el estudiante en
  /// el aula (el contenido solo se sirve con pago aprobado).
  Future<void> _openCurriculumDialog(TrainingCourse course) {
    return showAdminDialog<bool>(
      context: context,
      title: 'Temario',
      subtitle: course.title,
      width: 760,
      child: AdminCurriculumEditor(course: course),
    );
  }

  /// Desactivar/reactivar un curso: es un CAMBIO DE ESTADO, nunca se
  /// elimina el registro de la BD.
  Future<void> _toggleStatus(
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

    final notifier = ref.read(adminCoursesViewModelProvider.notifier);
    final ok = await runWithAppLoading(
      context,
      notifier.update(
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
      ),
      text: activate ? 'Reactivando…' : 'Desactivando…',
    );

    if (!mounted) return;
    if (ok == true) {
      await showAppSuccess(
        context,
        title: activate ? 'Curso reactivado' : 'Curso desactivado',
        message: activate
            ? 'Ya vuelve a estar en el catálogo público.'
            : 'Siguen guardados todos sus datos y temario.',
      );
    } else {
      final error = ref.read(adminCoursesViewModelProvider).error;
      await showAppError(
        context,
        title: 'No se pudo cambiar el estado',
        message: error?.message ?? 'Intenta de nuevo en unos segundos.',
      );
    }
  }
}
