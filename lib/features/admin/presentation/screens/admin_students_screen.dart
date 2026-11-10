import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/student_record.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';
import '../widgets/admin_user_form.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// ESTUDIANTES: /admin/estudiantes
///
/// Tabla con buscador, filtros de vista y paginación sobre los usuarios
/// registrados. El alta se hace con un botón que despliega un diálogo
/// con el formulario (rol fijo "estudiante").
class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  /// Vista activa: todos / inscritos en cursos / sin cursos.
  String _view = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminViewModelProvider.notifier).load());
  }

  List<StudentRecord> _applyView(List<StudentRecord> students) =>
      switch (_view) {
        'with' => students.where((s) => s.enrolledCourses > 0).toList(),
        'without' => students.where((s) => s.enrolledCourses == 0).toList(),
        _ => students,
      };

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(adminViewModelProvider);

    return AdminPage(
      title: 'Estudiantes',
      child: AdminTableCard<StudentRecord>(
        title: 'Estudiantes registrados',
        subtitle: '${panel.students.length} en total',
        isLoading: panel.isLoading && panel.students.isEmpty,
        items: _applyView(panel.students),
        searchHint: 'Buscar por nombre, email o teléfono…',
        searchText: (s) =>
            '${s.fullName} ${s.email} ${s.phone ?? ''} ${s.nationality ?? ''}',
        emptyMessage:
            'Aún no hay estudiantes registrados. Usa "Nuevo estudiante" '
            'para dar de alta el primero.',
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: panel.isLoading
                ? null
                : () => ref.read(adminViewModelProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
          FilledButton.icon(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Nuevo estudiante'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        filters: [
          _viewChip('Todos', 'all'),
          _viewChip('Con cursos inscritos', 'with'),
          _viewChip('Sin cursos', 'without'),
        ],
        columns: [
          AdminColumn<StudentRecord>(
            label: 'Estudiante',
            width: 280,
            sortValue: (s) => s.fullName.toLowerCase(),
            cell: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.fullName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  s.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AdminColumn<StudentRecord>(
            label: 'Teléfono',
            sortValue: (s) => s.phone ?? '',
            cell: (s) => Text(s.phone ?? '—'),
          ),
          AdminColumn<StudentRecord>(
            label: 'Nacionalidad',
            sortValue: (s) => s.nationality ?? '',
            cell: (s) => Text(s.nationality ?? '—'),
          ),
          AdminColumn<StudentRecord>(
            label: 'Cursos',
            centered: true,
            width: 110,
            sortValue: (s) => s.enrolledCourses,
            cell: (s) => s.enrolledCourses == 0
                ? const Text('—', style: TextStyle(color: AppColors.textMuted))
                : AdminBadge(
                    label: '${s.enrolledCourses}',
                    background: const Color(0xFFF1F5F9),
                    icon: Icons.school_outlined,
                  ),
          ),
          AdminColumn<StudentRecord>(
            label: 'Estado',
            width: 110,
            sortValue: (s) => s.isActive ? 1 : 0,
            cell: (s) => userStatusBadge(s.isActive),
          ),
          AdminColumn<StudentRecord>(
            label: 'Registro',
            sortValue: (s) => s.createdAt ?? DateTime(2000),
            cell: (s) => Text(
              s.createdAt == null ? '—' : _formatDate(s.createdAt!),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          AdminColumn<StudentRecord>(
            label: 'Acciones',
            width: 150,
            isActions: true,
            cell: (s) {
              // Editar y cambiar estado usan PATCH /admin/users/:id.
              final canEdit = ref.watch(permissionProvider('users:edit'));

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminActionButton(
                    tooltip: 'Ver perfil',
                    icon: Icons.person_outline,
                    onPressed: () =>
                        context.push('/admin/estudiantes/${s.id}'),
                  ),
                  if (canEdit) ...[
                    AdminActionButton(
                      tooltip: 'Editar',
                      icon: Icons.edit_outlined,
                      onPressed: () => _openEditDialog(s),
                    ),
                    if (s.isActive)
                      AdminActionButton(
                        tooltip: 'Desactivar estudiante',
                        icon: Icons.person_off_outlined,
                        destructive: true,
                        onPressed: () => _toggleStatus(s, activate: false),
                      )
                    else
                      AdminActionButton(
                        tooltip: 'Reactivar estudiante',
                        icon: Icons.restore,
                        onPressed: () => _toggleStatus(s, activate: true),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _viewChip(String label, String value) {
    final selected = _view == value;
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
      onSelected: (_) => setState(() => _view = value),
    );
  }

  /// Rol actual del estudiante (si existe como usuario del sistema).
  String _roleOf(StudentRecord student) {
    final users = ref.read(adminViewModelProvider).users;
    final match = users.where((u) => u.id == student.id).firstOrNull;
    return match == null || match.roles.isEmpty ? 'student' : match.roles.first;
  }

  /// Abre el diálogo con el formulario de alta de estudiante.
  Future<void> _openCreateDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nuevo estudiante',
      subtitle:
          'Se crea la cuenta de acceso (Supabase Auth) y el perfil '
          'del usuario con el rol "estudiante".',
      child: const AdminUserForm(fixedRole: 'student'),
    );

    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Estudiante creado ✅')));
    await ref.read(adminViewModelProvider.notifier).load();
  }

  /// Diálogo de EDICIÓN con los datos del estudiante precargados.
  Future<void> _openEditDialog(StudentRecord student) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar estudiante',
      subtitle: student.email,
      child: AdminUserForm(
        initial: AdminUserEditData(
          id: student.id,
          email: student.email,
          fullName: student.fullName,
          phone: student.phone,
          role: _roleOf(student),
          isActive: student.isActive,
        ),
      ),
    );

    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estudiante ${student.email} actualizado ✅')),
    );
    await ref.read(adminViewModelProvider.notifier).load();
  }

  /// Desactivar/reactivar: BORRADO LÓGICO, nunca se borra el registro.
  Future<void> _toggleStatus(
    StudentRecord student, {
    required bool activate,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: activate ? Icons.restore : Icons.person_off_outlined,
      title: activate ? 'Reactivar estudiante' : 'Desactivar estudiante',
      message: activate
          ? '${student.fullName} podrá volver a iniciar sesión.'
          : '${student.fullName} dejará de poder iniciar sesión. '
                'No se elimina ningún dato: su cuenta, perfil e '
                'inscripciones se conservan y puedes reactivarlo cuando quieras.',
      confirmLabel: activate ? 'Reactivar' : 'Desactivar',
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(adminViewModelProvider.notifier)
        .updateUser(
          id: student.id,
          fullName: student.fullName,
          phone: student.phone,
          role: _roleOf(student),
          isActive: activate,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? activate
                    ? 'Estudiante reactivado ✅'
                    : 'Estudiante desactivado (sigue en la BD) ✅'
              : 'No se pudo cambiar el estado del estudiante',
        ),
      ),
    );
    if (ok) await ref.read(adminViewModelProvider.notifier).load();
  }
}
