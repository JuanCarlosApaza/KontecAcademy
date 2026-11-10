import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/domain/entities/membership_plan.dart';
import '../../domain/entities/admin_user_record.dart';
import '../viewmodels/admin_providers.dart';
import '../../admin_injector.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

/// MEMBRESÍAS: /admin/membresias
///
/// Dos bloques: las membresías de los usuarios (otorgar manual,
/// revocar/reactivar) y los3 planes (nombre, meses, precio, activo).
class AdminMembershipsScreen extends ConsumerStatefulWidget {
  const AdminMembershipsScreen({super.key});

  @override
  ConsumerState<AdminMembershipsScreen> createState() =>
      _AdminMembershipsScreenState();
}

class _AdminMembershipsScreenState
    extends ConsumerState<AdminMembershipsScreen> {
  List<MembershipRecord> _memberships = const [];
  List<MembershipPlan> _plans = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (memberships, membershipsFailure) = await ref.read(
      listMembershipsProvider,
    )(NoParams());
    final (plans, plansFailure) = await ref.read(listPlansProvider)(NoParams());
    if (!mounted) return;
    setState(() {
      _memberships = membershipsFailure == null ? memberships : const [];
      _plans = plansFailure == null ? plans : const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(permissionProvider('courses:view'))) {
      return const AdminAccessDenied(
        message:
            'Tu cuenta no tiene el permiso "courses:view" para '
            'gestionar las membresías.',
        buttonLabel: 'Volver al sitio',
        destination: '/',
      );
    }
    final canManage = ref.watch(permissionProvider('courses:create'));

    return AdminPage(
      title: 'Membresías',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _membershipsCard(canManage),
          const SizedBox(height: 20),
          _plansCard(canManage),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Membresías de los usuarios ─────────────────────────────────

  Widget _membershipsCard(bool canManage) {
    return AdminTableCard<MembershipRecord>(
      title: 'Membresías',
      subtitle: '${_memberships.length} en total',
      isLoading: _loading,
      items: _memberships,
      searchHint: 'Buscar por email o plan…',
      searchText: (m) => '${m.userEmail} ${m.planName}',
      emptyMessage:
          'Aún no hay membresías. Otorga la primera con el botón '
          '"Otorgar membresía".',
      actions: [
        IconButton(
          tooltip: 'Recargar',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
        if (canManage)
          FilledButton.icon(
            onPressed: _openGrantDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Otorgar membresía'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
      columns: [
        AdminColumn<MembershipRecord>(
          label: 'Usuario',
          width: 240,
          sortValue: (m) => m.userEmail.toLowerCase(),
          cell: (m) => Text(
            m.userEmail.isEmpty ? m.userId : m.userEmail,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AdminColumn<MembershipRecord>(
          label: 'Plan',
          width: 170,
          sortValue: (m) => m.planName.toLowerCase(),
          cell: (m) => Text(
            '${m.planName} · ${m.months}m',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        AdminColumn<MembershipRecord>(
          label: 'Inicio',
          width: 110,
          sortValue: (m) => m.startDate ?? '',
          cell: (m) => Text(
            _formatIso(m.startDate),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
        AdminColumn<MembershipRecord>(
          label: 'Fin',
          width: 110,
          sortValue: (m) => m.endDate ?? '',
          cell: (m) => Text(
            _formatIso(m.endDate),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
        AdminColumn<MembershipRecord>(
          label: 'Estado',
          width: 120,
          sortValue: (m) => m.status,
          cell: (m) => enrollmentStatusBadge(m.status),
        ),
        AdminColumn<MembershipRecord>(
          label: 'Acciones',
          width: 110,
          isActions: true,
          cell: (m) =>
              canManage ? _membershipActions(m) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _membershipActions(MembershipRecord m) {
    // Vigente o en pago → se puede revocar; el resto → reactivar.
    final canRevoke = m.status == 'active' || m.status == 'pending_payment';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canRevoke)
          AdminActionButton(
            tooltip: 'Revocar membresía',
            icon: Icons.block_outlined,
            destructive: true,
            onPressed: () => _changeStatus(m, 'revoked'),
          )
        else
          AdminActionButton(
            tooltip: 'Reactivar membresía',
            icon: Icons.restart_alt,
            onPressed: () => _changeStatus(m, 'active'),
          ),
      ],
    );
  }

  Future<void> _changeStatus(MembershipRecord m, String status) async {
    final confirmed = await showAppConfirm(
      context,
      title: status == 'revoked'
          ? '¿Revocar la membresía?'
          : '¿Reactivar la membresía?',
      message: status == 'revoked'
          ? '${m.userEmail} perderá el acceso a todos los cursos al '
                'revocarla. Esta acción se puede deshacer reactivándola.'
          : '${m.userEmail} volverá a tener acceso a todos los cursos '
                'hasta ${_formatIso(m.endDate)}.',
      confirmText: status == 'revoked' ? 'Revocar' : 'Reactivar',
    );
    if (!confirmed || !mounted) return;

    final result = await runWithAppLoading<(MembershipRecord?, Failure?)>(
      context,
      ref.read(updateMembershipProvider)(
        UpdateMembershipParams(id: m.id, patch: {'status': status}),
      ),
      text: 'Actualizando membresía…',
    );
    if (!mounted || result == null) return;
    final (updated, failure) = result;

    if (failure != null) {
      await showAppError(
        context,
        title: 'No se pudo actualizar',
        message: failure.message,
      );
      return;
    }
    if (updated == null) {
      await showAppWarning(
        context,
        title: 'Membresía no encontrada',
        message: 'Puede que ya se haya actualizado.',
      );
    } else {
      await showAppSuccess(
        context,
        title: status == 'revoked'
            ? 'Membresía revocada'
            : 'Membresía reactivada',
        message: updated.userEmail,
      );
    }
    await _load();
  }

  Future<void> _openGrantDialog() async {
    final granted = await showAdminDialog<bool>(
      context: context,
      title: 'Otorgar membresía',
      subtitle: 'Se activa con fechas calculadas desde hoy.',
      width: 520,
      child: const _GrantForm(),
    );

    if (granted != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Membresía otorgada',
      message: 'Ya tiene acceso a todos los cursos.',
    );
    await _load();
  }

  // ── Planes (los3 tipos) ────────────────────────────────────────

  Widget _plansCard(bool canManage) {
    return AdminTableCard<MembershipPlan>(
      title: 'Planes de membresía',
      subtitle: '${_plans.length} (los tipos que se pueden comprar)',
      isLoading: _loading,
      items: _plans,
      searchHint: 'Buscar por nombre…',
      searchText: (p) => '${p.name} ${p.slug}',
      emptyMessage: 'No hay planes creados.',
      actions: [
        if (canManage)
          FilledButton.icon(
            onPressed: _openCreatePlanDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo plan'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
      columns: [
        AdminColumn<MembershipPlan>(
          label: 'Nombre',
          width: 240,
          sortValue: (p) => p.name.toLowerCase(),
          cell: (p) => Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.name,
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
        AdminColumn<MembershipPlan>(
          label: 'Duración',
          width: 110,
          sortValue: (p) => p.months,
          cell: (p) => Text(
            p.months == 12 ? '1 año' : '${p.months} meses',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        AdminColumn<MembershipPlan>(
          label: 'Precio',
          width: 120,
          sortValue: (p) => p.price,
          cell: (p) => Text(
            formatDollars(p.price),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        AdminColumn<MembershipPlan>(
          label: 'Estado',
          width: 110,
          sortValue: (p) => p.isActive ? 0 : 1,
          cell: (p) => AdminBadge(
            label: p.isActive ? 'Activo' : 'Inactivo',
            background: p.isActive
                ? const Color(0xFFECFDF5)
                : const Color(0xFFF1F5F9),
            icon: p.isActive
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
            iconColor: p.isActive
                ? const Color(0xFF059669)
                : AppColors.textMuted,
          ),
        ),
        AdminColumn<MembershipPlan>(
          label: 'Acciones',
          width: 110,
          isActions: true,
          cell: (p) => canManage
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminActionButton(
                      tooltip: 'Editar plan',
                      icon: Icons.edit_outlined,
                      onPressed: () => _openEditPlanDialog(p),
                    ),
                    const SizedBox(width: 6),
                    AdminActionButton(
                      tooltip: 'Eliminar plan',
                      icon: Icons.delete_outline,
                      destructive: true,
                      onPressed: () => _confirmDeletePlan(p),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _openCreatePlanDialog() async {
    final created = await showAdminDialog<bool>(
      context: context,
      title: 'Nuevo plan',
      subtitle: 'Ej. Mensual (1 mes), Semestral (6) o Anual (12).',
      width: 460,
      child: const _PlanForm(),
    );

    if (created != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Plan creado',
      message: 'Ya aparece en /membresias para poder comprarlo.',
    );
    await _load();
  }

  Future<void> _openEditPlanDialog(MembershipPlan plan) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: 'Editar plan',
      subtitle: plan.name,
      width: 460,
      child: _PlanForm(initial: plan),
    );

    if (saved != true || !mounted) return;
    await showAppSuccess(
      context,
      title: 'Plan actualizado',
      message: 'Los cambios ya están en /membresias.',
    );
    await _load();
  }

  Future<void> _confirmDeletePlan(MembershipPlan plan) async {
    final confirmed = await showAppConfirm(
      context,
      title: '¿Eliminar el plan "${plan.name}"?',
      message:
          'Las membresías existentes NO se borran, pero no se '
          'podrá comprar de nuevo. Esta acción no se puede deshacer.',
      confirmText: 'Eliminar plan',
    );
    if (!confirmed || !mounted) return;

    final result = await runWithAppLoading<(bool, Failure?)>(
      context,
      ref.read(deletePlanProvider)(plan.id),
      text: 'Eliminando plan…',
    );
    if (!mounted || result == null) return;
    final (wasDeleted, delFailure) = result;

    if (delFailure != null) {
      await showAppError(
        context,
        title: 'No se pudo eliminar',
        message: delFailure.message,
      );
      return;
    }

    if (wasDeleted == false) {
      await showAppWarning(
        context,
        title: 'Plan no encontrado',
        message: 'Puede que ya se haya eliminado.',
      );
    } else {
      await showAppSuccess(
        context,
        title: 'Plan eliminado',
        message: plan.name,
      );
    }
    await _load();
  }

  /// ISO (yyyy-MM-dd…) → dd/MM/yyyy ('—' si no hay fecha).
  String _formatIso(String? iso) {
    final date = DateTime.tryParse(iso ?? '')?.toLocal();
    if (date == null) return '—';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

/// Formulario de otorgamiento manual (usuario + plan).
class _GrantForm extends ConsumerStatefulWidget {
  const _GrantForm();

  @override
  ConsumerState<_GrantForm> createState() => _GrantFormState();
}

class _GrantFormState extends ConsumerState<_GrantForm> {
  String? _userId;
  String? _planId;
  bool _submitting = false;
  bool _loading = true;
  String? _error;
  List<AdminUserRecord> _users = const [];
  List<MembershipPlan> _plans = const [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final (users, usersFailure) = await ref.read(getAdminUsersProvider)(
      NoParams(),
    );
    final (plans, plansFailure) = await ref.read(listPlansProvider)(NoParams());
    if (!mounted) return;
    setState(() {
      _users = usersFailure == null ? users : const [];
      _plans = plansFailure == null ? plans : const [];
      _loading = false;
      if (usersFailure != null || plansFailure != null) {
        _error = 'No se pudieron cargar los usuarios o los planes.';
      }
    });
  }

  Future<void> _submit() async {
    if (_userId == null || _planId == null) {
      setState(() => _error = 'Elige el usuario y el plan.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final (granted, failure) = await ref.read(grantMembershipProvider)(
      AdminGrantInput(userId: _userId!, planId: _planId!),
    );
    if (!mounted) return;
    if (failure != null || granted == null) {
      setState(() {
        _submitting = false;
        _error = failure?.message ?? 'No se pudo otorgar la membresía.';
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _userId,
          decoration: const InputDecoration(
            labelText: 'Usuario *',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final user in _users)
              DropdownMenuItem(
                value: user.id,
                child: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          onChanged: (id) => setState(() => _userId = id),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _planId,
          decoration: const InputDecoration(
            labelText: 'Plan *',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final plan in _plans)
              DropdownMenuItem(
                value: plan.id,
                child: Text('${plan.name} · ${formatDollars(plan.price)}'),
              ),
          ],
          onChanged: (id) => setState(() => _planId = id),
        ),
        const SizedBox(height: 6),
        const Text(
          'La membresía queda ACTIVA desde hoy con la duración del plan.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
          confirmLabel: 'Otorgar',
          confirmIcon: Icons.workspace_premium_outlined,
          isSubmitting: _submitting,
          onConfirm: _submit,
        ),
      ],
    );
  }
}

/// Formulario de plan (crear / editar).
class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({this.initial});

  final MembershipPlan? initial;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _monthsController;
  late final TextEditingController _priceController;
  bool _isActive = true;
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _imageUrl;
  String? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _monthsController = TextEditingController(text: '${initial?.months ?? 12}');
    _priceController = TextEditingController(
      text: initial != null ? '${initial.price}' : '',
    );
    _isActive = initial?.isActive ?? true;
    _imageUrl = initial?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Selecciona una imagen del sistema y la sube al bucket público
  /// "courses" (POST /admin/upload-image); guarda la URL devuelta.
  /// El bucket solo admite JPG/PNG, así que el selector se limita a eso.
  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.isNotEmpty ?? false ? result!.files.first : null;
    if (file == null) return;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty || !mounted) return;

    final contentType = (file.extension ?? '').toLowerCase() == 'png'
        ? 'image/png'
        : 'image/jpeg';

    setState(() => _uploadingImage = true);
    final url = await runWithAppLoading<String?>(
      context,
      ref
          .read(adminViewModelProvider.notifier)
          .uploadImage(
            bytes: bytes,
            filename: file.name,
            contentType: contentType,
          ),
      text: 'Subiendo imagen…',
    );
    if (!mounted) return;

    final failure = ref.read(adminViewModelProvider).submitError;
    setState(() {
      _uploadingImage = false;
      if (url != null) _imageUrl = url;
    });
    if (url == null) {
      ref.read(adminViewModelProvider.notifier).clearMessages();
      await showAppError(
        context,
        title: 'No se pudo subir la imagen',
        message: failure ?? 'Error inesperado del servidor.',
      );
      return;
    }
    await showAppSuccess(
      context,
      title: 'Imagen subida',
      message: 'Se guardó en el bucket "courses".',
    );
  }

  void _removeImage() {
    setState(() => _imageUrl = null);
  }

  /// Campo de imagen: preview + botones de subir/quitar.
  Widget _imageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de la tarjeta',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _imageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploadingImage ? null : _pickAndUploadImage,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                _imageUrl == null ? 'Subir imagen' : 'Cambiar imagen',
              ),
            ),
            if (_imageUrl != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _removeImage,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Quitar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Aparece arriba en la tarjeta de /membresias. Recomendado: '
          'horizontal, mínimo 800 px de ancho.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }

    final months = int.tryParse(_monthsController.text.trim()) ?? 0;
    if (months < 1) {
      setState(() => _error = 'La duración debe ser al menos1 mes.');
      return;
    }
    final price = double.tryParse(_priceController.text.trim()) ?? -1;
    if (price < 0) {
      setState(() => _error = 'El precio debe ser un número ≥ 0.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final input = AdminPlanInput(
      name: name,
      months: months,
      price: price,
      isActive: _isActive,
      sortOrder: widget.initial?.sortOrder ?? 0,
      imageUrl: (_imageUrl?.trim().isEmpty ?? true) ? null : _imageUrl!.trim(),
    );

    final (saved, failure) = _isEditing
        ? await ref.read(updatePlanProvider)(
            UpdatePlanParams(id: widget.initial!.id, input: input),
          )
        : await ref.read(createPlanProvider)(input);

    if (!mounted) return;
    if (failure != null || (saved == null && _isEditing)) {
      setState(() {
        _submitting = false;
        _error = failure?.message ?? 'El plan ya no existe.';
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
          autofocus: !_isEditing,
          decoration: const InputDecoration(
            labelText: 'Nombre *',
            hintText: 'Ej. Semestral (6 meses)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meses *',
                  hintText: '1 / 6 / 12',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio (USD) *',
                  hintText: 'Ej. 149',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Activo (visible para comprar)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          value: _isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (value) => setState(() => _isActive = value),
        ),
        const SizedBox(height: 6),
        _imageField(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        AdminDialogActions(
          confirmLabel: _isEditing ? 'Guardar cambios' : 'Crear plan',
          confirmIcon: _isEditing ? Icons.check : Icons.add,
          isSubmitting: _submitting,
          onConfirm: _submit,
        ),
      ],
    );
  }
}
