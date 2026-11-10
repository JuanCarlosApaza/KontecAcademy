import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/admin_user_record.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: editar un usuario del panel (perfil, rol y estado).
///
/// [isActive] false = desactiva el acceso; es un borrado LÓGICO: la
/// cuenta y todos sus datos se conservan en la BD.
class UpdateUser
    extends UseCase<(AdminUserRecord, Failure?), UpdateUserParams> {
  UpdateUser(this._repository);

  final AdminRepository _repository;

  @override
  Future<(AdminUserRecord, Failure?)> call(UpdateUserParams params) {
    return _repository.updateUser(
      id: params.id,
      fullName: params.fullName,
      phone: params.phone,
      role: params.role,
      isActive: params.isActive,
    );
  }
}

class UpdateUserParams {
  const UpdateUserParams({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
}
