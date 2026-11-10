import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/app/app.dart';
import 'package:kontec/app/router/app_router.dart';
import 'package:kontec/core/error/failures.dart';
import 'package:kontec/features/aula/presentation/viewmodels/curriculum_providers.dart';
import 'package:kontec/features/landing/data/repositories/course_repository_impl.dart';
import 'package:kontec/features/landing/domain/entities/category.dart';
import 'package:kontec/features/landing/domain/entities/training_course.dart';
import 'package:kontec/features/landing/domain/repositories/course_repository.dart';
import 'package:kontec/features/landing/presentation/screens/course_detail_screen.dart';

/// REGRESIÓN (1): los botones del carrusel del home no respondían.
///
/// El carrusel iba con `bottom: -overlap` dentro de un `Stack` cuyo
/// `size` solo medía el hero (620px), así que los botones "Más
/// información" y los puntos quedaban ~220px FUERA de su área de
/// hit-testing y Flutter nunca les repartía el clic.
///
/// REGRESIÓN (2): la pantalla de cursos no mostraba el precio de oferta,
/// solo el general.
///
/// Ambos tests corren sin red: un repositorio falso resuelve todo el
/// feature `landing` (listado, detalle y categorías).
const _courseId = 'curso-test-1';

final _course = TrainingCourse(
  id: _courseId,
  title: 'Curso de prueba',
  modality: 'live',
  category: 'BIM',
  // Precio general 60 con oferta de 50 (oferta < general = descuento real).
  price: 60,
  compareAtPrice: 50,
);

/// Catálogo en memoria: el `homeViewModelProvider` y el
/// `courseDetailProvider` se alimentan del mismo repositorio.
class _FakeCourseRepository implements CourseRepository {
  _FakeCourseRepository(this._courses);

  final List<TrainingCourse> _courses;

  @override
  Future<(List<TrainingCourse>, Failure?)> getFeaturedCourses() async =>
      (_courses, null);

  @override
  Future<(List<TrainingCourse>, Failure?)> getAllCourses() async =>
      (_courses, null);

  @override
  Future<(TrainingCourse?, Failure?)> getCourseById(String id) async {
    for (final course in _courses) {
      if (course.id == id) return (course, null);
    }
    return (null, null);
  }

  @override
  Future<(List<Category>, Failure?)> getCategories() async =>
      (const <Category>[], null);
}

Future<ProviderContainer> _pumpHome(WidgetTester tester) async {
  // Ancho >= 900 para que aplique el solape del carrusel sobre el hero
  // (es exactamente la rama con el bug), pero < 1200 para que el
  // titular use fontSize 34: la fuente de test es "Ahem" (glifos
  // cuadrados del tamaño del fontSize) y a 42 desborda la caja del
  // hero, algo que en un navegador real no ocurre.
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      courseRepositoryProvider.overrideWithValue(
        _FakeCourseRepository([_course]),
      ),
      // El detalle no debe ir a buscar el temario a la red.
      curriculumProvider(_courseId).overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);

  // La pantalla vive tras el router (el navbar usa GoRouterState).
  container.read(routerProvider).go('/');
  addTearDown(() => container.read(routerProvider).go('/'));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KontecApp(),
    ),
  );
  // ⚠️ Nada de pumpAndSettle(): el carrusel tiene un ticker INFINITO que
  // nunca deja de programar frames y el settle entraría en bucle.
  await tester.pump();
  await tester.pump();

  return container;
}

void main() {
  testWidgets('el botón "Más información" del carrusel navega al detalle',
      (tester) async {
    await _pumpHome(tester);

    final button = find.text('Más información');
    expect(button, findsWidgets, reason: 'el carrusel pinta sus tarjetas');

    // Con el bug, este tap no llega al botón (queda fuera del `size`
    // del Stack) y la navegación nunca ocurre.
    await tester.tap(button.first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CourseDetailScreen), findsOneWidget);
    expect(find.text('Tarifa General'), findsOneWidget);
  });

  testWidgets('la pantalla de cursos muestra precio de oferta y general',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        courseRepositoryProvider.overrideWithValue(
          _FakeCourseRepository([_course]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(routerProvider).go('/capacitaciones');
    addTearDown(() => container.read(routerProvider).go('/'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const KontecApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Oferta (lo que se paga) y general tachado, igual que en el detalle.
    expect(find.text('\$50.00'), findsAtLeastNWidgets(1));
    expect(find.text('\$60.00'), findsAtLeastNWidgets(1));
  });
}
