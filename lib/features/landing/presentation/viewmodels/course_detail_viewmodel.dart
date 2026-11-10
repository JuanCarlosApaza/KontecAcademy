import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/viewmodels/session_context_provider.dart';
import '../../domain/entities/training_course.dart';
import '../../landing_injector.dart';

/// Curso de la pantalla de detalle (`/capacitaciones/:id`).
///
/// Presentation solo invoca el caso de uso GetCourseById: no busca en
/// listas ni habla con la API. Lanza la [Failure] del dominio si la
/// carga falla (null sin falla = curso inexistente, 404).
final courseDetailProvider = FutureProvider.family<TrainingCourse?, String>((
  ref,
  id,
) async {
  final (course, failure) = await ref.watch(getCourseByIdProvider)(id);
  if (failure != null) throw failure;

  // Contexto global de sesión: saber qué curso vio el estudiante.
  if (course != null) {
    ref
        .read(sessionContextProvider.notifier)
        .record('view_course', detail: course.title);
  }
  return course;
});
