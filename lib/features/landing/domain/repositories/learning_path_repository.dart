import '../../../../core/error/failures.dart';
import '../entities/learning_path.dart';

/// Contrato de acceso a las rutas de entrenamiento.
/// Hoy lo cumple un datasource remoto contra el server Node + Supabase.
abstract interface class LearningPathRepository {
  /// Rutas publicadas (pantalla /rutas), o un [Failure] si algo sale mal.
  Future<(List<LearningPath>, Failure?)> getPaths();

  /// Ruta por slug (pantalla /rutas/:slug).
  ///
  /// `(null, null)` = no existe (404); `Failure` = error real
  /// (red, servidor).
  Future<(LearningPath?, Failure?)> getPathBySlug(String slug);
}
