import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/home_viewmodel.dart';
import '../widgets/course_card.dart';
import '../widgets/courses_carousel.dart';
import '../widgets/hero_section.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// HOME (landing page): diseño tipo insight-construction.com para
/// **Kontec Academy**.
///
/// Solo presentación + navegación con datos "quemados" del ViewModel.
/// Responsivo:
///  * >= 900px: el carrusel se SOLAPA sobre la parte baja del hero.
///  * < 900px: el hero ocupa su alto y el carrusel va debajo (sin solape).
/// TODO(back): al tener API real, solo cambia el datasource del feature.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // Alto reservado para el solape del carrusel sobre el hero.
    const overlap = 220.0;
    // Hueco entre el pie del carrusel y el resto del contenido.
    const trailingGap = 40.0;

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (isWide) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                // El hero + el espacio reservado determinan el alto del
                // Stack, y el carrusel queda "flotando" DENTRO de ese alto.
                //
                // ⚠️ Esto es OBLIGATORIO: Flutter no reparte los clics a
                // un hijo que cae fuera del `size` de su padre. Antes el
                // carrusel iba con `bottom: -overlap`, así que el Stack
                // medía solo lo del hero (620px) y el carrusel se salía
                // 220px: los botones "Más información" y los puntos
                // quedaban fuera del área de hit-testing y no respondían.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeroSection(),
                    const SizedBox(height: overlap + trailingGap),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  // El hueco inferior deja el pie del carrusel en
                  // hero + overlap: misma posición visual que antes.
                  bottom: trailingGap,
                  child: _buildCourses(context, state),
                ),
              ],
            ),
          ] else ...[
            const HeroSection(),
            const SizedBox(height: 24),
            _buildCourses(context, state),
            const SizedBox(height: 40),
          ],
          const SiteFooter(),
        ],
      ),
    );
  }

  Widget _buildCourses(BuildContext context, HomeState state) {
    // Alto real del carrusel: tarjeta fija + puntos indicadores.
    const carouselHeight = CourseCard.cardHeight + 34;

    if (state.isLoading && state.courses.isEmpty) {
      return const SizedBox(
        height: carouselHeight,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.courses.isEmpty) {
      return const SizedBox(
        height: carouselHeight,
        child: Center(child: Text('No hay cursos disponibles todavía.')),
      );
    }

    return CoursesCarousel(
      courses: state.courses,
      onCourseTap: (course) => context.go('/capacitaciones/${course.id}'),
    );
  }
}
