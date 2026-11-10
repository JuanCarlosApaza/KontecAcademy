import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/features/admin/presentation/widgets/admin_table.dart';

/// REGRESIÓN: en la vista angosta (<640px) [AdminTableCard] construye
/// [_SortControl], que leía `sortValue` a través de
/// `List<AdminColumn<dynamic>>` y en web lanzaba:
/// "type '(Row) => String' is not a subtype of '((dynamic) => Comparable)?'".
class _Row {
  const _Row(this.name, this.amount);

  final String name;
  final double amount;
}

void main() {
  testWidgets('vista angosta con columnas ordenables no lanza TypeError',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTableCard<_Row>(
            title: 'Pagos',
            items: const [_Row('Beto', 300), _Row('Ana', 100)],
            searchText: (r) => r.name,
            columns: [
              AdminColumn<_Row>(
                label: 'Nombre',
                sortValue: (r) => r.name,
                cell: (r) => Text(r.name),
              ),
              AdminColumn<_Row>(
                label: 'Monto',
                sortValue: (r) => r.amount,
                cell: (r) => Text('${r.amount}'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);

    // Ordenar por la primera columna ordenable (flecha del control).
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('vista ancha (>640px) sigue pintando la tabla', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminTableCard<_Row>(
            title: 'Pagos',
            items: const [_Row('Ana', 100)],
            searchText: (r) => r.name,
            columns: [
              AdminColumn<_Row>(
                label: 'Nombre',
                sortValue: (r) => r.name,
                cell: (r) => Text(r.name),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ana'), findsOneWidget);
  });
}
