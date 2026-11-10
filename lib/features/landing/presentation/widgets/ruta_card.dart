import 'package:flutter/material.dart';

import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/learning_path.dart';

/// Etiqueta de modalidad de una ruta (mismos códigos que los cursos).
String pathModalityLabel(String modality) =>
    modality == 'live' ? 'En vivo' : 'Asíncrono';

/// Tarjeta de una ruta de entrenamiento (grid de /rutas).
///
/// Estructura: portada (imagen o gradiente de marca) → título →
/// descripción → chips de stats → preview de hasta3 cursos con nivel →
/// CTA "Ver ruta".
class RutaCard extends StatelessWidget {
  const RutaCard({super.key, required this.path, required this.onTap});

  final LearningPath path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = path.courses.take(3).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cover(coverUrl: path.coverUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (path.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      path.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatChip(
                        icon: Icons.menu_book_outlined,
                        label: path.courses.length == 1
                            ? '1 curso'
                            : '${path.courses.length} cursos',
                      ),
                      _StatChip(
                        icon: Icons.schedule,
                        label: '${path.durationHours} h',
                      ),
                      _StatChip(
                        icon: path.modality == 'live'
                            ? Icons.video_camera_front_outlined
                            : Icons.play_circle_outline,
                        label: pathModalityLabel(path.modality),
                      ),
                      _StatChip(
                        icon: Icons.calendar_month_outlined,
                        label: 'Acceso ${path.accessMonths} meses',
                      ),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Cursos de la ruta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final course in preview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _CourseLine(course: course),
                      ),
                    if (path.courses.length > preview.length)
                      Text(
                        '+ ${path.courses.length - preview.length} curso(s) más',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                  if (path.price > 0) ...[
                    const SizedBox(height: 10),
                    _PriceRow(path: path),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Ver ruta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Portada: imagen de la ruta o gradiente de marca como fallback.
class _Cover extends StatelessWidget {
  const _Cover({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      return Image.network(
        coverUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _FallbackCover(),
      );
    }
    return const _FallbackCover();
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF1F1A17)],
        ),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signpost_outlined, size: 34, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Ruta de entrenamiento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Precio de la ruta: chip de rebaja + total tachado + precio final.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = path.discountPercent > 0;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Ruta completa',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        if (hasDiscount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '-${path.discountPercent}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
        if (hasDiscount)
          Text(
            formatDollars(path.totalCoursesPrice),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          formatDollars(path.price),
          style: const TextStyle(
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

/// Chip pequeño de estadística (ícono + texto).
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea del preview: miniatura + título + nivel a la derecha.
class _CourseLine extends StatelessWidget {
  const _CourseLine({required this.course});

  final PathCourse course;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 36,
            height: 36,
            child: course.imageUrl != null
                ? Image.network(
                    course.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _MiniPlaceholder(),
                  )
                : const _MiniPlaceholder(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (course.level != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              course.level!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  const _MiniPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDEDED),
      child: const Icon(Icons.school_outlined, size: 18, color: Colors.white),
    );
  }
}
