import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/features/landing/domain/entities/training_course.dart';
import 'package:kontec/features/landing/presentation/widgets/course_display.dart';

/// REGRESIÓN: la semántica de precios se había invertido una vez
/// (se pintaba el precio de oferta tachado y el general destacado, y
/// como la oferta venía MENOR que el general, la condición nunca se
/// cumplía y solo se veía UN precio).
///
/// Regla: `price` = precio GENERAL · `compareAtPrice` = precio de OFERTA.
/// Solo hay oferta real cuando la oferta es > 0 y MENOR que el general.
TrainingCourse _course({required double price, double? compareAtPrice}) =>
    TrainingCourse(
      id: 'c1',
      title: 'Curso',
      modality: 'live',
      price: price,
      compareAtPrice: compareAtPrice,
    );

void main() {
  group('offerPrice / effectivePrice', () {
    test('con oferta válida (oferta < general) usa la oferta', () {
      final course = _course(price: 60, compareAtPrice: 50);

      expect(course.offerPrice, 50);
      expect(course.hasOffer, isTrue);
      expect(course.effectivePrice, 50);
    });

    test('sin segundo precio no hay oferta: se cobra el general', () {
      final course = _course(price: 60);

      expect(course.offerPrice, isNull);
      expect(course.hasOffer, isFalse);
      expect(course.effectivePrice, 60);
    });

    test('oferta MAYOR que el general se ignora (datos inconsistentes)', () {
      final course = _course(price: 150, compareAtPrice: 200);

      expect(course.offerPrice, isNull);
      expect(course.hasOffer, isFalse);
      expect(course.effectivePrice, 150);
    });

    test('oferta igual al general no es un descuento', () {
      final course = _course(price: 100, compareAtPrice: 100);

      expect(course.offerPrice, isNull);
      expect(course.effectivePrice, 100);
    });

    test('oferta en 0 o negativa se ignora', () {
      expect(_course(price: 60, compareAtPrice: 0).offerPrice, isNull);
      expect(_course(price: 60, compareAtPrice: -10).offerPrice, isNull);
    });

    test('precio general en 0 (sin precio) no inventa oferta', () {
      final course = _course(price: 0, compareAtPrice: 50);

      expect(course.offerPrice, isNull);
      expect(course.effectivePrice, 0);
    });
  });
}
