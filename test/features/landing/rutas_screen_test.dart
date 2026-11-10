import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/app/app.dart';
import 'package:kontec/app/router/app_router.dart';
import 'package:kontec/core/error/failures.dart';
import 'package:kontec/features/landing/domain/entities/learning_path.dart';
import 'package:kontec/features/landing/domain/repositories/learning_path_repository.dart';
import 'package:kontec/features/landing/landing_injector.dart';
import 'package:kontec/features/landing/presentation/screens/ruta_detail_screen.dart';
import 'package:kontec/features/landing/presentation/screens/rutas_screen.dart';

/// RUTAS DE ENTRENAMIENTO: la lista pinta las rutas del repositorio
/// falso, "Ver ruta" navega al detalle y el detalle muestra sus cursos
/// con nivel. Sin red: el repositorio se sustituye por un doble.
final _path = LearningPath(
  id: 'ruta-1',
  slug: 'estructuras-y-diseno',
  title: 'Estructuras y diseño',
  description: 'Ruta de prueba',
  modality: 'asynchronous',
  durationHours: 80,
  accessMonths: 12,
  // Precio: total de referencia $250 con -20% → $200.
  discountPercent: 20,
  totalCoursesPrice: 250,
  price: 200,
  courses: const [
    PathCourse(
      courseId: 'curso-1',
      title: 'Concreto armado',
      price: 150,
      hours: 40,
      level: 'Introductorio',
      sortOrder: 0,
    ),
    PathCourse(
      courseId: 'curso-2',
      title: 'Conexiones metálicas',
      price: 60,
      hours: 40,
      level: 'Intermedio',
      sortOrder: 1,
    ),
  ],
);

class _FakePathRepository implements LearningPathRepository {
  _FakePathRepository({this.paths = const [], this.notFound = false});

  final List<LearningPath> paths;
  final bool notFound;

  @override
  Future<(List<LearningPath>, Failure?)> getPaths() async => (paths, null);

  @override
  Future<(LearningPath?, Failure?)> getPathBySlug(String slug) async =>
      notFound ? (null, null) : (paths.where((p) => p.slug == slug).firstOrNull, null);
}

Future<ProviderContainer> _pump(WidgetTester tester, LearningPathRepository repo,
    {required String location}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [learningPathRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);

  container.read(routerProvider).go(location);
  addTearDown(() => container.read(routerProvider).go('/'));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KontecApp(),
    ),
  );
  await tester.pump();
  await tester.pump();

  return container;
}

void main() {
  testWidgets('/rutas pinta las tarjetas y navega al detalle',
      (tester) async {
    final container = await _pump(
      tester,
      _FakePathRepository(paths: [_path]),
      location: '/rutas',
    );

    expect(find.byType(RutasScreen), findsOneWidget);
    expect(find.text('Estructuras y diseño'), findsWidgets);
    expect(find.text('2 cursos'), findsWidgets);
    expect(find.text('80 h'), findsWidgets);
    // Precio de la ruta en la tarjeta: chip de rebaja + tachado + final.
    expect(find.text('-20%'), findsOneWidget);
    expect(find.text('\$250.00'), findsOneWidget);
    expect(find.text('\$200.00'), findsOneWidget);

    await tester.tap(find.text('Ver ruta').first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(RutaDetailScreen), findsOneWidget);
    expect(container.read(routerProvider).state.uri.path,
        '/rutas/estructuras-y-diseno');
  });

  testWidgets('el detalle lista los cursos con su nivel', (tester) async {
    await _pump(
      tester,
      _FakePathRepository(paths: [_path]),
      location: '/rutas/estructuras-y-diseno',
    );

    expect(find.byType(RutaDetailScreen), findsOneWidget);
    expect(find.text('Cursos de la ruta'), findsOneWidget);
    expect(find.text('Concreto armado'), findsOneWidget);
    expect(find.text('Conexiones metálicas'), findsOneWidget);
    expect(find.text('Introductorio'), findsOneWidget);
    expect(find.text('Intermedio'), findsOneWidget);
    // Inversión con rebaja + botón de compra en el panel inferior.
    expect(find.text('Inversión de la ruta'), findsOneWidget);
    expect(find.text('\$200.00'), findsOneWidget);
    expect(find.text('Comprar ruta'), findsOneWidget);
  });

  testWidgets('slug inexistente muestra el estado404 con salida',
      (tester) async {
    await _pump(
      tester,
      _FakePathRepository(notFound: true),
      location: '/rutas/no-existe',
    );

    expect(find.text('No encontramos esta ruta.'), findsOneWidget);

    await tester.tap(find.text('Ver todas las rutas'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RutasScreen), findsOneWidget);
  });

  testWidgets('lista vacía muestra el estado vacío', (tester) async {
    await _pump(tester, _FakePathRepository(), location: '/rutas');

    expect(find.text('Aún no hay rutas publicadas.'), findsOneWidget);
  });
}
