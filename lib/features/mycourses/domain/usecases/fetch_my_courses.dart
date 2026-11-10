import '../../../../core/usecase/usecase.dart';
import '../entities/enrolled_course.dart';
import '../repositories/my_courses_repository.dart';

/// Caso de uso: cursos inscritos del usuario de la sesión ("Mis cursos").
class FetchMyCourses extends UseCase<List<EnrolledCourse>, NoParams> {
  FetchMyCourses(this._repository);

  final MyCoursesRepository _repository;

  @override
  Future<List<EnrolledCourse>> call(NoParams params) =>
      _repository.fetchMyCourses();
}
