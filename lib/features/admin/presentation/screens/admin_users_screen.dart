import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/admin_user_record.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';
import '../widgets/admin_user_form.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// USUARIOS: /admin/usuarios
///
/// Cuentas del sistema con sus roles (admin / docente / estudiante /
/// sin rol). Tabla con buscador, filtro por rol y paginación; el alta
/// se hace con un botón que despliega el formulario en un diálogo.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  /// Filtro de rol activo ('all' = todos, 'none' = sin rol).
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminViewModelProvider.notifier).load());
  }

  List<AdminUserRecord> _applyFilter(List<AdminUserRecord> users) {
    if (_roleFilter == 'all') return users;
    if (_roleFilter == 'none') {
      return users.where((u) => u.roles.isEmpty).toList();
    }
    return users.where((u) => u.roles.contains(_roleFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(adminViewModelProvider);
    final canCreate = ref.watch(permissionProvider('users:create'));
    final canEdit = ref.watch(permissionProvider('users:edit'));

    return AdminPage(
      title: 'Usuarios',
      child: AdminTableCard<AdminUserRecord>(
        title: 'Cuentas registradas',
        subtitle: '${panel.users.length} en total',
        isLoading: panel.isLoading && panel.users.isEmpty,
        items: _applyFilter(panel.users),
        searchHint: 'Buscar por nombre, email o teléfono…',
        searchText: (u) => '${u.fullName} ${u.email} ${u.phone ?? ''}',
        emptyMessage: 'No hay usuarios en esta vista.',
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: panel.isLoading
                ? null
                : () => ref.read(adminViewModelProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
          if (canCreate)
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Nuevo usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
        filters: [
          SizedBox(
            height: 32,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _roleFilter,
                isDense: true,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Todos los roles'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administradores'),
                  ),
                  DropdownMenuItem(value: 'teacher', child: Text('Docentes')),
                  DropdownMenuItem(
                    value: 'student',
                    child: Text('Estudiantes'),
                  ),
                  DropdownMenuItem(value: 'none', child: Text('Sin rol')),
                ],
                onChanged: (value) =>
                    setState(() => _roleFilter = value ?? 'all'),
              ),
            ),
          ),
        ],
        columns: [
          AdminColumn<AdminUserRecord>(
            label: 'Usuario',
            width: 300,
            sortValue: (u) => u.fullName.toLowerCase(),
            cell: (u) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  u.fullName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  u.email,
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
          AdminColumn<AdminUserRecord>(
            label: 'Teléfono',
            sortValue: (u) => u.phone ?? '',
            cell: (u) => Text(u.phone ?? '—'),
          ),
          AdminColumn<AdminUserRecord>(
            label: 'Roles',
            width: 210,
            sortValue: (u) => u.roles.isEmpty ? 'sin rol' : u.roles.join(', '),
            cell: (u) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (u.roles.isEmpty) roleBadge('sin rol'),
                for (final role in u.roles) roleBadge(role),
              ],
            ),
          ),
          AdminColumn<AdminUserRecord>(
            label: 'Estado',
            width: 110,
            sortValue: (u) => u.isActive ? 1 : 0,
            cell: (u) => userStatusBadge(u.isActive),
          ),
          AdminColumn<AdminUserRecord>(
            label: 'Registro',
            sortValue: (u) => u.createdAt ?? DateTime(2000),
            cell: (u) => Text(
              u.createdAt == null ? '—' : _formatDate(u.createdAt!),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          AdminColumn<AdminUserRecord>(
            label: 'Acciones',
            width: 110,
            isActions: true,
            cell: (u) => canEdit
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminActionButton(
                        tooltip: 'Editar',
                        icon: Icons.edit_outlined,
                        onPressed: () => _openEditDialog(u),
                      ),
                      if (u.isActive)
                        AdminActionButton(
                          tooltip: 'Desactivar usuario',
                          icon: Icons.person_off_outlined,
                          destructive: true,
                          onPressed: () => _toggleStatus(u, activate: false),
                        )
                      else
                        AdminActionButton(
                          tooltip: 'Reactivar usuario',
                          icon: Icons.restore,
                          onPressed: () => _toggleStatus(u, activate: true),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Abre el diálogo con el formulario de creación de usuario.
  Future<void> _openCreateDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nuevo usuario',
      subtitle:
          'Se crea la cuenta de acceso (Supabase Auth) y el perfil '
          'del usuario con su rol.',
      child: const AdminUserForm(),
    );

    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Usuario creado ✅')));
    await ref.read(adminViewModelProvider.notifier).load();
  }

  /// Diálogo de EDICIÓN con los datos del usuario precargados.
  Future<void> _openEditDialog(AdminUserRecord user) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar usuario',
      subtitle: user.email,
      child: AdminUserForm(
        initial: AdminUserEditData(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          phone: user.phone,
          role: user.roles.isEmpty ? '' : user.roles.first,
          isActive: user.isActive,
        ),
      ),
    );

    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuario ${user.email} actualizado ✅')),
    );
  }

  /// Desactivar/reactivar: BORRADO LÓGICO (isActive), nunca se borra
  /// la cuenta ni sus datos de la BD.
  Future<void> _toggleStatus(
    AdminUserRecord user, {
    required bool activate,
  }) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: activate ? Icons.restore : Icons.person_off_outlined,
      title: activate ? 'Reactivar usuario' : 'Desactivar usuario',
      message: activate
          ? '${user.fullName} podrá volver a iniciar sesión.'
          : '${user.fullName} dejará de poder iniciar sesión. '
                'No se elimina ningún dato: su cuenta, perfil e '
                'inscripciones se conservan y puedes reactivarlo cuando quieras.',
      confirmLabel: activate ? 'Reactivar' : 'Desactivar',
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(adminViewModelProvider.notifier)
        .updateUser(
          id: user.id,
          fullName: user.fullName,
          phone: user.phone,
          role: user.roles.isEmpty ? 'student' : user.roles.first,
          isActive: activate,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? activate
                    ? 'Usuario reactivado ✅'
                    : 'Usuario desactivado (sigue en la BD) ✅'
              : 'No se pudo cambiar el estado del usuario',
        ),
      ),
    );
  }
}
