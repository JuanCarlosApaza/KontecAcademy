import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/quill_content.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../aula/presentation/widgets/embedded_video_player.dart';
import '../../domain/entities/admin_curriculum.dart';
import '../../domain/entities/new_lesson.dart';
import '../viewmodels/admin_curriculum_viewmodel.dart';
import 'admin_dialog.dart';

/// Tipos de contenido que sabe servir el aula (claves de la BD).
const kContentTypes = ['recorded', 'live', 'drive', 'text', 'file', 'link'];

const kContentTypeLabels = {
  'recorded': 'Video grabado',
  'live': 'Clase en vivo',
  'drive': 'Material en Drive',
  'text': 'Texto (bienvenida/guía)',
  'file': 'Archivo adjunto',
  'link': 'Enlace',
};

/// Icono de una lección según su tipo de contenido.
IconData lessonIcon(String contentType) => switch (contentType) {
  'text' => Icons.article_outlined,
  'file' => Icons.attach_file,
  'link' => Icons.link,
  'live' => Icons.videocam_outlined,
  'drive' => Icons.folder_open_outlined,
  _ => Icons.play_circle_outline,
};

/// Borde estándar de los campos del editor de lecciones.
OutlineInputBorder _inputBorder({Color color = const Color(0xFFE5E7EB)}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

InputDecoration _inputDecoration({
  required String label,
  String? hint,
  IconData? icon,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  isDense: true,
  prefixIcon: icon == null ? null : Icon(icon, size: 18),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: _inputBorder(),
  enabledBorder: _inputBorder(),
  focusedBorder: _inputBorder(color: AppColors.primary),
);

/// EDITOR DE LECCIÓN estilo Tutor LMS: dos columnas.
///
/// Izquierda: nombre + editor rico (toolbar Quill) con un conmutador
/// **Editor / Vista previa** para ver el contenido tal cual lo verá el
/// estudiante en el aula. Derecha: tipo de contenido, video con preview
/// de YouTube, Zoom, Drive y adjunto.
class AdminLessonEditor extends ConsumerStatefulWidget {
  const AdminLessonEditor({super.key, required this.module, this.initial});

  final AdminModule module;
  final AdminLesson? initial;

  /// Abre el diálogo con este editor (ancho, dos columnas).
  ///
  /// Devuelve true si la lección se guardó (para que el caller muestre
  /// su alerta de éxito con un contexto que ya no está dentro del
  /// diálogo).
  static Future<bool> show(
    BuildContext context, {
    required AdminModule module,
    AdminLesson? initial,
  }) async {
    final saved = await showAdminDialog<bool>(
      context: context,
      title: initial == null ? 'Nueva lección' : 'Editar lección',
      subtitle: module.title,
      width: 960,
      child: AdminLessonEditor(module: module, initial: initial),
    );
    return saved == true;
  }

  @override
  ConsumerState<AdminLessonEditor> createState() => _AdminLessonEditorState();
}

class _AdminLessonEditorState extends ConsumerState<AdminLessonEditor> {
  late final TextEditingController _title;
  late final TextEditingController _videoUrl;
  late final TextEditingController _zoomUrl;
  late final TextEditingController _driveUrl;
  late final TextEditingController _attachmentUrl;
  late final TextEditingController _attachmentName;

  late final QuillController _quill;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScroll = ScrollController();

  late String _contentType;

  /// true = mostrando la vista previa en la columna izquierda.
  bool _previewMode = false;

  /// Delta del contenido al entrar en vista previa (para que el
  /// preview no cambie mientras se sigue escribiendo en el editor).
  String _previewDelta = '';

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _videoUrl = TextEditingController(text: initial?.videoUrl ?? '');
    _zoomUrl = TextEditingController(text: initial?.zoomUrl ?? '');
    _driveUrl = TextEditingController(text: initial?.driveUrl ?? '');
    _attachmentUrl = TextEditingController(text: initial?.attachmentUrl ?? '');
    _attachmentName = TextEditingController(
      text: initial?.attachmentName ?? '',
    );
    _contentType = kContentTypes.contains(initial?.contentType)
        ? initial!.contentType
        : 'recorded';
    _quill = QuillController.basic()
      ..document = documentFromContentText(initial?.contentText);
  }

  @override
  void dispose() {
    _title.dispose();
    _videoUrl.dispose();
    _zoomUrl.dispose();
    _driveUrl.dispose();
    _attachmentUrl.dispose();
    _attachmentName.dispose();
    _quill.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCurriculumViewModelProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final content = _buildContentColumn(state);
            final settings = _buildSettingsColumn(state);

            // En columnas angostas (< 560) las dos columnas se
            // apilan: en fila cada una queda con ~130 px y los
            // campos de texto quedan inutilizables.
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [content, const SizedBox(height: 18), settings],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Columna izquierda: nombre + editor de contenido ──
                Expanded(flex: 5, child: content),
                const SizedBox(width: 22),
                // ── Columna derecha: tipo, video, enlaces, adjunto ────
                Expanded(flex: 4, child: settings),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        AdminDialogActions(
          confirmLabel: _isEditing ? 'Guardar cambios' : 'Crear lección',
          confirmIcon: _isEditing ? Icons.check : Icons.add,
          isSubmitting: state.isSubmitting,
          onConfirm: _submit,
        ),
      ],
    );
  }

  // ── Columna izquierda ────────────────────────────────────────────

  /// Encabezado "Contenido de la lección" + conmutador Editor/Preview.
  ///
  /// En columnas angostas apila el toggle debajo del título para que
  /// la fila no desborde (el diálogo es responsive).
  Widget _buildSectionHeader(AdminCurriculumState state) {
    final toggle = _EditorPreviewToggle(
      previewMode: _previewMode,
      enabled: !state.isSubmitting,
      onChanged: (preview) => _setPreviewMode(preview),
    );

    const label = Text(
      'Contenido de la lección',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // ~300px es lo mínimo para que título + toggle quepan en fila.
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 8), toggle],
          );
        }
        return Row(
          children: [
            const Expanded(child: label),
            const SizedBox(width: 10),
            toggle,
          ],
        );
      },
    );
  }

  Widget _buildContentColumn(AdminCurriculumState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          enabled: !state.isSubmitting,
          decoration: _inputDecoration(
            label: 'Nombre de la lección',
            icon: Icons.title,
          ),
        ),
        const SizedBox(height: 18),
        _buildSectionHeader(state),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_previewMode) ...[
                QuillSimpleToolbar(
                  controller: _quill,
                  config: const QuillSimpleToolbarConfig(
                    axis: Axis.horizontal,
                    showFontFamily: false,
                    showFontSize: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSmallButton: false,
                    showLineHeightButton: false,
                    showDirection: false,
                    showAlignmentButtons: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showSearchButton: false,
                    showDividers: false,
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                IgnorePointer(
                  ignoring: state.isSubmitting,
                  child: SizedBox(
                    height: 320,
                    child: QuillEditor(
                      controller: _quill,
                      focusNode: _editorFocus,
                      scrollController: _editorScroll,
                      config: QuillEditorConfig(
                        placeholder:
                            'Escribe aquí el contenido de la lección '
                            '(texto, listas, enlaces, código)…',
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
              ] else
                _buildPreview(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _previewMode
              ? ' Así verá el estudiante esta lección en el aula. Cambia '
                    'a "Editor" para seguir escribiendo.'
              : 'Lo que escribas aquí se muestra en el aula con el formato '
                    'elegido (negrita, listas, enlaces…).',
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// Cambia entre editor y vista previa; al entrar en preview congela
  /// una copia del Delta actual para que coincida con lo que se ve.
  void _setPreviewMode(bool preview) {
    _editorFocus.unfocus();
    setState(() {
      _previewMode = preview;
      if (preview) {
        _previewDelta = contentTextFromDocument(_quill.document);
      }
    });
  }

  Widget _buildPreview() {
    final isEmpty = _quill.document.toPlainText().trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: AppColors.surface,
          // Wrap (no Row con Spacer): en columnas angostas el grupo
          // "Vista previa" pasa a la segunda línea en vez de desbordar.
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    lessonIcon(_contentType),
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kContentTypeLabels[_contentType] ?? _contentType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Vista previa',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        if (isEmpty)
          const SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 38, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'Esta lección aún no tiene contenido.\n'
                    'Vuelve a "Editor" para escribirlo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(height: 320, child: _QuillPreview(deltaJson: _previewDelta)),
      ],
    );
  }

  // ── Columna derecha ──────────────────────────────────────────────

  Widget _buildSettingsColumn(AdminCurriculumState state) {
    final enabled = !state.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('lesson-type-$_contentType'),
          initialValue: _contentType,
          decoration: _inputDecoration(
            label: 'Tipo de contenido',
            icon: Icons.category_outlined,
          ),
          items: [
            for (final value in kContentTypes)
              DropdownMenuItem(
                value: value,
                child: Text(
                  kContentTypeLabels[value] ?? value,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
          ],
          onChanged: enabled
              ? (value) => setState(() => _contentType = value ?? 'recorded')
              : null,
        ),
        const SizedBox(height: 14),
        _urlField(
          controller: _videoUrl,
          label: 'URL del video (YouTube o .mp4)',
          enabled: enabled,
          icon: Icons.play_circle_outline,
        ),
        _buildVideoPreview(_videoUrl.text),
        const SizedBox(height: 12),
        _urlField(
          controller: _zoomUrl,
          label: 'URL de Zoom (clase en vivo)',
          enabled: enabled,
          icon: Icons.videocam_outlined,
        ),
        const SizedBox(height: 12),
        _urlField(
          controller: _driveUrl,
          label: 'URL de Google Drive',
          enabled: enabled,
          icon: Icons.folder_open_outlined,
        ),
        const SizedBox(height: 12),
        _urlField(
          controller: _attachmentUrl,
          label: 'URL del adjunto (PDF, ZIP, enlace…)',
          enabled: enabled,
          icon: Icons.attach_file,
        ),
        const SizedBox(height: 12),
        _urlField(
          controller: _attachmentName,
          label: 'Nombre visible del adjunto (ej: Syllabus.pdf)',
          enabled: enabled,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        const Text(
          'El aula muestra la primera URL que encuentre (video → Zoom → '
          'Drive) y el adjunto como botón aparte. Déjalas vacías si la '
          'lección aún no tiene material.',
          style: TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// Miniatura de YouTube bajo el campo de video (preview estilo Tutor).
  Widget _buildVideoPreview(String url) {
    final videoId = extractYoutubeVideoId(url);

    if (videoId == null) {
      if (url.trim().isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No es un video de YouTube: el aula lo abrirá en otra '
                'pestaña.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 44,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urlField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    IconData icon = Icons.link,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.url,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      await showAppWarning(
        context,
        title: 'Falta el nombre',
        message: 'Escribe un título para la lección antes de guardarla.',
      );
      return;
    }

    String? url(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    final input = NewLesson(
      lessonId: widget.initial?.id,
      title: title,
      contentType: _contentType,
      videoUrl: url(_videoUrl),
      zoomUrl: url(_zoomUrl),
      driveUrl: url(_driveUrl),
      contentText: contentTextFromDocument(_quill.document),
      attachmentUrl: url(_attachmentUrl),
      attachmentName: url(_attachmentName),
    );

    final notifier = ref.read(adminCurriculumViewModelProvider.notifier);
    final ok = await runWithAppLoading(
      context,
      notifier.saveLesson(widget.module.id, input),
      text: 'Guardando lección…',
    );
    if (!mounted) return;

    if (ok != true) {
      final error =
          ref.read(adminCurriculumViewModelProvider).submitError ??
          'Intenta de nuevo en unos segundos.';
      await showAppError(
        context,
        title: 'No se pudo guardar la lección',
        message: error,
      );
      return;
    }

    // Cierra el diálogo con true; el caller muestra la alerta de éxito.
    notifier.clearSuccess();
    Navigator.of(context).pop(true);
  }
}

/// Conmutador Editor / Vista previa del contenido de la lección.
class _EditorPreviewToggle extends StatelessWidget {
  const _EditorPreviewToggle({
    required this.previewMode,
    required this.onChanged,
    this.enabled = true,
  });

  final bool previewMode;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: ButtonStyle(
        side: WidgetStatePropertyAll(
          BorderSide(
            color: enabled ? const Color(0xFFE5E7EB) : const Color(0xFFF1F5F9),
          ),
        ),
        visualDensity: VisualDensity.compact,
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textDark,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.black
              : Colors.white,
        ),
      ),
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.edit_outlined, size: 16),
          label: Text('Editor', style: TextStyle(fontSize: 12.5)),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.visibility_outlined, size: 16),
          label: Text('Vista previa', style: TextStyle(fontSize: 12.5)),
        ),
      ],
      selected: {previewMode},
      onSelectionChanged: enabled
          ? (selection) => onChanged(selection.first)
          : null,
    );
  }
}

/// Contenido renderizado en solo lectura, con el mismo estilo que verá
/// el estudiante en el aula.
class _QuillPreview extends StatefulWidget {
  const _QuillPreview({required this.deltaJson});

  final String deltaJson;

  @override
  State<_QuillPreview> createState() => _QuillPreviewState();
}

class _QuillPreviewState extends State<_QuillPreview> {
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
        padding: const EdgeInsets.all(14),
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
