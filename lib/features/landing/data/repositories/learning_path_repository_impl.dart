import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/learning_path.dart';
import '../../domain/repositories/learning_path_repository.dart';
import '../datasources/learning_path_remote_datasource.dart';

/// Implementación del repositorio de rutas: habla con la API REST.
///
/// Su responsabilidad: traducir excepciones (`data`) en fallas (`domain`)
/// y convertir modelos en entidades. Nada más.
final learningPathRepositoryProvider = Provider<LearningPathRepository>(
  (ref) => LearningPathRepositoryImpl(ref.watch(learningPathRemoteDataSourceProvider)),
);

class LearningPathRepositoryImpl implements LearningPathRepository {
  LearningPathRepositoryImpl(this._remote);

  final LearningPathRemoteDataSource _remote;

  @override
  Future<(List<LearningPath>, Failure?)> getPaths() async {
    try {
      final models = await _remote.fetchPaths();
      return (models.map((m) => m.toEntity()).toList(), null);
    } on ServerException catch (e) {
      return (<LearningPath>[], ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (<LearningPath>[], NetworkFailure(e.message));
    } catch (e) {
      return (<LearningPath>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LearningPath?, Failure?)> getPathBySlug(String slug) async {
    try {
      final model = await _remote.fetchPathBySlug(slug);
      return (model.toEntity(), null);
    } on ServerException catch (e) {
      // 404 = la ruta no existe (no es un error del sistema).
      if (e.statusCode == 404) return (null, null);
      return (null, ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return (null, NetworkFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
