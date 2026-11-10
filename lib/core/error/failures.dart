import 'package:equatable/equatable.dart';

/// Errores de nivel dominio: lo que la UI realmente "entiende".
/// Los repositorios convierten excepciones (`data`) en estas fallas.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {this.statusCode})
    : super('Error del servidor: $message');

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message)
    : super('Sin conexión a internet: $message');
}

class CacheFailure extends Failure {
  const CacheFailure(String message)
    : super('Error de datos locales: $message');
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super('Error inesperado: $message');
}
