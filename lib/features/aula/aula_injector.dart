import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/curriculum_repository_impl.dart';
import 'domain/usecases/get_curriculum.dart';
import 'domain/usecases/set_lesson_progress.dart';

/// Composition root del feature `aula`.
/// Aquí se ensamblan las capas; el dominio no importa data.
export 'data/repositories/curriculum_repository_impl.dart'
    show curriculumRepositoryProvider;

final getCurriculumProvider = Provider<GetCurriculum>(
  (ref) => GetCurriculum(ref.watch(curriculumRepositoryProvider)),
);

final setLessonProgressProvider = Provider<SetLessonProgress>(
  (ref) => SetLessonProgress(ref.watch(curriculumRepositoryProvider)),
);
