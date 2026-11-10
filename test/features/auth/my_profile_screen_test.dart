import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kontec/features/admin/domain/entities/student_profile.dart';
import 'package:kontec/features/admin/presentation/viewmodels/admin_providers.dart';
import 'package:kontec/features/auth/presentation/screens/my_profile_screen.dart';

final _profile = StudentProfile(
  id: 'u1',
  fullName: 'Carla Quispe',
  email: 'carla@ejemplo.com',
  phone: '999888777',
  nationality: 'Peruana',
  createdAt: DateTime(2026, 1, 1),
  isActive: true,
  enrollments: [
    StudentEnrollment(
      courseId: 'c1',
      title: 'Diseño de Puentes',
      status: 'approved',
      enrolledAt: DateTime(2026, 10, 20),
    ),
    StudentEnrollment(
      courseId: 'c2',
      title: 'Geotecnia',
      status: 'revoked',
      enrolledAt: DateTime(2026, 9, 1),
    ),
  ],
);

Future<void> _pumpProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [myProfileProvider.overrideWith((ref) async => _profile)],
  );
  addTearDown(container.dispose);

  // GoRouter mínimo: el navbar usa GoRouterState.of(context), y así
  // evitamos el guard de login de la app real.
  final router = GoRouter(
    initialLocation: '/perfil',
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const MyProfileScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra datos personales y cursos con su estado', (
    tester,
  ) async {
    await _pumpProfile(tester);

    expect(tester.takeException(), isNull);
    // Datos de la cuenta.
    expect(find.text('Carla Quispe'), findsOneWidget);
    expect(find.text('carla@ejemplo.com'), findsOneWidget);
    expect(find.text('Peruana'), findsOneWidget);
    expect(find.text('999888777'), findsOneWidget);
    // Cursos inscritos con su estado.
    expect(find.text('Diseño de Puentes'), findsOneWidget);
    expect(find.text('Geotecnia'), findsOneWidget);
    expect(find.text('Con acceso'), findsOneWidget);
    expect(find.text('Revocado'), findsOneWidget);
  });

  testWidgets('no ofrece acciones de administrador (quitar/restaurar)', (
    tester,
  ) async {
    await _pumpProfile(tester);

    expect(tester.takeException(), isNull);
    // El usuario no debe poder gestionar accesos desde su perfil.
    expect(find.text('Quitar acceso'), findsNothing);
    expect(find.text('Restaurar acceso'), findsNothing);
  });

  testWidgets('con perfil vacío (solo registro) no se rompe', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        myProfileProvider.overrideWith(
          (ref) async => const StudentProfile(
            id: 'u1',
            fullName: '',
            email: 'nuevo@ejemplo.com',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/perfil',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const MyProfileScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Sin nombre → usa el email como nombre visible.
    expect(find.text('nuevo@ejemplo.com'), findsWidgets);
    expect(find.textContaining('Todavía no te has inscrito'), findsOneWidget);
  });
}
