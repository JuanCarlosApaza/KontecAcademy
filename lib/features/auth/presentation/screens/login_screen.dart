import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../admin/presentation/viewmodels/admin_providers.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_button.dart';

/// LOGIN: /login
///
/// Email + contraseña (Supabase) o "Continuar con Google".
/// Acepta ?redirect=... para volver a la página original tras entrar
/// (lo usa el guard "agregar al carrito" cuando no había sesión).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// URL a la que volver tras autenticarse (por defecto: inicio).
  String get _redirect =>
      GoRouterState.of(context).uri.queryParameters['redirect'] ?? '/';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_ensureConfigured()) return;

    final viewModel = ref.read(authViewModelProvider.notifier);
    final ok = await viewModel.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!ok && mounted) {
      final message =
          ref.read(authViewModelProvider).error?.message ??
          'Revisa tu correo y contraseña.';
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'No se pudo iniciar sesión',
        message: message,
      );
    }

    if (!ok || !mounted) return;
    await _goAfterLogin();
  }

  /// Destino tras iniciar sesión:
  ///  * ?redirect=... explícito (ej: "agregar al carrito" → /checkout).
  ///  * rol "admin" → dashboard del panel.
  ///  * el resto → inicio.
  /// Si el backend no responde (roles), sin errores: se va al inicio.
  Future<void> _goAfterLogin() async {
    final explicitRedirect = GoRouterState.of(context)
        .uri
        .queryParameters['redirect'];

    bool isAdmin = false;
    try {
      // Fuerza una consulta fresca a /me con el token recién obtenido.
      ref.invalidate(adminRolesProvider);
      final roles = await ref.read(adminRolesProvider.future);
      isAdmin = roles.contains('admin');
    } catch (_) {
      isAdmin = false;
    }

    if (!mounted) return;

    final destination =
        (explicitRedirect != null && explicitRedirect.isNotEmpty)
        ? explicitRedirect
        : isAdmin
        ? '/admin'
        : '/';
    context.go(destination);
  }

  Future<void> _signInWithGoogle() async {
    if (!_ensureConfigured()) return;

    final failure = await ref
        .read(authViewModelProvider.notifier)
        .signInWithGoogle();

    if (failure != null && mounted) {
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'No se pudo iniciar con Google',
        message: failure.message,
      );
    }
    // En web la app sale con el navegador; al volver, authUserProvider
    // emite el usuario y el router lo lleva al destino.
  }

  /// Aviso claro si falta la clave publishable de Supabase.
  bool _ensureConfigured() {
    if (SupabaseConfig.isConfigured) return true;
    // ignore: unawaited_futures
    showAppAlert(
      context,
      type: AppAlertType.warning,
      title: 'Falta configurar Supabase',
      message:
          'Pega la clave publishable en '
          'lib/core/config/supabase_config.dart',
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    // "Recuérdame": precarga el correo guardado la primera vez.
    if (state.savedEmail != null && _emailController.text.isEmpty) {
      _emailController.text = state.savedEmail!;
    }

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 400),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: 48,
                ),
                // maxWidth explícito en vez de width fijo: en
                // pantallas angostas la tarjeta se ajusta al ancho
                // disponible sin depender del clamp implícito.
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accede para inscribirte a tus cursos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _EmailField(controller: _emailController),
                        const SizedBox(height: 16),
                        _PasswordField(
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _RememberMeRow(
                          value: state.rememberMe,
                          onChanged: (value) => ref
                              .read(authViewModelProvider.notifier)
                              .setRememberMe(value),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: state.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: state.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _DividerWithLabel(label: 'o continúa con'),
                        const SizedBox(height: 20),
                        GoogleButton(
                          onPressed: state.isLoading ? null : _signInWithGoogle,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No tienes cuenta?',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            TextButton(
                              onPressed: () => context.go(
                                '/registro?redirect=${Uri.encodeComponent(_redirect)}',
                              ),
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: _inputDecoration('Correo electrónico', Icons.mail_outline),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return 'Ingresa tu correo';
        if (!email.contains('@')) return 'Correo no válido';
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.password],
      decoration: _inputDecoration('Contraseña', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textMuted,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (value) =>
          (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (newValue) => onChanged(newValue ?? false),
          ),
        ),
        const Text(
          'Recuérdame',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _DividerWithLabel extends StatelessWidget {
  const _DividerWithLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
