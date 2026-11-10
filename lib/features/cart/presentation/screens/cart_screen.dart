import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/login_required_dialog.dart';
import '../../../landing/presentation/widgets/insight_navbar.dart';
import '../../../landing/presentation/widgets/site_footer.dart';
import '../../../landing/presentation/widgets/whatsapp_button.dart';
import '../../domain/entities/cart_item.dart';
import '../viewmodels/cart_viewmodel.dart';

/// CARRITO: /carrito
///
/// Lista los cursos agregados, permite quitarlos y pasa al pago.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartViewModelProvider);
    final total = ref.watch(
      cartViewModelProvider.select((list) => list.totalPrice),
    );

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _CartHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: items.isEmpty
                    ? const _EmptyCart()
                    : _CartList(items: items, total: total),
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader();

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
        constraints: const BoxConstraints(maxWidth: 900),
        child: const Text(
          'Mi carrito',
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

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
            'Tu carrito está vacío.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega cursos desde el catálogo de capacitaciones.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
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

class _CartList extends ConsumerWidget {
  const _CartList({required this.items, required this.total});

  final List<CartItem> items;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          _CartItemTile(item: item),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                formatDollars(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: () async {
              // Doble check: por si entraron por URL directa sin sesión.
              // Tras el login vuelve DIRECTO a /checkout: la compra
              // continúa en vez de botarlo al carrito o al inicio.
              final ok = await ensureAuthenticated(
                context,
                ref,
                action: 'pasar a la modalidad de pago',
                redirect: '/checkout',
              );
              if (!ok || !context.mounted) return;
              context.go('/checkout');
            },
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
            child: const Text('Continuar con el pago'),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = item.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 56,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _PlaceholderIcon(),
                    )
                  : const _PlaceholderIcon(),
            ),
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isPath || item.isMembership) ...[
                // Combo o membresía: el precio ya incluye lo pactado.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isPath ? 'Ruta · con descuento' : 'Membresía',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (item.modality.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.modality,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          );

          final price = Text(
            formatDollars(item.price),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          );

          final delete = IconButton(
            tooltip: 'Quitar del carrito',
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: () => ref
                .read(cartViewModelProvider.notifier)
                .removeItem(item.courseId),
          );

          // En filas angostas el precio baja al bloque de texto: en
          // una Row completa el título se aplasta a ~0 px.
          if (constraints.maxWidth < 480) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [info, const SizedBox(height: 6), price],
                  ),
                ),
                delete,
              ],
            );
          }

          return Row(
            children: [
              image,
              const SizedBox(width: 14),
              Expanded(child: info),
              const SizedBox(width: 12),
              price,
              delete,
            ],
          );
        },
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.play_circle_outline, color: AppColors.primary),
    );
  }
}
