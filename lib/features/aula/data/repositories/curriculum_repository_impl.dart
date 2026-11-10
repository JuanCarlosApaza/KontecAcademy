import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/course_curriculum.dart';
import '../../domain/repositories/curriculum_repository.dart';
import '../datasources/curriculum_remote_datasource.dart';

/// Implementación del aula: traduce modelos a entidades y excepciones
/// (`data`) a fallas (`domain`). Nada más.
final curriculumRepositoryProvider = Provider<CurriculumRepository>(
  (ref) =>
      CurriculumRepositoryImpl(ref.watch(curriculumRemoteDataSourceProvider)),
);

class CurriculumRepositoryImpl implements CurriculumRepository {
  CurriculumRepositoryImpl(this._remote);

  final CurriculumRemoteDataSource _remote;

  @override
  Future<(CourseCurriculum?, Failure?)> fetchCurriculum(String courseId) async {
    try {
      final model = await _remote.fetchCurriculum(courseId);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      // 404 = el curso no existe (no es un error del sistema).
      if (e.statusCode == 404) return (null, null);
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (null, NetworkFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Failure?> setLessonProgress(
    String lessonId, {
    required bool completed,
  }) async {
    try {
      await _remote.setLessonProgress(lessonId, completed: completed);
      return null;
    } on ServerException catch (e) {
      return ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      return NetworkFailure(e.message);
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
