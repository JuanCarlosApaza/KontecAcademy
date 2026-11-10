import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../admin_injector.dart';
import '../../domain/entities/roles_matrix.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// ROLES Y PERMISOS: /admin/roles
///
/// Matriz rol × permiso que administra el propio panel: cada fila es
/// un permiso (`modulo:accion`) y cada columna un rol. El rol `admin`
/// sale siempre marcado y bloqueado (el backend le da todos los
/// permisos y no deja modificarlo, para que nadie se autobloquee).
///
/// Responsive: tabla en pantallas anchas y tarjetas con secciones
/// plegables en móvil.
class AdminRolesScreen extends ConsumerStatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  ConsumerState<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends ConsumerState<AdminRolesScreen> {
  /// Cambios SIN guardar, por id de rol. Ausente = igual que la matriz.
  final Map<String, Set<String>> _dirty = {};

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // Guard de sección: /admin/roles directo sin el permiso.
    if (!ref.watch(permissionProvider('roles:manage'))) {
      return const AdminAccessDenied(
        message: 'Tu cuenta no tiene el permiso "roles:manage" para '
            'gestionar los roles del panel.',
        buttonLabel: 'Volver al sitio',
        destination: '/',
      );
    }

    final matrixAsync = ref.watch(rolesMatrixProvider);

    return AdminPage(
      title: 'Roles y permisos',
      child: matrixAsync.when(
        loading: () => const _PanelBox(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, _) => _PanelBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(rolesMatrixProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (matrix) => _buildMatrix(context, matrix),
      ),
    );
  }

  Widget _buildMatrix(BuildContext context, RolesMatrix matrix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dirty.isNotEmpty) ...[
          _saveBar(matrix),
          const SizedBox(height: 14),
        ],
        _PanelBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(matrix),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return wide
                      ? _tableView(matrix)
                      : _cardsView(context, matrix);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Cabecera ───────────────────────────────────────────────────

  Widget _header(RolesMatrix matrix) {
    final dirtyCount = _dirty.length;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Matriz de permisos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${matrix.roles.length} roles · '
              '${matrix.permissions.length} permisos'
              '${dirtyCount > 0 ? ' · $dirtyCount sin guardar' : ''}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _saving ? null : _openCreateDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo rol'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Vista tabla (≥760px) ───────────────────────────────────────

  Widget _tableView(RolesMatrix matrix) {
    final roles = matrix.roles;

    final rows = <DataRow>[];
    matrix.byModule.forEach((module, permissions) {
      for (var i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        rows.add(
          DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 340,
                  child: _permissionCell(
                    module: module,
                    permission: permission,
                    isFirstOfModule: i == 0,
                  ),
                ),
              ),
              for (final role in roles)
                DataCell(
                  Center(
                    child: SizedBox(
                      width: 120,
                      child: _checkbox(matrix, role, permission.code),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
        columnSpacing: 20,
        horizontalMargin: 16,
        showCheckboxColumn: false,
        columns: [
          const DataColumn(
            label: SizedBox(
              width: 340,
              child: Text(
                'Permiso',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          for (final role in roles)
            DataColumn(label: SizedBox(width: 120, child: _roleHeader(role))),
        ],
        rows: rows,
      ),
    );
  }

  Widget _roleHeader(RoleRecord role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                role.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (!role.system && !_saving)
              IconButton(
                tooltip: 'Eliminar rol "${role.name}"',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                color: const Color(0xFFDC2626),
                onPressed: () => _confirmDelete(role),
              ),
          ],
        ),
        Text(
          role.system
              ? 'Base · ${role.userCount} usuario(s)'
              : '${role.userCount} usuario(s)',
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        if (role.name == 'admin')
          const Text(
            'Todos, siempre',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _permissionCell({
    required String module,
    required PermissionDef permission,
    required bool isFirstOfModule,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirstOfModule)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 4),
            child: Text(
              module.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                color: AppColors.textMuted,
              ),
            ),
          ),
        Text(
          permission.code,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          permission.description,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _checkbox(RolesMatrix matrix, RoleRecord role, String code) {
    // El rol admin siempre está marcado y bloqueado (bypass del server).
    final locked = role.name == 'admin' || _saving;
    final codes = locked
        ? (matrix.grants[role.name] ?? const <String>[])
        : (_dirty[role.id] ?? matrix.codesOf(role));

    return Checkbox(
      value: codes.contains(code),
      activeColor: AppColors.black,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onChanged: locked
          ? null
          : (value) => _toggle(matrix, role, code, value ?? false),
    );
  }

  // ── Vista tarjetas (<760px) ────────────────────────────────────

  Widget _cardsView(BuildContext context, RolesMatrix matrix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in matrix.roles) _roleCard(context, matrix, role),
      ],
    );
  }

  Widget _roleCard(BuildContext context, RolesMatrix matrix, RoleRecord role) {
    final selected = role.name == 'admin'
        ? matrix.grants[role.name] ?? const <String>[]
        : (_dirty[role.id] ?? matrix.codesOf(role));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                role.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (!role.system && !_saving)
              IconButton(
                tooltip: 'Eliminar rol "${role.name}"',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFDC2626),
                onPressed: () => _confirmDelete(role),
              ),
          ],
        ),
        subtitle: Text(
          '${selected.length} de ${matrix.permissions.length} permisos'
          '${role.system ? ' · rol base' : ''}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final entry in matrix.byModule.entries) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            for (final permission in entry.value)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(permission.code),
                activeColor: AppColors.black,
                title: Text(
                  permission.code,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  permission.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                onChanged:
                    role.name == 'admin' || _saving
                        ? null
                        : (value) => _toggle(
                          matrix,
                          role,
                          permission.code,
                          value ?? false,
                        ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Acciones ───────────────────────────────────────────────────

  /// Barra de "cambios sin guardar" con descartar / guardar.
  Widget _saveBar(RolesMatrix matrix) {
    final count = _dirty.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 20, color: Color(0xFFB45309)),
          Text(
            '$count ${count == 1 ? 'rol' : 'roles'} con cambios sin guardar',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: _saving ? null : _discard,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              side: const BorderSide(color: Color(0xFFFCD34D)),
            ),
            child: const Text('Descartar'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : () => _saveAll(matrix),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Guardar permisos'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(RolesMatrix matrix, RoleRecord role, String code, bool value) {
    setState(() {
      final current = Set<String>.of(_dirty[role.id] ?? matrix.codesOf(role));
      if (value) {
        current.add(code);
      } else {
        current.remove(code);
      }

      // Volver al estado original → se descarta el "dirty" de ese rol.
      if (_sameSet(current, matrix.codesOf(role))) {
        _dirty.remove(role.id);
      } else {
        _dirty[role.id] = current;
      }
    });
  }

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  /// Guarda TODOS los roles con cambios, con el spinner modal de la
  /// librería para que la pantalla no quede "congelada" sin feedback.
  Future<void> _saveAll(RolesMatrix matrix) async {
    final entries = _dirty.entries.toList(growable: false);
    if (entries.isEmpty || _saving) return;

    // El id → nombre solo para el mensaje de éxito.
    final names = {
      for (final role in matrix.roles) role.id: role.name,
    };

    setState(() => _saving = true);

    Future<Failure?> saveChanges() async {
      for (final entry in entries) {
        final result = await ref.read(saveRolePermissionsProvider)(
          SaveRolePermissionsParams(
            roleId: entry.key,
            codes: entry.value.toList(growable: false)..sort(),
          ),
        );
        if (result != null) return result;
      }
      return null;
    }

    final failure = await runWithAppLoading<Failure?>(
      context,
      saveChanges(),
      text: 'Guardando permisos…',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (failure != null) {
      await showAppError(
        context,
        title: 'No se pudieron guardar los permisos',
        message: failure.message,
      );
      return;
    }

    setState(_dirty.clear);
    ref.invalidate(rolesMatrixProvider);
    // El menú lateral debe reflejar los permisos nuevos.
    ref.invalidate(sessionAccessProvider);

    await showAppSuccess(
      context,
      title: 'Permisos actualizados',
      message: 'Se actualizó: ${entries.map((e) => names[e.key] ?? e.key).join(', ')}',
    );
  }

  /// Descarta los cambios locales sin tocar el backend.
  void _discard() => setState(_dirty.clear);

  Future<void> _confirmDelete(RoleRecord role) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Eliminar el rol "${role.name}"',
      message:
          'Se quitarán sus permisos y las asignaciones a usuarios. '
          'Esta acción no se puede deshacer.',
      confirmText: 'Eliminar rol',
    );
    if (!confirmed || !mounted) return;

    final failure = await runWithAppLoading<Failure?>(
      context,
      ref.read(deleteRoleProvider)(role.id),
      text: 'Eliminando rol…',
    );
    if (!mounted) return;

    if (failure != null) {
      await showAppError(
        context,
        title: 'No se pudo eliminar el rol',
        message: failure.message,
      );
      return;
    }

    setState(() => _dirty.remove(role.id));
    ref.invalidate(rolesMatrixProvider);
    await showAppSuccess(
      context,
      title: 'Rol eliminado',
      message: 'El rol "${role.name}" ya no existe.',
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nuevo rol',
      subtitle: 'El nombre va en minúsculas y sin espacios.',
      width: 460,
      child: const _NewRoleForm(),
    );

    if (created != true || !mounted) return;
    ref.invalidate(rolesMatrixProvider);
    await showAppSuccess(
      context,
      title: 'Rol creado',
      message: 'Ya puedes marcar sus permisos en la matriz.',
    );
  }
}

// ── Piezas compartidas ────────────────────────────────────────────

/// Tarjeta blanca estándar del panel.
class _PanelBox extends StatelessWidget {
  const _PanelBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: adminCardDecoration,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: child,
    );
  }
}

/// Formulario del diálogo "Nuevo rol".
class _NewRoleForm extends ConsumerStatefulWidget {
  const _NewRoleForm();

  @override
  ConsumerState<_NewRoleForm> createState() => _NewRoleFormState();
}

class _NewRoleFormState extends ConsumerState<_NewRoleForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final (_, failure) = await ref.read(createRoleProvider)(
      CreateRoleParams(
        name: name,
        description: _descriptionController.text.trim(),
      ),
    );

    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _submitting = false;
        _error = failure.message;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. coordinador',
            helperText: 'Minúsculas, sin espacios (letras, números, - y _)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            hintText: 'Ej. Coordina los cursos del área',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 18),
        AdminDialogActions(
          confirmLabel: 'Crear rol',
          confirmIcon: Icons.add,
          isSubmitting: _submitting,
          onConfirm: _submit,
        ),
      ],
    );
  }
}
