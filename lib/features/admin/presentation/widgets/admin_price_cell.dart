import 'package:flutter/material.dart';

import '../../../../../core/format/currency.dart';
import '../../../../../core/theme/app_colors.dart';

/// Celda de precio compartida por las tablas de cursos del panel admin
/// (listado y overview), para que un precio se pinte IGUAL en ambas.
///
/// Sin oferta → solo el precio general. Con oferta → el general TACHADO
/// + la oferta (lo que se cobra) en negrita. Misma regla que el front
/// público (`course_display.dart`): solo hay oferta real cuando es
/// menor que el general.
class AdminPriceCell extends StatelessWidget {
  const AdminPriceCell({
    super.key,
    required this.price,
    required this.compareAt,
  });

  /// Precio general.
  final double price;

  /// Precio de oferta (null = sin descuento).
  final double? compareAt;

  @override
  Widget build(BuildContext context) {
    final hasOffer = compareAt != null && compareAt! > 0 && compareAt! < price;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasOffer) ...[
          Text(
            formatDollars(price),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          formatDollars(hasOffer ? compareAt! : price),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
