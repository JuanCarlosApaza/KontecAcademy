import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../auth/presentation/widgets/login_required_dialog.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../domain/entities/learning_path.dart';
import '../viewmodels/rutas_viewmodel.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/ruta_card.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// DETALLE DE RUTA: /rutas/:slug
///
/// Banda oscura con datos de la ruta + lista ORDENADA de sus cursos
/// (cada uno navega a /capacitaciones/:id) + beneficios + nota de que
/// los cursos se compran por separado.
class RutaDetailScreen extends ConsumerWidget {
  const RutaDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rutaDetailProvider(slug));

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _StatusBox(
              icon: Icons.error_outline,
              message: error is Failure
                  ? error.message
                  : 'No se pudo cargar la ruta.',
              buttonLabel: 'Reintentar',
              onPressed: () => ref.invalidate(rutaDetailProvider(slug)),
            ),
            data: (path) => path == null
                ? _StatusBox(
                    icon: Icons.signpost_outlined,
                    message: 'No encontramos esta ruta.',
                    buttonLabel: 'Ver todas las rutas',
                    onPressed: () => context.go('/rutas'),
                  )
                : _RutaBody(path: path),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

/// Cuerpo completo de una ruta existente.
class _RutaBody extends StatelessWidget {
  const _RutaBody({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RutaHeader(path: path),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cursos de la ruta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sigue el orden para avanzar de lo básico a lo avanzado.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (path.courses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Esta ruta todavía no tiene cursos publicados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (var i = 0; i < path.courses.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CourseRow(
                          position: i + 1,
                          course: path.courses[i],
                          onTap: () => context
                              .go('/capacitaciones/${path.courses[i].courseId}'),
                        ),
                      ),
                  const SizedBox(height: 16),
                  _BenefitsPanel(),
                  const SizedBox(height: 20),
                  _BuyRoutePanel(path: path),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Banda oscura: título, descripción y meta de la ruta.
class _RutaHeader extends StatelessWidget {
  const _RutaHeader({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

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
        horizontal: width < 800 ? 24 : 72,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/rutas'),
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              label: const Text(
                'Volver a rutas',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path.title,
              style: const TextStyle(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (path.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                path.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: .85),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.menu_book_outlined,
                  label: path.courses.length == 1
                      ? '1 curso'
                      : '${path.courses.length} cursos',
                ),
                _MetaChip(
                  icon: Icons.schedule,
                  label: '${path.durationHours} horas',
                ),
                _MetaChip(
                  icon: path.modality == 'live'
                      ? Icons.video_camera_front_outlined
                      : Icons.play_circle_outline,
                  label: pathModalityLabel(path.modality),
                ),
                _MetaChip(
                  icon: Icons.calendar_month_outlined,
                  label: 'Acceso ${path.accessMonths} meses',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de un curso de la ruta: número de orden + miniatura + datos.
class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.position,
    required this.course,
    required this.onTap,
  });

  final int position;
  final PathCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: course.imageUrl != null
                      ? Image.network(
                          course.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _RowPlaceholder(),
                        )
                      : const _RowPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${course.hours} h',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (course.level != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1E0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              course.level!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDollars(course.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowPlaceholder extends StatelessWidget {
  const _RowPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDEDED),
      child: const Icon(Icons.school_outlined, size: 22, color: Colors.white),
    );
  }
}

/// Chip de meta sobre la banda oscura.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Beneficios de las rutas (bloque estilo insight-construction).
class _BenefitsPanel extends StatelessWidget {
  const _BenefitsPanel();

  static const _benefits = [
    (Icons.verified_outlined, 'Certificados', 'Un certificado por curso al completarlo.'),
    (Icons.handyman_outlined, 'Aprendizaje práctico', 'Proyectos y casos reales de obra.'),
    (Icons.groups_outlined, 'Comunidad', 'Acceso a la comunidad de profesionales.'),
    (Icons.workspace_premium_outlined, 'Expertos', 'Docentes con experiencia en implementación BIM.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Al completar la ruta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final itemWidth = wide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final (icon, title, subtitle) in _benefits)
                    SizedBox(
                      width: itemWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Precio final + botón "Comprar ruta": agrega el combo al carrito
/// CON la rebaja ya aplicada (el servidor es quien fija el precio al
/// leer) + enlace secundario al catálogo completo.
class _BuyRoutePanel extends ConsumerWidget {
  const _BuyRoutePanel({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDiscount = path.discountPercent > 0;

    final priceBlock = Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Inversión de la ruta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '-${path.discountPercent}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
        if (hasDiscount)
          Text(
            formatDollars(path.totalCoursesPrice),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          formatDollars(path.price),
          style: const TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );

    final buyButton = FilledButton.icon(
      onPressed: () => _buy(context, ref),
      icon: const Icon(Icons.add_shopping_cart, size: 18),
      label: const Text('Comprar ruta'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    );

    final seeAllButton = OutlinedButton.icon(
      onPressed: () => context.go('/capacitaciones'),
      icon: const Icon(Icons.grid_view_outlined, size: 18),
      label: const Text('Ver todos los cursos'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                priceBlock,
                const SizedBox(height: 14),
                buyButton,
                const SizedBox(height: 8),
                seeAllButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: priceBlock),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [buyButton, const SizedBox(height: 8), seeAllButton],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Agrega la ruta al carrito (pide sesión si hace falta) con el
  /// spinner de librería y confirma con QuickAlert.
  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final ok = await ensureAuthenticated(
      context,
      ref,
      action: 'comprar la ruta',
    );
    if (!ok || !context.mounted) return;

    final added = await runWithAppLoading<bool>(
      context,
      ref.read(cartViewModelProvider.notifier).addItem(
        CartItem(
          courseId: path.id,
          title: path.title,
          price: path.price,
          type: 'path',
          modality: pathModalityLabel(path.modality),
          imageUrl: path.coverUrl,
        ),
      ),
      text: 'Agregando la ruta al carrito…',
    );
    if (!context.mounted) return;

    if (added == false) {
      await showAppAlert(
        context,
        type: AppAlertType.info,
        title: 'La ruta ya está en tu carrito',
        message: 'Ve al carrito para continuar con el pago.',
      );
      return;
    }

    await showAppSuccess(
      context,
      title: 'Ruta agregada al carrito',
      message: hasDiscountText(),
    );
  }

  String hasDiscountText() {
    final total = 'Total ${formatDollars(path.totalCoursesPrice)}';
    if (path.discountPercent <= 0) return '$total.';
    return '$total con -${path.discountPercent}%: ${formatDollars(path.price)}.';
  }
}

/// Estado de la pantalla: error404 / error de red con su acción.
class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
