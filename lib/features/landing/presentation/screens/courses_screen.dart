import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/courses_viewmodel.dart';
import '../widgets/course_card.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// CAPACITACIONES: catálogo completo de cursos.
///
/// Contenido: buscador + chips de categoría + grid responsive de tarjetas.
/// Cada tarjeta navega al detalle: /capacitaciones/:id
/// Los datos reales llegan de la API (server Node + Supabase).
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _CoursesHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchField(state: state),
                    const SizedBox(height: 16),
                    _CategoryChips(state: state),
                    const SizedBox(height: 24),
                    _CoursesGrid(state: state),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

/// Banda superior oscura con título de la sección.
class _CoursesHeader extends StatelessWidget {
  const _CoursesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF1F1A17)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 800 ? 24 : 72,
        vertical: 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'Capacitaciones ',
                children: [
                  TextSpan(
                    text: 'en BIM, MEP y Civil 3D',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 34,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cursos especializados con certificación Autodesk. '
              'Aprende a tu ritmo, con sesiones y programas estructurados.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: .85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Buscador por título o categoría.
class _SearchField extends ConsumerWidget {
  const _SearchField({required this.state});

  final CoursesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(coursesViewModelProvider.notifier);

    return TextField(
      onChanged: viewModel.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Buscar curso (ej: Civil 3D, Revit, MEP…)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: state.searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => viewModel.setSearchQuery(''),
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Chips de categoría ("Todas" + las de [CoursesState.categories],
/// que llegan de `GET /categories` en la API real).
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.state});

  final CoursesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(coursesViewModelProvider.notifier);
    final categories = ['Todas', ...state.categories];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final category in categories)
          ChoiceChip(
            label: Text(category),
            selected: state.selectedCategory == category,
            onSelected: (_) => viewModel.selectCategory(category),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: state.selectedCategory == category
                  ? Colors.white
                  : AppColors.textDark,
            ),
            side: BorderSide(
              color: state.selectedCategory == category
                  ? AppColors.primary
                  : const Color(0xFFD4D4D4),
            ),
            backgroundColor: Colors.white,
          ),
      ],
    );
  }
}

/// Grid responsive de cursos: 1 col (móvil) · 2 (tablet) · 3 (desktop).
class _CoursesGrid extends ConsumerWidget {
  const _CoursesGrid({required this.state});

  final CoursesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final courses = state.visibleCourses;

    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              state.error?.message ?? 'No encontramos cursos con esos filtros.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: ref
                    .read(coursesViewModelProvider.notifier)
                    .loadCourses,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);
        final cardWidth = (width - 16 * (columns - 1)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final course in courses)
              SizedBox(
                width: cardWidth,
                child: CourseCard(
                  course: course,
                  onTap: () => context.go('/capacitaciones/${course.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
