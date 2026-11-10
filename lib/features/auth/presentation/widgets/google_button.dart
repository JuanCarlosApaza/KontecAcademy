import 'package:flutter/material.dart';

/// Botón "Continuar con Google" con su logo (G multicolor dibujado
/// con CustomPaint → sin assets ni imágenes externas).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF161616),
          side: const BorderSide(color: Color(0xFFD4D4D4)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 28, height: 28, child: _GoogleLogo()),
            const SizedBox(width: 12),
            const Text('Continuar con Google'),
          ],
        ),
      ),
    );
  }
}

/// Logo "G" de Google con los 4 colores de la marca.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final stroke = radius * 0.55;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Cuatro arcos de color (azul, verde, amarillo, rojo).
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    // Rojo: 135° a 225° (arriba-izquierda).
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      2.356,
      1.571,
      false,
      paint,
    );
    // Amarillo: 45° a 135° (arriba-derecha).
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      4.712,
      1.571,
      false,
      paint,
    );
    // Verde: 315° a 45° (abajo-derecha).
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      0,
      1.571,
      false,
      paint,
    );
    // Azul: 225° a 315° (abajo-izquierda).
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - stroke / 2),
      3.927,
      1.571,
      false,
      paint,
    );

    // Barra azul horizontal (la "G").
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke / 2, radius, stroke),
      Paint()..color = blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
