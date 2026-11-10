import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/rutas_viewmodel.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/ruta_card.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// RUTAS DE ENTRENAMIENTO: /rutas
///
/// Banda oscura de título + grid responsive de tarjetas de ruta.
/// Cada tarjeta navega al detalle: /rutas/:slug
/// Los datos reales llegan de la API (server Node + Supabase).
class RutasScreen extends ConsumerWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rutasViewModelProvider);

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _RutasHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _RutasGrid(state: state),
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
class _RutasHeader extends StatelessWidget {
  const _RutasHeader();

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
                text: 'Rutas de ',
                children: [
                  TextSpan(
                    text: 'Entrenamiento',
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
              'Programas estructurados que agrupan varios cursos con nivel '
              'y orden definidos. Encuentra tu especialización y avanza '
              'paso a paso hacia tu objetivo profesional.',
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

/// Grid responsive de rutas: 1 col (móvil) · 2 (≥640).
/// Con los4 estados siempre visibles: loading, error, vacío, datos.
class _RutasGrid extends ConsumerWidget {
  const _RutasGrid({required this.state});

  final RutasState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.paths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.paths.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            const Icon(
              Icons.signpost_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              state.error?.message ?? 'Aún no hay rutas publicadas.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: ref
                    .read(rutasViewModelProvider.notifier)
                    .loadPaths,
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
        final columns = width >= 640 ? 2 : 1;
        final cardWidth = (width - 16 * (columns - 1)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final path in state.paths)
              SizedBox(
                width: cardWidth,
                child: RutaCard(
                  path: path,
                  onTap: () => context.go('/rutas/${path.slug}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
