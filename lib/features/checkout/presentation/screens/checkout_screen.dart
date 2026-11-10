import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../../domain/entities/checkout_result.dart';
import '../viewmodels/checkout_viewmodel.dart';

/// MODALIDAD DE PAGO: /checkout
///
/// 1. Pide los datos personales (nombre, DNI, teléfono, nacionalidad).
/// 2. Muestra el resumen del carrito y el total.
/// 3. Al confirmar, el backend registra `users` + `enrollments` +
///    `payments` (pendientes de aprobación con ticket).
///
/// El router redirige a /login si no hay sesión.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Peruana');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  /// Rellena nombre y email con la sesión de Supabase (una sola vez).
  void _prefillFromSession(String? fullName, String? email) {
    if (_nameController.text.isEmpty && fullName != null) {
      _nameController.text = fullName;
    }
    if (_emailController.text.isEmpty && email != null) {
      _emailController.text = email;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Capturado ANTES de enviar: el viewmodel limpia el carrito al
    // tener éxito y ya no se podría saber qué se compró.
    final hasMembership = ref
        .read(cartViewModelProvider)
        .any((item) => item.isMembership);

    await ref
        .read(checkoutViewModelProvider.notifier)
        .submit(
          fullName: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          nationality: _nationalityController.text,
          documentNumber: _documentController.text,
        );

    if (!mounted) return;
    final state = ref.read(checkoutViewModelProvider);
    if (state.result != null) {
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: '¡Inscripción registrada!',
        message: hasMembership
            ? 'Recibimos tu pago. Está en verificación manual: al '
                  'aprobarlo tu membresía se activará y tendrás acceso '
                  'a todos los cursos.'
            : 'Recibimos tu pago. Está en verificación manual: cuando sea '
                  'aprobado el curso aparecerá en "Mis cursos" con acceso.',
      );
    } else if (state.error != null) {
      final failure = state.error;
      final sessionExpired =
          failure is ServerFailure && failure.statusCode == 401;

      // Sesión expirada: en vez de dejarlo varado con un error, se
      // lleva al login y de vuelta al checkout para CONTINUAR la compra
      // (el carrito se conserva en el servidor y en local).
      if (sessionExpired && mounted) {
        final relogin = await showAppConfirm(
          context,
          title: 'Tu sesión expiró',
          message: 'Inicia sesión de nuevo para continuar con la compra. '
              'Tu carrito se conserva.',
          confirmText: 'Iniciar sesión',
        );
        if (relogin && mounted) {
          context.go('/login?redirect=/checkout');
        }
        return;
      }

      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'No se pudo registrar el pago',
        message: failure!.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutViewModelProvider);
    final items = ref.watch(cartViewModelProvider);
    final user = ref.watch(authUserProvider).value;
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    _prefillFromSession(user?.displayName, user?.email);

    // Éxito: pantalla de confirmación.
    if (state.isDone) return _SuccessPanel(result: state.result!, items: items);

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _CheckoutHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: items.isEmpty
                    ? const _EmptyCheckout()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PersonalDataForm(
                                      formKey: _formKey,
                                      nameController: _nameController,
                                      emailController: _emailController,
                                      documentController: _documentController,
                                      phoneController: _phoneController,
                                      nationalityController:
                                          _nationalityController,
                                    ),
                                    const SizedBox(height: 24),
                                    _OrderSummary(
                                      items: items,
                                      isLoading: state.isLoading,
                                      error: state.error?.message,
                                      onSubmit: _submit,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _PersonalDataForm(
                                        formKey: _formKey,
                                        nameController: _nameController,
                                        emailController: _emailController,
                                        documentController: _documentController,
                                        phoneController: _phoneController,
                                        nationalityController:
                                            _nationalityController,
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      flex: 5,
                                      child: _OrderSummary(
                                        items: items,
                                        isLoading: state.isLoading,
                                        error: state.error?.message,
                                        onSubmit: _submit,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 48),
                        ],
                      ),
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF1F1A17)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 800 ? 24 : 72,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: const Text(
          'Finalizar inscripción',
          style: TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Formulario de datos personales.
class _PersonalDataForm extends StatelessWidget {
  const _PersonalDataForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.documentController,
    required this.phoneController,
    required this.nationalityController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController documentController;
  final TextEditingController phoneController;
  final TextEditingController nationalityController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.person_outline,
            title: 'Datos personales',
            subtitle: 'Necesarios para emitir tu certificado y contacto.',
          ),
          const SizedBox(height: 16),
          _field(
            controller: nameController,
            label: 'Nombres y apellidos *',
            icon: Icons.badge_outlined,
            validator: (value) => (value == null || value.trim().length < 3)
                ? 'Ingresa tu nombre completo'
                : null,
          ),
          const SizedBox(height: 14),
          _field(
            controller: emailController,
            label: 'Correo electrónico *',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Ingresa tu correo';
              if (!email.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // En pantallas angostas (< 560) los dos campos se apilan:
          // a ~149 px la etiqueta con icono queda recortada.
          LayoutBuilder(
            builder: (context, constraints) {
              final documentField = _field(
                controller: documentController,
                label: 'DNI / Documento *',
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.trim().length < 6)
                    ? 'Mínimo 6 dígitos'
                    : null,
              );
              final phoneField = _field(
                controller: phoneController,
                label: 'Teléfono',
                icon: Icons.phone_iphone,
                keyboardType: TextInputType.phone,
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    documentField,
                    const SizedBox(height: 14),
                    phoneField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: documentField),
                  const SizedBox(width: 14),
                  Expanded(child: phoneField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _field(
            controller: nationalityController,
            label: 'Nacionalidad',
            icon: Icons.public,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

/// Resumen del pedido + botón de confirmación.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
  });

  final List<CartItem> items;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final total = items.totalPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Resumen del pedido',
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatDollars(item.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                formatDollars(total),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'El pago se valida con transferencia o yape/plin '
            '(nuestro equipo te contactará con el ticket).',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirmar inscripción'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Confirmación tras registrar la inscripción.
class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.result, required this.items});

  final CheckoutResult result;
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Inscripción registrada!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Recibimos tus datos y tu(s) curso(s). '
                      'Te contactaremos para confirmar el pago; '
                      'mientras tanto, tu inscripción está '
                      '"pendiente de pago".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total: ${formatDollars(result.total)} · '
                      '${result.enrollmentIds.length} curso(s)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.go('/capacitaciones'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Seguir explorando cursos'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay cursos en tu carrito.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/capacitaciones'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver capacitaciones'),
          ),
        ],
      ),
    );
  }
}
