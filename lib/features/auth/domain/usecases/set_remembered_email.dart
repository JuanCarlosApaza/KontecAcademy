import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/remember_email_repository.dart';

class SetRememberedEmailParams extends Equatable {
  const SetRememberedEmailParams({required this.email, required this.remember});

  final String email;
  final bool remember;

  @override
  List<Object?> get props => [email, remember];
}

/// Caso de uso: guardar/borrar el correo según el checkbox "Recuérdame".
class SetRememberedEmail extends UseCase<void, SetRememberedEmailParams> {
  SetRememberedEmail(this._repository);

  final RememberEmailRepository _repository;

  @override
  Future<void> call(SetRememberedEmailParams params) {
    return _repository.setRememberedEmail(
      params.email,
      remember: params.remember,
    );
  }
}
