import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/format/currency.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_alerts.dart';
import '../../../auth/presentation/widgets/login_required_dialog.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../domain/entities/training_course.dart';
import 'course_display.dart';

/// Tarjeta de curso destacado (carrusel del home y grid de catálogo).
///
/// Todas las tarjetas miden lo MISMO ([_cardHeight]) sin importar cuánto
/// texto tengan, para que el carrusel gire sin saltos de alto.
///
/// Estructura: cover → título → puntos destacados → modalidad →
/// dato extra → precio → botones "Más información" y "carrito"
/// (los botones siempre anclados al fondo).
///
/// El botón de carrito es opcional ([showCartButton]): el carrusel del
/// home lo oculta para dejar solo "Más información" (el alta se hace
/// desde el detalle del curso).
class CourseCard extends ConsumerWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showCartButton = true,
  });

  /// Alto fijo idéntico para TODAS las tarjetas.
  ///
  /// Reserva aire para el precio (oferta + general tachado) sin que el
  /// `Spacer` de los botones se quede sin holgura.
  static const double cardHeight = 440;

  final TrainingCourse course;
  final VoidCallback? onTap;

  /// Muestra el botón de carrito junto a "Más información".
  final bool showCartButton;

  /// Agrega el curso al carrito. Si no hay sesión, el guard pide
  /// iniciar sesión primero (flujo: ver cursos → carrito → login).
  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final ok = await ensureAuthenticated(
      context,
      ref,
      action: 'agregar cursos al carrito',
    );
    if (!ok || !context.mounted) return;

    final added = await ref
        .read(cartViewModelProvider.notifier)
        .addItem(
          CartItem(
            courseId: course.id,
            title: course.title,
            // Se cobra el precio de OFERTA si existe; si no, el general.
            price: course.effectivePrice,
            modality: course.modalityLabel,
            imageUrl: course.imageUrl,
          ),
        );

    if (!context.mounted) return;
    await showAppAlert(
      context,
      type: added ? AppAlertType.success : AppAlertType.info,
      title: 'Carrito',
      message: added
          ? 'Curso agregado al carrito 🛒'
          : 'El curso ya está en tu carrito.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseCover(course: course),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título (siempre 2 líneas de espacio → sin saltos).
                  SizedBox(
                    height: 42,
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Puntos destacados.
                  for (final point in course.highlights) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                  const SizedBox(height: 6),
                  // Modalidad.
                  const Text(
                    'Modalidad:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.laptop_mac,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.modalityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        course.durationLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Precio, con el mismo criterio que el detalle: el
                  // precio de oferta es el que se paga y el general va
                  // tachado al lado (solo si hay descuento real).
                  if (course.price > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          if (course.hasOffer) ...[
                            Text(
                              formatDollars(course.price),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            formatDollars(course.effectivePrice),
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Botones: "Más información" + carrito (siempre anclados
                  // abajo, con aire generoso).
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDark,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text('Más información'),
                          ),
                        ),
                      ),
                      if (showCartButton) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Tooltip(
                            message: 'Agregar al carrito',
                            child: FilledButton(
                              onPressed: () => _addToCart(context, ref),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cover superior: imagen real del curso si el back envía una
/// (`course.imageUrl`); si no hay o no carga, se ve el degradado + badge.
class _CourseCover extends StatelessWidget {
  const _CourseCover({required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: course.coverColors,
              ),
            ),
          ),
          if (hasImage)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // Si la URL falla, queda el degradado de abajo.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          // Scrim para que el texto se lea encima de la foto.
          if (hasImage)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59000000), Color(0xB3000000)],
                ),
              ),
            ),
          // Marca de agua del logo.
          const Positioned(
            top: 10,
            left: 12,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Kontec',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' Academy',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Badge "Entrenamiento Especializado" centrado abajo.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.badge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
