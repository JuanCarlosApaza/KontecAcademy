import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enrolled_course.dart';
import '../../domain/repositories/my_courses_repository.dart';
import '../datasources/my_courses_remote_datasource.dart';

/// Implementación de "Mis cursos": traduce los modelos del datasource
/// a entidades de dominio. Las excepciones (data) suben tal cual y las
/// consume el FutureProvider (estado de error en la pantalla).
final myCoursesRepositoryProvider = Provider<MyCoursesRepository>(
  (ref) =>
      MyCoursesRepositoryImpl(ref.watch(myCoursesRemoteDataSourceProvider)),
);

class MyCoursesRepositoryImpl implements MyCoursesRepository {
  MyCoursesRepositoryImpl(this._remote);

  final MyCoursesRemoteDataSource _remote;

  @override
  Future<List<EnrolledCourse>> fetchMyCourses() async {
    final models = await _remote.fetchMyCourses();
    return [for (final model in models) model.toEntity()];
  }
}
