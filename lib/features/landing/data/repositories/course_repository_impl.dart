import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/training_course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

/// Implementación del repositorio: habla con la API REST del server.
///
/// Su responsabilidad: traducir excepciones (`data`) en fallas (`domain`)
/// y convertir modelos en entidades. Nada más.
/// Para cambiar la API por una fuente local, solo se reemplaza este wiring.
final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepositoryImpl(ref.watch(courseRemoteDataSourceProvider)),
);

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._remote);

  final CourseRemoteDataSource _remote;

  @override
  Future<(List<TrainingCourse>, Failure?)> getFeaturedCourses() =>
      _guard(_fetchCourses);

  @override
  Future<(List<TrainingCourse>, Failure?)> getAllCourses() =>
      _guard(_fetchCourses);

  @override
  Future<(TrainingCourse?, Failure?)> getCourseById(String id) async {
    try {
      final model = await _remote.fetchCourseById(id);
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
  Future<(List<Category>, Failure?)> getCategories() => _guard(
    () async =>
        (await _remote.fetchCategories()).map((m) => m.toEntity()).toList(),
  );

  Future<List<TrainingCourse>> _fetchCourses() async =>
      (await _remote.fetchCourses()).map((m) => m.toEntity()).toList();

  /// Ejecuta [fetch] y traduce cualquier excepción → [Failure]
  /// (las excepciones de datos NUNCA salen de esta capa).
  Future<(List<T>, Failure?)> _guard<T>(
    Future<List<T>> Function() fetch,
  ) async {
    try {
      final items = await fetch();
      return (items, null);
    } on ServerException catch (e) {
      return (<T>[], ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (<T>[], NetworkFailure(e.message));
    } catch (e) {
      return (<T>[], UnknownFailure(e.toString()));
    }
  }
}
