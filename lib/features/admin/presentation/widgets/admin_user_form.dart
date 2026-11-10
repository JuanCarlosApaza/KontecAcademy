import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/admin_providers.dart';
import 'admin_dialog.dart';

/// Datos de un usuario para precargar el formulario de EDICIÓN.
class AdminUserEditData {
  const AdminUserEditData({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;

  /// Rol actual ('' = sin rol).
  final String role;

  /// false = cuenta desactivada (borrado lógico; nada se borra).
  final bool isActive;
}

/// Formulario reutilizable de usuario (nombre, email, teléfono,
/// contraseña y rol). Se usa dentro de `showAdminDialog` desde las
/// pantallas de Usuarios y Estudiantes.
///
/// * Sin [initial]: modo CREACIÓN (alta de cuenta nueva).
/// * Con [initial]: modo EDICIÓN (perfil, rol y estado; el email es
///   solo lectura y no se pide contraseña).
///
/// Al guardar con éxito cierra el diálogo con `true`.
class AdminUserForm extends ConsumerStatefulWidget {
  const AdminUserForm({super.key, this.fixedRole, this.initial});

  /// Si se indica, el rol no se puede elegir (p. ej. 'student').
  final String? fixedRole;

  /// Si se indica, el formulario edita ese usuario en vez de crear uno.
  final AdminUserEditData? initial;

  @override
  ConsumerState<AdminUserForm> createState() => _AdminUserFormState();
}

class _AdminUserFormState extends ConsumerState<AdminUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _role;
  late bool _isActive;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _role = initial?.role.isNotEmpty == true
        ? initial!.role
        : (widget.fixedRole ?? 'student');
    _isActive = initial?.isActive ?? true;
    _fullNameController.text = initial?.fullName ?? '';
    _emailController.text = initial?.email ?? '';
    _phoneController.text = initial?.phone ?? '';
    // Limpia errores de envíos anteriores al abrir el diálogo.
    Future.microtask(
      () => ref.read(adminViewModelProvider.notifier).clearMessages(),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(adminViewModelProvider.notifier);
    final bool ok;
    final initial = widget.initial;

    if (initial == null) {
      ok = await notifier.createUser(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        role: _role,
      );
    } else {
      ok = await notifier.updateUser(
        id: initial.id,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        role: _role,
        isActive: _isActive,
      );
    }

    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(adminViewModelProvider);
    final wide = MediaQuery.sizeOf(context).width >= 560;

    final fullName = _field(
      controller: _fullNameController,
      label: 'Nombre completo',
      hint: 'Ej. Ana Torres',
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
    );
    final email = _field(
      controller: _emailController,
      label: 'Email',
      hint: 'Ej. ana@ejemplo.com',
      keyboardType: TextInputType.emailAddress,
      enabled: !_isEditing,
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Ingresa el email';
        if (!value.contains('@')) return 'El email no es válido';
        return null;
      },
    );
    final phone = _field(
      controller: _phoneController,
      label: 'Teléfono (opcional)',
      hint: 'Ej. 999888777',
      keyboardType: TextInputType.phone,
    );
    final password = _field(
      controller: _passwordController,
      label: 'Contraseña temporal',
      hint: 'Mínimo 6 caracteres',
      obscureText: true,
      validator: (v) => (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fullName),
                const SizedBox(width: 14),
                Expanded(child: email),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: phone),
                const SizedBox(width: 14),
                // La contraseña solo aplica al crear la cuenta.
                Expanded(child: _isEditing ? const SizedBox() : password),
              ],
            ),
          ] else ...[
            fullName,
            const SizedBox(height: 14),
            email,
            const SizedBox(height: 14),
            phone,
            if (!_isEditing) ...[const SizedBox(height: 14), password],
          ],
          const SizedBox(height: 14),

          // Rol (fijo o elegible).
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Rol',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'student', child: Text('Estudiante')),
              DropdownMenuItem(value: 'teacher', child: Text('Docente')),
              DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              DropdownMenuItem(value: '', child: Text('Sin rol')),
            ],
            onChanged: (widget.fixedRole == null && !_isEditing)
                ? null
                : (value) => setState(() => _role = value ?? 'student'),
          ),
          const SizedBox(height: 14),

          // Estado de la cuenta (solo al editar): desactivar es un
          // borrado LÓGICO, la cuenta y sus datos se conservan.
          if (_isEditing) ...[
            SwitchListTile(
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Cuenta activa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: const Text(
                'Al desactivar, el usuario deja de poder iniciar sesión. '
                'No se elimina ningún dato.',
                style: TextStyle(fontSize: 12.5),
              ),
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
          ],

          if (panel.submitError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                panel.submitError!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
              ),
            ),

          AdminDialogActions(
            confirmLabel: _isEditing
                ? 'Guardar cambios'
                : widget.fixedRole == 'student'
                ? 'Crear estudiante'
                : 'Crear usuario',
            confirmIcon: _isEditing ? Icons.check : Icons.person_add_alt_1,
            isSubmitting: panel.isSubmitting,
            onConfirm: _submit,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
    validator: validator,
  );
}
