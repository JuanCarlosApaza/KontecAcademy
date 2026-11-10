import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../domain/entities/admin_curriculum.dart';
import '../../domain/entities/new_course.dart';
import '../../domain/entities/new_lesson.dart';
import '../../domain/entities/new_module.dart';
import '../../domain/repositories/course_admin_repository.dart';
import '../datasources/course_admin_remote_datasource.dart';
import '../datasources/curriculum_admin_remote_datasource.dart';

/// Implementación del repositorio admin: habla con la API REST.
///
/// Su responsabilidad: traducir excepciones (`data`) en fallas (`domain`)
/// y convertir el modelo de respuesta en entidad. Nada más.
final courseAdminRepositoryProvider = Provider<CourseAdminRepository>(
  (ref) => CourseAdminRepositoryImpl(
    ref.watch(courseAdminRemoteDataSourceProvider),
    ref.watch(curriculumAdminRemoteDataSourceProvider),
  ),
);

class CourseAdminRepositoryImpl implements CourseAdminRepository {
  CourseAdminRepositoryImpl(this._remote, this._curriculum);

  final CourseAdminRemoteDataSource _remote;
  final CurriculumAdminRemoteDataSource _curriculum;

  @override
  Future<(TrainingCourse, Failure?)> createCourse(NewCourse input) async {
    try {
      final model = await _remote.createCourse(input);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        _emptyCourse(input),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (_emptyCourse(input), NetworkFailure(e.message));
    } catch (e) {
      return (_emptyCourse(input), UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(TrainingCourse, Failure?)> updateCourse(
    String id,
    NewCourse input,
  ) async {
    try {
      final model = await _remote.updateCourse(id, input);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (
        _emptyCourse(input),
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return (_emptyCourse(input), NetworkFailure(e.message));
    } catch (e) {
      return (_emptyCourse(input), UnknownFailure(e.toString()));
    }
  }

  TrainingCourse _emptyCourse(NewCourse input) => TrainingCourse(
    id: '',
    title: input.title,
    modality: input.modality,
    category: '',
  );

  // ── TEMARIO ──────────────────────────────────────────────────

  @override
  Future<(AdminCurriculum?, Failure?)> fetchCurriculum(
    String courseId,
  ) async {
    try {
      final model = await _curriculum.fetchCurriculum(courseId);
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
  Future<(AdminModule?, Failure?)> saveModule(NewModule input) async {
    try {
      final model = await _curriculum.saveModule(input);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (null, NetworkFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> deleteModule(String moduleId) async {
    try {
      await _curriculum.deleteModule(moduleId);
      return (true, null);
    } on ServerException catch (e) {
      return (false, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (false, NetworkFailure(e.message));
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AdminLesson?, Failure?)> saveLesson(
    String moduleId,
    NewLesson input,
  ) async {
    try {
      final model = await _curriculum.saveLesson(moduleId, input);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (null, NetworkFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> deleteLesson(String lessonId) async {
    try {
      await _curriculum.deleteLesson(lessonId);
      return (true, null);
    } on ServerException catch (e) {
      return (false, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (false, NetworkFailure(e.message));
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }
}
