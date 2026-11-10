import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_course_participants_screen.dart';
import '../../features/admin/presentation/screens/admin_courses_screen.dart';
import '../../features/admin/presentation/screens/admin_memberships_screen.dart';
import '../../features/admin/presentation/screens/admin_overview_screen.dart';
import '../../features/admin/presentation/screens/admin_payments_screen.dart';
import '../../features/admin/presentation/screens/admin_paths_screen.dart';
import '../../features/admin/presentation/screens/admin_roles_screen.dart';
import '../../features/admin/presentation/screens/admin_student_profile_screen.dart';
import '../../features/admin/presentation/screens/admin_students_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/widgets/admin_shell.dart';
import '../../features/aula/presentation/screens/aula_screen.dart';
import '../../features/auth/auth_injector.dart';
import '../../features/auth/presentation/screens/auth_entry_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/my_profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/landing/presentation/screens/course_detail_screen.dart';
import '../../features/landing/presentation/screens/courses_screen.dart';
import '../../features/landing/presentation/screens/home_screen.dart';
import '../../features/landing/presentation/screens/membresias_screen.dart';
import '../../features/landing/presentation/screens/ruta_detail_screen.dart';
import '../../features/landing/presentation/screens/rutas_screen.dart';
import '../../features/mycourses/presentation/screens/my_courses_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';

/// Router centralizado (go_router) como provider de Riverpod, para que
/// el guard de autenticación consulte la sesión vía AuthRepository.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      // Capacitaciones: catálogo + detalle de curso.
      GoRoute(
        path: '/capacitaciones',
        name: 'capacitaciones',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/capacitaciones/:id/aula',
        name: 'course-aula',
        builder: (context, state) =>
            AulaScreen(courseId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/capacitaciones/:id',
        name: 'course-detail',
        builder: (context, state) =>
            CourseDetailScreen(courseId: state.pathParameters['id'] ?? ''),
      ),
      // Autenticación (Supabase: email + Google).
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registro',
        name: 'registro',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Puente: decide destino tras iniciar sesión (admin → /admin).
      GoRoute(
        path: '/auth-entrar',
        name: 'auth-entrar',
        builder: (context, state) => const AuthEntryScreen(),
      ),
      // Carrito + pago (requieren sesión → ver redirect más abajo).
      GoRoute(
        path: '/carrito',
        name: 'carrito',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      // Mis cursos: inscripciones del estudiante (con acceso una vez
      // que el admin aprueba el pago).
      GoRoute(
        path: '/mis-cursos',
        name: 'mis-cursos',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      // Mi perfil: datos de cuenta + cursos inscritos (requiere sesión).
      GoRoute(
        path: '/perfil',
        name: 'perfil',
        builder: (context, state) => const MyProfileScreen(),
      ),
      // Panel administrativo (sidebar oscuro estilo dashboard + guard
      // de rol "admin" dentro de AdminShell).
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminOverviewScreen(),
          ),
          GoRoute(
            path: '/admin/estudiantes',
            name: 'admin-estudiantes',
            builder: (context, state) => const AdminStudentsScreen(),
          ),
          // Perfil de un estudiante (desde Estudiantes o Participantes).
          GoRoute(
            path: '/admin/estudiantes/:id',
            name: 'admin-estudiante-perfil',
            builder: (context, state) => AdminStudentProfileScreen(
              studentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/pagos',
            name: 'admin-pagos',
            builder: (context, state) => const AdminPaymentsScreen(),
          ),
          GoRoute(
            path: '/admin/cursos',
            name: 'admin-cursos',
            builder: (context, state) => const AdminCoursesScreen(),
          ),
          // Participantes de un curso (desde la tabla de Cursos).
          GoRoute(
            path: '/admin/cursos/:id/participantes',
            name: 'admin-curso-participantes',
            builder: (context, state) => AdminCourseParticipantsScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/categorias',
            name: 'admin-categorias',
            builder: (context, state) => const AdminCategoriesScreen(),
          ),
          GoRoute(
            path: '/admin/usuarios',
            name: 'admin-usuarios',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          // Matriz de roles × permisos (guard propio: roles:manage).
          GoRoute(
            path: '/admin/roles',
            name: 'admin-roles',
            builder: (context, state) => const AdminRolesScreen(),
          ),
          GoRoute(
            path: '/admin/rutas',
            name: 'admin-rutas',
            builder: (context, state) => const AdminPathsScreen(),
          ),
          // Membresías: registros de usuarios + planes (courses:view).
          GoRoute(
            path: '/admin/membresias',
            name: 'admin-membresias',
            builder: (context, state) => const AdminMembershipsScreen(),
          ),
        ],
      ),
      // Rutas de entrenamiento: lista + detalle (/rutas/:slug).
      GoRoute(
        path: '/rutas',
        name: 'rutas',
        builder: (context, state) => const RutasScreen(),
      ),
      GoRoute(
        path: '/rutas/:slug',
        name: 'ruta-detalle',
        builder: (context, state) => RutaDetailScreen(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: '/store',
        name: 'store',
        builder: (context, state) => const _PlaceholderPage('Insight Store'),
      ),
      GoRoute(
        path: '/membresias',
        name: 'membresias',
        builder: (context, state) => const MembershipsScreen(),
      ),
      GoRoute(
        path: '/comunidad',
        name: 'comunidad',
        builder: (context, state) => const _PlaceholderPage('Comunidad'),
      ),
      GoRoute(
        path: '/consultorias',
        name: 'consultorias',
        builder: (context, state) => const _PlaceholderPage('Consultorías'),
      ),
      GoRoute(
        path: '/contactanos',
        name: 'contactanos',
        builder: (context, state) => const _PlaceholderPage('Contáctanos'),
      ),
      GoRoute(
        path: '/ofertas',
        name: 'ofertas',
        builder: (context, state) => const _PlaceholderPage('Ofertas'),
      ),
    ],
    // GUARD de autenticación:
    //  * /checkout exige sesión (pasar a la modalidad de pago).
    //  * /login y /registro mandan al usuario con sesión a su destino.
    redirect: (context, state) {
      final bool isLoggedIn;
      try {
        // La sesión la resuelve AuthRepository (Supabase vive en data;
        // el router nunca toca el SDK directamente).
        isLoggedIn = ref.read(authRepositoryProvider).currentUser != null;
      } catch (_) {
        // Supabase sin inicializar (tests): navegación libre.
        return null;
      }

      final location = state.matchedLocation;
      final isAuthPage = location == '/login' || location == '/registro';
      // El aula es /capacitaciones/<id>/aula (el id es dinámico).
      final isAula =
          location.startsWith('/capacitaciones/') && location.endsWith('/aula');

      if (!isLoggedIn &&
          (location == '/checkout' ||
              location == '/mis-cursos' ||
              location == '/perfil' ||
              isAula)) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$from';
      }
      if (isLoggedIn && isAuthPage) {
        // Con sesión en /login o /registro: si hay destino explícito
        // (?redirect=) se respeta; si no, el puente /auth-entrar
        // decide según el rol (admin → dashboard).
        return state.uri.queryParameters['redirect'] ?? '/auth-entrar';
      }
      return null;
    },
  );
});

/// Página genérica para secciones aún sin diseño.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title — contenido próximamente.')),
    );
  }
}
