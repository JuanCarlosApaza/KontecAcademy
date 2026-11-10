import 'package:equatable/equatable.dart';

/// Datos de una lección del temario (alta o edición, según [lessonId]).
class NewLesson extends Equatable {
  const NewLesson({
    required this.title,
    required this.contentType,
    this.videoUrl,
    this.zoomUrl,
    this.driveUrl,
    this.contentText,
    this.attachmentUrl,
    this.attachmentName,
    this.lessonId,
    this.orderIndex,
  });

  final String title;

  /// 'recorded' | 'live' | 'drive' | 'text' | 'file' | 'link'.
  final String contentType;

  final String? videoUrl;
  final String? zoomUrl;
  final String? driveUrl;

  /// Texto de la lección (tipo 'text').
  final String? contentText;

  /// Archivo o enlace adjunto (tipo 'file' | 'link').
  final String? attachmentUrl;
  final String? attachmentName;

  /// null = alta; con id = edición.
  final String? lessonId;

  /// Posición dentro del módulo (1-based). Solo al mover.
  final int? orderIndex;

  bool get isEditing => lessonId != null;

  @override
  List<Object?> get props => [
    title,
    contentType,
    videoUrl,
    zoomUrl,
    driveUrl,
    contentText,
    attachmentUrl,
    attachmentName,
    lessonId,
    orderIndex,
  ];
}
