import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../landing/domain/entities/category.dart';
import '../../../landing/domain/entities/training_course.dart';
import '../../../landing/landing_injector.dart';
import '../../domain/entities/new_course.dart';
import '../viewmodels/admin_courses_viewmodel.dart';
import '../viewmodels/admin_providers.dart';
import 'admin_badges.dart';
import 'admin_dialog.dart';

/// Borde estándar de los campos del formulario de curso.
OutlineInputBorder _inputBorder({Color color = const Color(0xFFE5E7EB)}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );

InputDecoration _inputDecoration({required String label, String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: AppColors.primary),
    );

/// Encabezado de sección del formulario (icono + título + ayuda).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.icon, this.hint});

  final String title;
  final IconData? icon;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 7),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(
              hint!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Formulario de creación/edición de curso, pensado para usarse dentro
/// de `showAdminDialog` (botones "Nuevo curso" y "Editar" de la tabla).
///
/// Con [initial] cargado funciona en modo EDICIÓN (también es el camino
/// del "desactivar/reactivar" lógico, vía el selector de estado).
/// Al guardar con éxito cierra el diálogo con `true`.
class AdminCourseForm extends ConsumerStatefulWidget {
  const AdminCourseForm({super.key, this.initial});

  /// Curso a editar; null = creación nueva.
  ///
  /// En edición precarga ambos precios: `price` (precio general) y
  /// `compareAtPrice` (precio de OFERTA, que la UI pinta como descuento).
  /// Dejar el de oferta vacío lo guarda como null (curso sin descuento).
  final TrainingCourse? initial;

  @override
  ConsumerState<AdminCourseForm> createState() => _AdminCourseFormState();
}

class _AdminCourseFormState extends ConsumerState<AdminCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _hoursController = TextEditingController(text: '40');
  final _weeksController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _professorController = TextEditingController();
  final _teachingMethodController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  final _certificateController = TextEditingController();
  final _careersController = TextEditingController();

  List<Category> _categories = const [];
  bool _loadingCategories = true;
  String? _categoryId;
  String _modality = 'asynchronous';
  String _status = 'active';

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _titleController.text = initial.title;
      _descriptionController.text = initial.description;
      _imageUrlController.text = initial.imageUrl ?? '';
      _hoursController.text = '${initial.hours}';
      _weeksController.text = initial.totalWeeks?.toString() ?? '';
      _priceController.text = initial.price == initial.price.truncateToDouble()
          ? '${initial.price.toInt()}'
          : '${initial.price}';
      _compareAtPriceController.text = initial.compareAtPrice == null
          ? ''
          : initial.compareAtPrice!.toStringAsFixed(
              initial.compareAtPrice!.truncateToDouble() ==
                      initial.compareAtPrice!
                  ? 0
                  : 2,
            );
      // Tolera datos heredados: solo admite las claves del dropdown.
      _modality =
          initial.modality == 'live' || initial.modality == 'asynchronous'
          ? initial.modality
          : 'asynchronous';
      _status = kCourseStatusLabels.containsKey(initial.status)
          ? initial.status
          : 'active';
      _professorController.text = initial.professorBio ?? '';
      _teachingMethodController.text = initial.teachingMethod ?? '';
      _targetAudienceController.text = initial.targetAudience ?? '';
      _certificateController.text = initial.certificateInfo ?? '';
      _careersController.text = initial.careerOpportunities ?? '';
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _hoursController.dispose();
    _weeksController.dispose();
    _priceController.dispose();
    _compareAtPriceController.dispose();
    _professorController.dispose();
    _teachingMethodController.dispose();
    _targetAudienceController.dispose();
    _certificateController.dispose();
    _careersController.dispose();
    super.dispose();
  }

  /// Carga las categorías reales y, en edición, marca la del curso.
  Future<void> _loadCategories() async {
    final (categories, failure) = await ref.read(getCategoriesProvider)(
      NoParams(),
    );

    if (!mounted) return;
    final initial = widget.initial;
    setState(() {
      _categories = failure == null ? categories : const [];
      _loadingCategories = false;
      // Prioriza el id de la entidad; si no, busca por nombre.
      _categoryId =
          initial?.categoryId ??
          _categories
              .where((category) => category.name == (initial?.category ?? ''))
              .map((category) => category.id)
              .firstOrNull;
      // En creación, preselecciona la primera categoría disponible.
      if (initial == null && _categoryId == null && _categories.isNotEmpty) {
        _categoryId = _categories.first.id;
      }
    });
  }

  /// Convierte texto de precio → double aceptando coma decimal ("150,50").
  double? _parseNumber(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Texto del campo → null si quedó vacío (la API guarda null, no '').
  String? _emptyToNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Abre el selector de archivos del sistema, sube la imagen al bucket
  /// público "courses" de Supabase Storage y coloca la URL pública en
  /// el campo de imagen (esa URL es la que se guarda en la BD).
  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.isNotEmpty ?? false ? result!.files.first : null;
    if (file == null) return;

    // En web los bytes vienen siempre con withData: true.
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty || !mounted) return;

    final contentType = switch ((file.extension ?? '').toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'avif' => 'image/avif',
      _ => 'image/jpeg',
    };

    final url = await runWithAppLoading(
      context,
      ref
          .read(adminViewModelProvider.notifier)
          .uploadImage(
            bytes: bytes,
            filename: file.name,
            contentType: contentType,
          ),
      text: 'Subiendo imagen…',
    );

    if (url == null || !mounted) return;
    setState(() => _imageUrlController.text = url);
    await showAppSuccess(
      context,
      title: 'Imagen subida',
      message: 'Se guardó en el bucket "courses".',
    );
  }

  /// Valida el formulario y envía el curso a la API (crear o actualizar).
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final input = NewCourse(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      categoryId: _categoryId,
      modality: _modality,
      totalHours: int.tryParse(_hoursController.text.trim()) ?? 0,
      totalWeeks: int.tryParse(_weeksController.text.trim()),
      price: _parseNumber(_priceController.text) ?? 0,
      compareAtPrice: _parseNumber(_compareAtPriceController.text),
      status: _status,
      professorBio: _emptyToNull(_professorController),
      teachingMethod: _emptyToNull(_teachingMethodController),
      targetAudience: _emptyToNull(_targetAudienceController),
      certificateInfo: _emptyToNull(_certificateController),
      careerOpportunities: _emptyToNull(_careersController),
    );

    final initial = widget.initial;
    final notifier = ref.read(adminCoursesViewModelProvider.notifier);
    final ok = await runWithAppLoading(
      context,
      initial == null
          ? notifier.create(input)
          : notifier.update(initial.id, input),
      text: initial == null ? 'Creando curso…' : 'Guardando cambios…',
    );

    if (!mounted) return;
    if (ok != true) {
      final error = ref.read(adminCoursesViewModelProvider).error;
      await showAppError(
        context,
        title: initial == null
            ? 'No se pudo crear el curso'
            : 'No se pudieron guardar los cambios',
        message: error?.message ?? 'Intenta de nuevo en unos segundos.',
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminCoursesViewModelProvider);
    // Estado de la subida de imagen (AdminViewModel, no este form).
    final isUploading = ref.watch(
      adminViewModelProvider.select((s) => s.isUploadingImage),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Información básica ────────────────────────────────
          const _SectionHeader(
            'Información básica',
            icon: Icons.info_outline,
          ),

          // Título (obligatorio).
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Título *',
              hint: 'Ej: Diseño de puentes de concreto',
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'El título es obligatorio'
                : null,
          ),
          const SizedBox(height: 14),

          // Descripción.
          TextFormField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Descripción',
              hint: 'Qué aprenderá quien tome el curso…',
            ),
          ),
          const SizedBox(height: 14),

          // Categoría (real, desde GET /categories).
          DropdownButtonFormField<String>(
            key: ValueKey('category-${_categoryId ?? 'none'}'),
            initialValue: _categoryId,
            decoration: _inputDecoration(label: 'Categoría'),
            items: [
              for (final category in _categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: _loadingCategories
                ? null
                : (v) => setState(() => _categoryId = v),
          ),
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Cargando categorías…',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: 14),

          // ── Modalidad y duración ─────────────────────────────
          const _SectionHeader(
            'Modalidad y duración',
            icon: Icons.schedule_outlined,
          ),
          SegmentedButton<String>(
            segments: [
              for (final entry in kCourseModalityLabels.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {_modality},
            showSelectedIcon: false,
            style: ButtonStyle(
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFFE5E7EB)),
              ),
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
            onSelectionChanged: (selection) =>
                setState(() => _modality = selection.first),
          ),
          const SizedBox(height: 16),

          // Horas + precios.
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _hoursField(),
                _weeksField(),
                _priceField(),
                _compareAtPriceField(),
              ];

              if (constraints.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in fields) ...[
                    Expanded(child: field),
                    const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Imagen: URL manual o subida al bucket "courses".
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Imagen de portada',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isUploading ? null : _pickAndUploadImage,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: const Text('Subir imagen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _imageUrlController,
            keyboardType: TextInputType.url,
            decoration: _inputDecoration(
              label: 'Imagen (URL de portada)',
              hint: 'https://…/curso.jpg  —  o usa "Subir imagen"',
            ),
          ),
          if (_imageUrlController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _imageUrlController.text,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 130,
                  alignment: Alignment.center,
                  color: const Color(0xFFF1F5F9),
                  child: const Text(
                    'Vista previa no disponible',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('status-$_status'),
            initialValue: _status,
            decoration: _inputDecoration(label: 'Estado'),
            items: [
              for (final entry in kCourseStatusLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'active'),
          ),
          const SizedBox(height: 14),

          // ── Contenido de la landing ──────────────────────────
          const _SectionHeader(
            'Contenido de la landing',
            icon: Icons.web_outlined,
            hint: 'Estos textos se muestran en las pestañas de la '
                'página del curso.',
          ),
          TextFormField(
            controller: _professorController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Profesorado',
              hint: 'Perfil del especialista: experiencia y área…',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _teachingMethodController,
            minLines: 2,
            maxLines: 5,
            decoration: _inputDecoration(
              label: 'Método didáctico',
              hint: 'Ej: Clases grabadas\nCasos reales\nForo de consultas',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _targetAudienceController,
            minLines: 2,
            maxLines: 5,
            decoration: _inputDecoration(
              label: 'Dirigido a',
              hint: 'Una opción por línea:\nIngenieros civiles\nArquitectos',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _certificateController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Certificado',
              hint: 'Beneficios del certificado (QR, LinkedIn…)',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _careersController,
            minLines: 2,
            maxLines: 5,
            decoration: _inputDecoration(
              label: 'Salidas laborales',
              hint: 'Una opción por línea:\nProject Manager\nBIM Modeler',
            ),
          ),
          const SizedBox(height: 18),

          AdminDialogActions(
            confirmLabel: _isEditing ? 'Guardar cambios' : 'Crear curso',
            confirmIcon: _isEditing ? Icons.check : Icons.add,
            isSubmitting: adminState.isSubmitting,
            onConfirm: _submit,
          ),
        ],
      ),
    );
  }

  Widget _hoursField() => TextFormField(
    controller: _hoursController,
    keyboardType: TextInputType.number,
    decoration: _inputDecoration(label: 'Horas *', hint: '40'),
    validator: (value) {
      final hours = int.tryParse((value ?? '').trim());
      if (hours == null || hours < 0) return 'Número inválido';
      return null;
    },
  );

  Widget _weeksField() => TextFormField(
    controller: _weeksController,
    keyboardType: TextInputType.number,
    decoration: _inputDecoration(label: 'Semanas', hint: 'Opcional'),
    validator: (value) {
      final raw = (value ?? '').trim();
      if (raw.isEmpty) return null;
      final weeks = int.tryParse(raw);
      if (weeks == null || weeks < 0) return 'Número inválido';
      return null;
    },
  );

  Widget _priceField() => TextFormField(
    controller: _priceController,
    keyboardType: TextInputType.number,
    decoration: _inputDecoration(label: 'Precio general (USD) *', hint: '150'),
    validator: (value) {
      final price = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
      if (price == null || price < 0) return 'Número inválido';
      return null;
    },
  );

  /// Precio de oferta: la UI lo pinta junto al precio general TACHADO,
  /// así que solo tiene sentido si es MENOR que el precio general.
  Widget _compareAtPriceField() => TextFormField(
    controller: _compareAtPriceController,
    keyboardType: TextInputType.number,
    decoration: _inputDecoration(
      label: 'Precio de oferta (USD)',
      hint: 'Opcional',
    ),
    validator: (value) {
      final raw = (value ?? '').trim().replaceAll(',', '.');
      if (raw.isEmpty) return null; // sin oferta → sin descuento
      final offer = double.tryParse(raw);
      if (offer == null || offer < 0) return 'Número inválido';
      final price = double.tryParse(
        _priceController.text.trim().replaceAll(',', '.'),
      );
      if (price != null && offer >= price) {
        return 'Debe ser menor que el precio general';
      }
      return null;
    },
  );
}
