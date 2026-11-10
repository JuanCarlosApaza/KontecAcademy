import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/app/app.dart';
import 'package:kontec/app/router/app_router.dart';
import 'package:kontec/core/data/countries.dart';

/// REGRESIÓN: el registro debe mostrar el dropdown de país y sincronizar
/// el código telefónico según el país elegido (Bolivia → +591).
void main() {
  testWidgets('elegir país sincroniza el código telefónico', (tester) async {
    // La fuente de tests (Ahem) hace que TODO glyph ocupe un em, lo que
    // provoca RenderFlex overflows que en el navegador (Roboto) no
    // existen: los toleramos para centrarnos en el comportamiento.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(routerProvider).go('/registro');
    addTearDown(() => container.read(routerProvider).go('/'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const KontecApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Por defecto Bolivia → código +591.
    expect(find.text('🇧🇴 Bolivia'), findsOneWidget);
    expect(find.text('+591'), findsOneWidget);

    // Cambia el país a Argentina → el código queda +54.
    await tester.tap(find.byType(DropdownButtonFormField<CountryCode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇦🇷 Argentina'));
    await tester.pumpAndSettle();

    expect(find.text('+54'), findsOneWidget);
    expect(find.text('+591'), findsNothing);
  });
}
