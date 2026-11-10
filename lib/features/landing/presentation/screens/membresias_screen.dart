import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../auth/presentation/widgets/login_required_dialog.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../domain/entities/membership_plan.dart';
import '../viewmodels/membresias_viewmodel.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// MEMBRESÍAS: /membresias
///
/// Los3 tipos de membresía (mensual /6 meses / anual) con su precio;
/// quien compra una accede a TODOS los cursos mientras esté vigente.
/// La compra entra al carrito como ítem tipado 'membership' y se
/// aprueba como cualquier ticket (transferencia manual).
class MembershipsScreen extends ConsumerWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(membershipPlansProvider);

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _MembershipsHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: plansAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error is Failure
                              ? error.message
                              : 'No se pudieron cargar los planes.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(membershipPlansProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  data: (plans) => _PlansGrid(plans: plans),
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

/// Banda superior oscura con título de la sección.
class _MembershipsHeader extends StatelessWidget {
  const _MembershipsHeader();

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
        vertical: 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'Membresía ',
                children: [
                  TextSpan(
                    text: 'Kontec Academy',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 34,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Un solo acceso a TODOS los cursos de la plataforma mientras '
              'tu membresía esté vigente. Elige el plan que mejor te quede.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: .85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid responsive de planes: 1 col (móvil) · 3 (≥900).
class _PlansGrid extends StatelessWidget {
  const _PlansGrid({required this.plans});

  final List<MembershipPlan> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Aún no hay planes disponibles.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
        final cardWidth = (width - 16 * (columns - 1)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final plan in plans)
              SizedBox(
                width: cardWidth,
                child: _PlanCard(plan: plan),
              ),
          ],
        );
      },
    );
  }
}

/// Tarjeta de un plan de membresía con su botón de compra.
class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.imageUrl != null && plan.imageUrl!.isNotEmpty)
            _PlanImage(url: plan.imageUrl!),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDollars(plan.price),
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _buy(context, ref),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adquirir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Agrega el plan al carrito (pide sesión si hace falta) con el
  /// spinner de librería y confirma con QuickAlert.
  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final ok = await ensureAuthenticated(
      context,
      ref,
      action: 'adquirir la membresía',
    );
    if (!ok || !context.mounted) return;

    final added = await runWithAppLoading<bool>(
      context,
      ref
          .read(cartViewModelProvider.notifier)
          .addItem(
            CartItem(
              courseId: plan.id,
              title: plan.name,
              price: plan.price,
              type: 'membership',
              modality: 'Membresía',
            ),
          ),
      text: 'Agregando al carrito…',
    );
    if (!context.mounted) return;

    if (added == false) {
      await showAppAlert(
        context,
        type: AppAlertType.info,
        title: 'Este plan ya está en tu carrito',
        message: 'Ve al carrito para continuar con el pago.',
      );
      return;
    }

    await showAppSuccess(
      context,
      title: 'Membresía agregada al carrito',
      message:
          '${plan.name} — ${formatDollars(plan.price)}. '
          'Se activará al aprobar el pago.',
    );
  }
}

/// Imagen de la tarjeta: se muestra COMPLETA (alto según su propia
/// relación de aspecto, sin recorte) arriba del contenedor del plan.
class _PlanImage extends StatelessWidget {
  const _PlanImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        height: 160,
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(
          Icons.workspace_premium_outlined,
          size: 40,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
