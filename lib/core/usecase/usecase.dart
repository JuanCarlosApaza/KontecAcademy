/// Contrato base de todos los casos de uso del dominio.
///
/// Cada caso de uso representa UNA sola acción de negocio y expone
/// un único método [call]. La capa de presentación (ViewModels) es
/// la única que los invoca; los Widgets jamás lo hacen.
///
/// Ejemplo de uso:
/// ```dart
/// class GetTasks extends UseCase<(List<Task>, Failure?), NoParams> { ... }
/// ```
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Parámetro vacío para casos de uso sin entrada (ej: listar todo).
class NoParams {
  const NoParams();
}
