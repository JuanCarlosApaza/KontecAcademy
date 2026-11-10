import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_record.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: listado de estudiantes del panel.
class GetStudents extends UseCase<(List<StudentRecord>, Failure?), NoParams> {
  GetStudents(this._repository);

  final AdminRepository _repository;

  @override
  Future<(List<StudentRecord>, Failure?)> call(NoParams params) =>
      _repository.getStudents();
}
