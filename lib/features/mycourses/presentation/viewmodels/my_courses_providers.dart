import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/entities/enrolled_course.dart';
import '../../mycourses_injector.dart';

/// Cursos inscritos del usuario actual ("Mis cursos").
///
/// Reacciona al login/logout: sin sesión la lista queda vacía y NO se
/// llama a la API (evita un 401 ruidoso al cerrar cuenta).
final myCoursesProvider = FutureProvider<List<EnrolledCourse>>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const [];

  return ref.watch(fetchMyCoursesProvider)(const NoParams());
});
