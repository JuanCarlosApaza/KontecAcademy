import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../landing/data/models/learning_path_model.dart';
import '../../../landing/domain/entities/learning_path.dart';
import '../../data/datasources/paths_admin_remote_datasource.dart';
import '../../domain/repositories/paths_repository.dart';

/// Implementación del CRUD de rutas del panel: habla con la API REST.
///
/// Su responsabilidad: traducir excepciones (`data`) en fallas
/// (`domain`) y convertir el JSON en las entidades de `landing`
/// (mismo contrato que consume la pantalla pública).
final pathsRepositoryProvider = Provider<PathsAdminRepository>(
  (ref) => PathsAdminRepositoryImpl(ref.watch(pathsAdminRemoteDataSourceProvider)),
);

class PathsAdminRepositoryImpl implements PathsAdminRepository {
  PathsAdminRepositoryImpl(this._remote);

  final PathsAdminRemoteDataSource _remote;

  @override
  Future<(List<LearningPath>, Failure?)> listPaths() async {
    try {
      final rows = await _remote.listPaths();
      return (
        rows.map((row) => LearningPathModel.fromJson(row).toEntity()).toList(),
        null,
      );
    } catch (e) {
      return (<LearningPath>[], _failure(e));
    }
  }

  @override
  Future<(LearningPath?, Failure?)> createPath(AdminPathInput input) async {
    try {
      final row = await _remote.createPath(_toBody(input));
      return (LearningPathModel.fromJson(row).toEntity(), null);
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(LearningPath?, Failure?)> updatePath(
    String id,
    AdminPathInput input,
  ) async {
    try {
      final row = await _remote.updatePath(id, _toBody(input));
      return (LearningPathModel.fromJson(row).toEntity(), null);
    } on ServerException catch (e) {
      // 404 = la ruta no existe (no es un error del sistema).
      if (e.statusCode == 404) return (null, null);
      return (null, _failure(e));
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(LearningPath?, Failure?)> setPathCourses(
    String id,
    List<PathCourseAssignment> courses,
  ) async {
    try {
      final row = await _remote.setPathCourses(
        id,
        [
          for (final course in courses)
            {
              'courseId': course.courseId,
              'level': course.level,
              'sortOrder': course.sortOrder,
            },
        ],
      );
      return (LearningPathModel.fromJson(row).toEntity(), null);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return (null, null);
      return (null, _failure(e));
    } catch (e) {
      return (null, _failure(e));
    }
  }

  @override
  Future<(bool, Failure?)> deletePath(String id) async {
    try {
      await _remote.deletePath(id);
      return (true, null);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return (false, null);
      return (false, _failure(e));
    } catch (e) {
      return (false, _failure(e));
    }
  }

  Failure _failure(Object error) {
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    if (error is NetworkException) return NetworkFailure(error.message);
    return UnknownFailure(error.toString());
  }

  Map<String, dynamic> _toBody(AdminPathInput input) => {
    'title': input.title,
    if (input.slug != null && input.slug!.isNotEmpty) 'slug': input.slug,
    'description': input.description,
    'coverUrl': input.coverUrl,
    'modality': input.modality,
    'durationHours': input.durationHours,
    'accessMonths': input.accessMonths,
    'discountPercent': input.discountPercent,
    'sortOrder': input.sortOrder,
    'isPublished': input.isPublished,
  };
}
