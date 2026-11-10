import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/admin_repository.dart';

/// Caso de uso: subir una imagen local al bucket público "courses" de
/// Supabase Storage y obtener su URL pública.
class UploadCourseImage
    extends UseCase<(String, Failure?), UploadCourseImageParams> {
  UploadCourseImage(this._repository);

  final AdminRepository _repository;

  @override
  Future<(String, Failure?)> call(UploadCourseImageParams params) {
    return _repository.uploadImage(
      bytes: params.bytes,
      filename: params.filename,
      contentType: params.contentType,
    );
  }
}

class UploadCourseImageParams {
  const UploadCourseImageParams({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final List<int> bytes;
  final String filename;
  final String contentType;
}
