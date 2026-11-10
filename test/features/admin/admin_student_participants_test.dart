import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/features/admin/domain/entities/course_participant.dart';
import 'package:kontec/features/admin/domain/entities/student_profile.dart';
import 'package:kontec/features/admin/presentation/screens/admin_course_participants_screen.dart';
import 'package:kontec/features/admin/presentation/screens/admin_student_profile_screen.dart';
import 'package:kontec/features/admin/presentation/viewmodels/admin_providers.dart';

const _courseId = 'curso-1';
const _studentId = 'est-1';

final _participants = CourseParticipants(
  courseId: _courseId,
  courseTitle: 'Diseño de Puentes',
  participants: [
    CourseParticipant(
      userId: _studentId,
      fullName: 'Carla Quispe',
      email: 'carla@ejemplo.com',
      phone: '999888777',
      status: 'pending_payment',
      enrolledAt: DateTime(2026, 10, 20),
    ),
    CourseParticipant(
      userId: 'est-2',
      fullName: 'Luis Ramírez',
      email: 'luis@ejemplo.com',
      status: 'revoked',
      enrolledAt: DateTime(2026, 9, 1),
    ),
  ],
);

final _profile = StudentProfile(
  id: _studentId,
  fullName: 'Carla Quispe',
  email: 'carla@ejemplo.com',
  phone: '999888777',
  nationality: 'Peruana',
  createdAt: DateTime(2026, 1, 1),
  isActive: true,
  enrollments: [
    StudentEnrollment(
      courseId: _courseId,
      title: 'Diseño de Puentes',
      status: 'approved',
      enrolledAt: DateTime(2026, 10, 20),
    ),
  ],
);

Future<void> _pumpParticipants(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      participantsProvider(_courseId).overrideWith((ref) async => _participants),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: AdminCourseParticipantsScreen(courseId: _courseId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpProfile(WidgetTester tester, {bool canManage = true}) async {
  tester.view.physicalSize = const Size(1300, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      studentProfileProvider(_studentId).overrideWith((ref) async => _profile),
      // El botón de acceso está tras el guard de students:manage.
      permissionProvider('students:manage').overrideWithValue(canManage),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: AdminStudentProfileScreen(studentId: _studentId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('participantes muestra nombre, correo, fecha y estado',
      (tester) async {
    await _pumpParticipants(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Diseño de Puentes'), findsOneWidget);
    expect(find.text('Carla Quispe'), findsOneWidget);
    expect(find.text('carla@ejemplo.com'), findsOneWidget);
    expect(find.text('20/10/2026'), findsOneWidget);
    // Estados (badge de inscripción).
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.text('Revocado'), findsOneWidget);
  });

  testWidgets('perfil muestra datos, curso inscrito y botón de acceso',
      (tester) async {
    await _pumpProfile(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Carla Quispe'), findsOneWidget);
    expect(find.text('carla@ejemplo.com'), findsOneWidget);
    expect(find.text('Peruana'), findsOneWidget);
    expect(find.text('Diseño de Puentes'), findsOneWidget);
    expect(find.text('Con acceso'), findsOneWidget);
    // Acción de acceso para un curso con acceso.
    expect(find.text('Quitar acceso'), findsOneWidget);
  });

  testWidgets('al tocar "Quitar acceso" se pide confirmación', (tester) async {
    await _pumpProfile(tester);

    await tester.tap(find.text('Quitar acceso'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Diálogo de confirmación con la advertencia de reversibilidad.
    expect(find.text('Quitar acceso'), findsWidgets);
    expect(find.textContaining('No se elimina ningún dato'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    // Cancelar no debe disparar ninguna llamada (solo UI).
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin students:manage no se ofrece quitar acceso',
      (tester) async {
    await _pumpProfile(tester, canManage: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Diseño de Puentes'), findsOneWidget);
    expect(find.text('Quitar acceso'), findsNothing);
  });
}
