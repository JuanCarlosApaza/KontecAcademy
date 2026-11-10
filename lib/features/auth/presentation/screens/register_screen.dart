import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_button.dart';

/// REGISTRO: /registro
///
/// Crea la cuenta en Supabase Auth (email + contraseña + nombre).
/// Si la confirmación de email está activada en Supabase, se avisa al
/// usuario que revise su correo.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  /// País elegido: define el prefijo del dropdown de código.
  CountryCode _country = defaultCountry();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _redirect =>
      GoRouterState.of(context).uri.queryParameters['redirect'] ?? '/';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phoneDigits = _phoneController.text.trim();
    final viewModel = ref.read(authViewModelProvider.notifier);
    final (result, failure) = await viewModel.signUpWithEmail(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: '+${_country.dial} $phoneDigits',
    );

    if (!mounted) return;

    if (failure != null) {
      // Error del registro → alerta (antes inline).
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'No se pudo crear la cuenta',
        message: failure.message,
      );
      return;
    }

    if (result.emailConfirmationRequired) {
      // Sin sesión todavía: hay que confirmar el correo.
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Revisa tu correo',
        message:
            'Enviamos un enlace de confirmación a '
            '${_emailController.text.trim()}. '
            'Confirma tu cuenta y luego inicia sesión.',
      );
      if (mounted) context.go('/login');
      return;
    }

    // Cuenta creada con sesión activa → seguimos al destino original.
    context.go(_redirect);
  }

  Future<void> _signInWithGoogle() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 800;

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
                          'Crea tu cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Regístrate para tomar tus cursos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            'Nombre completo',
                            Icons.person_outline,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 3)
                              ? 'Ingresa tu nombre completo'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // País → define el prefijo del dropdown de código.
                        DropdownButtonFormField<CountryCode>(
                          // Key por selección: el widget se recrea al
                          // cambiar de país (patrón del form admin).
                          key: ValueKey('country-${_country.iso}'),
                          initialValue: _country,
                          decoration: _inputDecoration('País', Icons.public),
                          items: [
                            for (final country in kCountriesSorted)
                              DropdownMenuItem(
                                value: country,
                                child: Text(
                                  '${country.flag} ${country.name}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                          ],
                          onChanged: (country) => setState(() {
                            if (country != null) _country = country;
                          }),
                        ),
                        const SizedBox(height: 16),
                        // En pantallas angostas (< 480) código y teléfono
                        // se apilan: en fila el dropdown del código solo
                        // recibe ~34 px y desborda (RenderFlex +17 px).
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final dialField = SizedBox(
                              width: 118,
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('dial-${_country.dial}'),
                                initialValue: _country.dial,
                                decoration: _inputDecoration(
                                  'Código',
                                  Icons.phone_outlined,
                                ),
                                items: [
                                  for (final dial in kCountryDialCodes)
                                    DropdownMenuItem(
                                      value: dial,
                                      child: Text(
                                        '+$dial',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                ],
                                onChanged: (dial) => setState(() {
                                  if (dial == null) return;
                                  _country = kCountries.firstWhere(
                                    (country) => country.dial == dial,
                                    orElse: () => _country,
                                  );
                                }),
                              ),
                            );

                            final phoneField = TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _inputDecoration(
                                'Teléfono',
                                Icons.smartphone_outlined,
                              ),
                              validator: (value) {
                                final digits = (value ?? '').trim();
                                if (digits.length < 6) {
                                  return 'Teléfono muy corto';
                                }
                                return null;
                              },
                            );

                            if (constraints.maxWidth < 480) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dialField,
                                  const SizedBox(height: 10),
                                  phoneField,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Código telefónico (sincronizado con el país).
                                dialField,
                                const SizedBox(width: 10),
                                Expanded(child: phoneField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: _inputDecoration(
                            'Correo electrónico',
                            Icons.mail_outline,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Ingresa tu correo';
                            if (!email.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration:
                              _inputDecoration(
                                'Contraseña (mínimo 6 caracteres)',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                              ? 'Mínimo 6 caracteres'
                              : null,
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
                                : const Text('Crear cuenta'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o regístrate con',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GoogleButton(
                          onPressed: state.isLoading ? null : _signInWithGoogle,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            TextButton(
                              onPressed: () => context.go(
                                '/login?redirect=${Uri.encodeComponent(_redirect)}',
                              ),
                              child: const Text(
                                'Inicia sesión',
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
