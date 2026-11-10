import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/my_courses_repository_impl.dart';
import 'domain/usecases/fetch_my_courses.dart';

/// Composition root del feature `mycourses`.
/// Aquí se ensamblan las capas; el dominio no importa data.
export 'data/repositories/my_courses_repository_impl.dart'
    show myCoursesRepositoryProvider;

final fetchMyCoursesProvider = Provider<FetchMyCourses>(
  (ref) => FetchMyCourses(ref.watch(myCoursesRepositoryProvider)),
);
