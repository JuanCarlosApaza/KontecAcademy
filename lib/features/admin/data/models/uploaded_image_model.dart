import 'package:equatable/equatable.dart';

/// DTO de la respuesta de `POST /admin/upload-image`.
class UploadedImageModel extends Equatable {
  const UploadedImageModel({required this.publicUrl});

  /// URL pública de la imagen subida al bucket "courses".
  final String publicUrl;

  factory UploadedImageModel.fromJson(Map<String, dynamic> json) =>
      UploadedImageModel(publicUrl: json['publicUrl'] as String? ?? '');

  @override
  List<Object?> get props => [publicUrl];
}
