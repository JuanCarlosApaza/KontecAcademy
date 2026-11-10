import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../landing/domain/entities/category.dart';
import '../../../landing/landing_injector.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// CATEGORÍAS: /admin/categorias
///
/// Tabla del catálogo con buscador y paginación. La alta se hace con
/// un botón que despliega un pequeño diálogo con el nombre.
///
/// Las categorías no tienen estado, así que aquí solo hay EDICIÓN
/// (renombrar): no se elimina ningún registro de la BD.
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  List<Category> _categories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (categories, failure) = await ref.read(getCategoriesProvider)(
      NoParams(),
    );
    if (!mounted) return;
    setState(() {
      _categories = failure == null ? categories : const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sin categories:edit no se ofrece ni el alta ni el renombrado.
    final canEdit = ref.watch(permissionProvider('categories:edit'));

    return AdminPage(
      title: 'Categorías',
      child: AdminTableCard<Category>(
        title: 'Categorías del catálogo',
        subtitle: '${_categories.length} en total',
        isLoading: _loading,
        items: _categories,
        searchHint: 'Buscar por nombre o slug…',
        searchText: (c) => '${c.name} ${c.slug}',
        emptyMessage:
            'Aún no hay categorías. Crea la primera con '
            '"Nueva categoría".',
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (canEdit)
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva categoría'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
        columns: [
          AdminColumn<Category>(
            label: 'Nombre',
            width: 280,
            sortValue: (c) => c.name.toLowerCase(),
            cell: (c) => Row(
              children: [
                const Icon(
                  Icons.label_outline,
                  size: 16,
                  color: AppColors.textDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.name,
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
          AdminColumn<Category>(
            label: 'Slug',
            sortValue: (c) => c.slug,
            cell: (c) => Text(
              c.slug,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),
          AdminColumn<Category>(
            label: 'Acciones',
            // 110 (no 80): con 80 el rótulo "Acciones" desbordaba el
            // encabezado por 21 px y Flutter lo pintaba como error.
            width: 110,
            isActions: true,
            cell: (c) => canEdit
                ? AdminActionButton(
                    tooltip: 'Editar nombre',
                    icon: Icons.edit_outlined,
                    onPressed: () => _openEditDialog(c),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Diálogo de creación de categoría.
  Future<void> _openCreateDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nueva categoría',
      subtitle: 'El slug se genera automáticamente a partir del nombre.',
      width: 460,
      child: const _CategoryForm(),
    );

    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Categoría creada ✅')));
    await _load();
  }

  /// Diálogo de EDICIÓN con el nombre precargado.
  Future<void> _openEditDialog(Category category) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar categoría',
      subtitle: category.name,
      width: 460,
      child: _CategoryForm(initial: category),
    );

    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Categoría actualizada ✅')));
    await _load();
  }
}

/// Formulario mínimo dentro del diálogo: solo el nombre.
/// Con [initial] renombra la categoría en vez de crear una nueva.
class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({this.initial});

  /// Categoría a editar; null = creación.
  final Category? initial;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final TextEditingController _nameController;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    // Limpia errores de envíos anteriores al abrir el diálogo.
    Future.microtask(
      () => ref.read(adminViewModelProvider.notifier).clearMessages(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(adminViewModelProvider.notifier);
    final initial = widget.initial;
    final ok = initial == null
        ? await notifier.createCategory(name)
        : await notifier.updateCategory(id: initial.id, name: name);
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(adminViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. VDC',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (panel.submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            panel.submitError!,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        AdminDialogActions(
          confirmLabel: _isEditing ? 'Guardar cambios' : 'Crear categoría',
          confirmIcon: _isEditing ? Icons.check : Icons.add,
          isSubmitting: panel.isSubmitting,
          onConfirm: _submit,
        ),
      ],
    );
  }
}
