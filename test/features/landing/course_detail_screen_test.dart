import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/app/app.dart';
import 'package:kontec/app/router/app_router.dart';
import 'package:kontec/features/aula/domain/entities/course_curriculum.dart';
import 'package:kontec/features/aula/presentation/viewmodels/curriculum_providers.dart';
import 'package:kontec/features/landing/domain/entities/training_course.dart';
import 'package:kontec/features/landing/presentation/viewmodels/course_detail_viewmodel.dart';

/// REGRESIÓN: la landing de detalle usa TabBar con TabController propio
/// (bug real: "No TabController for TabBar" al abrir /capacitaciones/:id).
/// Pinta las 7 pestañas y recorre su contenido con datos fake de BD.
const _courseId = 'curso-test-1';

final _course = TrainingCourse(
  id: _courseId,
  title: 'Curso de prueba',
  modality: 'live',
  category: 'BIM',
  description: 'Descripción de prueba.',
  hours: 40,
  totalWeeks: 8,
  // Precio general 250 con oferta de 200 (la UI tacha el general y
  // destaca la oferta, igual que en el resto de cursos reales).
  price: 250,
  compareAtPrice: 200,
  professorBio: 'Bio del profe.',
  teachingMethod: 'Clase grabada\nForo de consultas',
  targetAudience: 'Ingenieros\nArquitectos',
  certificateInfo: 'Certificado con QR',
  careerOpportunities: 'BIM Manager\nBIM Modeler',
);

CourseCurriculum _curriculumWithAccess(String access) => CourseCurriculum(
  courseId: _courseId,
  courseTitle: 'Curso de prueba',
  access: access,
  modules: [
    CurriculumModule(
      id: 'm1',
      title: 'Módulo 1: Fundamentos',
      order: 1,
      lessons: [
        const CurriculumLesson(
          id: 'l1',
          title: 'Lección introductoria',
          contentType: 'recorded',
          order: 1,
          contentUrl: null,
          isCompleted: false,
        ),
      ],
    ),
  ],
  totalLessons: 1,
  completedLessons: 0,
);

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Size size,
  String access = 'none',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      courseDetailProvider(_courseId).overrideWith((ref) async => _course),
      curriculumProvider(_courseId).overrideWith(
        (ref) async => _curriculumWithAccess(access),
      ),
    ],
  );
  addTearDown(container.dispose);

  // La pantalla vive tras el router (el navbar usa GoRouterState).
  container.read(routerProvider).go('/capacitaciones/$_courseId');
  addTearDown(() => container.read(routerProvider).go('/'));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const KontecApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pinta sidebar y las 7 pestañas en desktop', (tester) async {
    await _pumpDetail(tester, size: const Size(1400, 900));

    expect(find.text('Curso de prueba'), findsOneWidget);
    // Sidebar de compra.
    expect(find.text('Tarifa General'), findsOneWidget);
    expect(find.text('\$200.00'), findsOneWidget); // oferta (lo que se paga)
    expect(find.text('\$250.00'), findsOneWidget); // general tachado
    expect(find.text('Agregar al carrito'), findsOneWidget);
    expect(find.text('Inscribirme ahora'), findsOneWidget);

    // Las 7 pestañas de la plantilla.
    for (final tab in [
      'DESCRIPCIÓN',
      'CONTENIDO',
      'PROFESORADO',
      'MÉTODO DIDÁCTICO',
      'DIRIGIDO A',
      'CERTIFICADO',
      'SALIDAS LABORALES',
    ]) {
      expect(find.text(tab), findsOneWidget);
    }

    // Contenido de la pestaña activa por defecto (también se repite en
    // el caption de la imagen de cabecera).
    expect(find.text('Descripción de prueba.'), findsAtLeastNWidgets(1));
    expect(find.text('¿Qué incluye?'), findsOneWidget);
  });

  testWidgets('cada pestaña muestra su sección y el temario en accordion',
      (tester) async {
    await _pumpDetail(tester, size: const Size(1400, 900));

    await tester.tap(find.text('CONTENIDO'));
    await tester.pumpAndSettle();
    expect(find.text('Módulo 1: Fundamentos'), findsOneWidget);
    // El módulo arranca contraído: la lección se ve al abrirlo.
    await tester.tap(find.text('Módulo 1: Fundamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Lección introductoria'), findsOneWidget);

    await tester.tap(find.text('PROFESORADO'));
    await tester.pumpAndSettle();
    expect(find.text('Bio del profe.'), findsOneWidget);

    await tester.tap(find.text('MÉTODO DIDÁCTICO'));
    await tester.pumpAndSettle();
    expect(find.text('Clase grabada'), findsOneWidget);

    await tester.tap(find.text('DIRIGIDO A'));
    await tester.pumpAndSettle();
    expect(find.text('Ingenieros'), findsOneWidget);
    expect(find.text('Arquitectos'), findsOneWidget);

    await tester.tap(find.text('CERTIFICADO'));
    await tester.pumpAndSettle();
    expect(find.text('Certificado con QR'), findsOneWidget);

    await tester.tap(find.text('SALIDAS LABORALES'));
    await tester.pumpAndSettle();
    expect(find.text('BIM Manager'), findsOneWidget);
    expect(find.text('BIM Modeler'), findsOneWidget);
  });

  testWidgets('en móvil la sidebar de compra va arriba de los tabs',
      (tester) async {
    await _pumpDetail(tester, size: const Size(500, 900));

    expect(find.text('Tarifa General'), findsOneWidget);
    expect(find.text('Inscribirme ahora'), findsOneWidget);
    expect(find.text('DESCRIPCIÓN'), findsOneWidget);
  });

  testWidgets('si ya tomó el curso se le advierte en vez de venderle',
      (tester) async {
    await _pumpDetail(tester, size: const Size(1400, 900), access: 'full');

    expect(find.text('Ya tomaste este curso'), findsOneWidget);
    expect(find.text('Entrar al curso'), findsOneWidget);
    expect(find.text('Inscribirme ahora'), findsNothing);
    expect(find.text('Agregar al carrito'), findsNothing);
  });
}
