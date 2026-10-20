import 'package:go_router/go_router.dart';

import '../../features/tasks/presentation/screens/tasks_screen.dart';

/// Router centralizado (go_router). Al crecer, cada feature puede aportar
/// sus rutas y concatenarse aquí: `...authRoutes, ...taskRoutes`.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'tasks',
      builder: (context, state) => const TasksScreen(),
    ),
    // TODO: añade aquí tus futuras features:
    // GoRoute(path: '/login', builder: ...),
  ],
);
