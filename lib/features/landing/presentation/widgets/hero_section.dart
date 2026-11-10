import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Sección hero negra del home con titular, subtítulo y fondo "de obra".
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // El corte DEBE coincidir con el de home_screen.dart (>= 900 para
    // solapar el carrusel): si no, entre 800 y 900 el hero pinta la
    // versión desktop (620 + padding inferior de 240) con el carrusel
    // debajo → banda vacía de ~240 px.
    final isMobile = width < 900;

    return Container(
      width: double.infinity,
      // Altura MÍNIMA: el texto puede crecer (escala de fuente ≥ 1.3)
      // y entonces el hero crece en vez de recortar el contenido.
      constraints: BoxConstraints(minHeight: isMobile ? 440 : 620),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, Color(0xFF141414), Color(0xFF1F1A17)],
        ),
      ),
      // TODO(back): sustituir por la imagen real de fondo (assets o URL).
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const Positioned.fill(child: _BlueprintGrid()),
          // Acento naranja difuso (esquina superior derecha).
          const Positioned(top: -120, right: -80, child: _OrangeGlow()),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 24 : 72,
                32,
                isMobile ? 24 : 72,
                // En desktop las tarjetas se solapan sobre la parte
                // baja del hero: el texto nunca invade esa zona.
                isMobile ? 32 : 240,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text:
                          'Conviértete en un especialista BIM con '
                          'habilidades sobresalientes en el ',
                      children: [
                        TextSpan(
                          text: 'sector de la construcción',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: isMobile ? 26 : (width >= 1200 ? 42 : 34),
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aprende tecnologías y metodologías: Revit, Navisworks, '
                    'BIM, VDC y mucho, mucho más…',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo naranja semitransparente que aporta el acento de marca.
class _OrangeGlow extends StatelessWidget {
  const _OrangeGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      height: 420,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: .18),
      ),
    );
  }
}

/// Retícula sutil tipo "plano/blueprint" para dar textura al fondo.
class _BlueprintGrid extends StatelessWidget {
  const _BlueprintGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(color: Colors.white.withValues(alpha: .05)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    const step = 56.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}
