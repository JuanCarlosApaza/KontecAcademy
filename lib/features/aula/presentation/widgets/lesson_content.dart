import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/quill_content.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_curriculum.dart';
import 'embedded_video_player.dart';

/// Contenido de una lección del aula.
///
/// El tipo se deduce de la URL porque la BD guarda tres columnas
/// distintas (video / zoom / drive) y el backend devuelve solo la
/// primera que encuentre: así la UI no depende de `contentType`, que en
/// la BD es una clave libre.
class LessonContent extends StatelessWidget {
  const LessonContent({
    super.key,
    required this.lesson,
    this.onVideoEnded,
  });

  final CurriculumLesson lesson;

  /// Se dispara cuando el video embebido termina (para auto-marcar
  /// la lección como completada, estilo Moodle/Tutor LMS).
  final VoidCallback? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    final url = lesson.contentUrl;
    final text = lesson.contentText;
    final attachmentUrl = lesson.attachmentUrl;

    final hasUrl = url != null && url.isNotEmpty;
    final hasText = text != null && text.trim().isNotEmpty;
    final hasAttachment = attachmentUrl != null && attachmentUrl.isNotEmpty;

    // Sin contenido publicado (o pago sin aprobar): el backend manda
    // todo en null y aquí no hay nada que mostrar.
    if (!hasUrl && !hasText && !hasAttachment) {
      return const _Placeholder(
        icon: Icons.hourglass_empty,
        title: 'Contenido próximamente',
        message: 'El docente aún no publicó el material de esta lección.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasText) _textSection(text),
        if (hasText && (hasUrl || hasAttachment)) const SizedBox(height: 14),
        if (hasAttachment)
          _attachmentSection(
            context,
            url: attachmentUrl,
            name: lesson.attachmentName,
          ),
        if (hasAttachment && hasUrl) const SizedBox(height: 14),
        // Video de YouTube → se embebe en el aula (con auto-marca al
        // terminar); cualquier otro enlace sale fuera con launchUrl.
        if (hasUrl) ...[
          if (EmbeddedVideoPlayer.canEmbed(url))
            EmbeddedVideoPlayer(url: url, onVideoEnded: onVideoEnded)
          else
            _linkSection(context, url),
        ],
      ],
    );
  }

  /// Texto de la lección (bienvenida, guía, notas del docente).
  ///
  /// Se guarda como Delta JSON (editor con formato); el texto plano
  /// heredado se sigue pintando tal cual.
  Widget _textSection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.article_outlined, color: AppColors.textDark, size: 22),
              SizedBox(width: 10),
              Text(
                'Contenido de la lección',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: isQuillDelta(text)
                ? _QuillLessonText(deltaJson: text)
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: AppColors.textDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Archivo o enlace adjunto del docente (PDF, ZIP, Drive…).
  Widget _attachmentSection(BuildContext context, {required String url, String? name}) {
    final isDrive = url.toLowerCase().contains('drive.google.com');
    final label = name != null && name.trim().isNotEmpty
        ? name.trim()
        : isDrive
        ? 'Material en Google Drive'
        : 'Archivo de la lección';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Icon(
                  isDrive ? Icons.folder_open_outlined : Icons.attach_file,
                  color: AppColors.textDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDrive
                          ? 'Documento o carpeta compartida'
                          : 'Archivo para descargar o abrir',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openUrl(context, url),
              icon: Icon(
                isDrive ? Icons.folder_open_outlined : Icons.download_outlined,
                size: 20,
              ),
              label: Text(isDrive ? 'Abrir en Google Drive' : 'Abrir archivo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Video / clase / material externo (el tipo se deduce de la URL).
  Widget _linkSection(BuildContext context, String url) {
    final kind = ContentKind.of(url);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Icon(kind.icon, color: AppColors.textDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kind.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openUrl(context, url),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(kind.action),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final messenger = ScaffoldMessenger.of(context);

    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('La dirección del contenido no es válida'),
        ),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el contenido')),
      );
    }
  }
}

/// Contenido de la lección renderizado con formato (solo lectura).
///
/// Vive dentro del `ListView` del aula, así que va sin scroll propio
/// (`scrollable: false`): crece con el contenido y lo mueve el aula.
class _QuillLessonText extends StatefulWidget {
  const _QuillLessonText({required this.deltaJson});

  final String deltaJson;

  @override
  State<_QuillLessonText> createState() => _QuillLessonTextState();
}

class _QuillLessonTextState extends State<_QuillLessonText> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: documentFromContentText(widget.deltaJson),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultStyles.getInstance(context);

    return QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        scrollable: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: defaults.paragraph?.copyWith(
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textDark,
            ),
          ),
          link: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        onLaunchUrl: (url) async {
          final uri = Uri.tryParse(url);
          if (uri == null || !uri.hasScheme) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

/// Tipo de contenido deducido de la URL de la lección.
enum ContentKind {
  video,
  live,
  drive,
  link;

  /// Clasifica una URL de contenido del aula.
  factory ContentKind.of(String url) {
    final normalized = url.toLowerCase();
    final isVideo =
        normalized.contains('youtube.com') ||
        normalized.contains('youtu.be') ||
        RegExp(r'\.(mp4|webm|m3u8)(\?|$)').hasMatch(normalized);
    if (isVideo) return ContentKind.video;

    if (normalized.contains('zoom.us')) return ContentKind.live;
    if (normalized.contains('drive.google.com') ||
        normalized.contains('docs.google.com')) {
      return ContentKind.drive;
    }
    return ContentKind.link;
  }

  String get label => switch (this) {
    ContentKind.video => 'Video de la clase',
    ContentKind.live => 'Clase en vivo',
    ContentKind.drive => 'Material del curso',
    ContentKind.link => 'Contenido de la lección',
  };

  String get description => switch (this) {
    ContentKind.video => 'Se abrirá en una pestaña nueva',
    ContentKind.live => 'Grabación o enlace de la sesión en vivo',
    ContentKind.drive => 'Documento o carpeta compartida',
    ContentKind.link => 'Recurso externo del docente',
  };

  String get action => switch (this) {
    ContentKind.video => 'Ver el video',
    ContentKind.live => 'Unirse o ver la clase',
    ContentKind.drive => 'Abrir en Google Drive',
    ContentKind.link => 'Abrir contenido',
  };

  IconData get icon => switch (this) {
    ContentKind.video => Icons.play_circle_outline,
    ContentKind.live => Icons.videocam_outlined,
    ContentKind.drive => Icons.folder_open_outlined,
    ContentKind.link => Icons.link,
  };
}

/// Aviso a pantalla completa (sin acceso / sin contenido).
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
