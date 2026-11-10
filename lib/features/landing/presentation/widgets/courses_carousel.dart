import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/training_course.dart';
import 'course_card.dart';

/// Carrusel CONTINUO de tarjetas todas del mismo tamaño.
///
/// A diferencia de un PageView (que estático → salta), este carrusel
/// **siempre está en movimiento**: las tarjetas se deslizan hacia la
/// izquierda de forma constante y el loop es infinito (el contenido se
/// duplica, así que no hay "corte" visible al dar la vuelta).
///
///  * 4 tarjetas por pantalla en desktop (máx.), 2 en tablet, 1 en móvil.
///  * Se pausa al pasar el cursor (y se queda pausado mientras esté
///    dentro, para poder hacer clic en "Más información") y a los 4 s
///    tras tocar o usar las flechas.
///  * Flechas y puntos saltan suavemente (ease) a la tarjeta deseada.
class CoursesCarousel extends StatefulWidget {
  const CoursesCarousel({
    super.key,
    required this.courses,
    this.onCourseTap,

    /// Tiempo que tarda en pasar de una tarjeta a la siguiente.
    this.stepInterval = const Duration(milliseconds: 1700),
  });

  final List<TrainingCourse> courses;
  final ValueChanged<TrainingCourse>? onCourseTap;
  final Duration stepInterval;

  @override
  State<CoursesCarousel> createState() => _CoursesCarouselState();
}

class _CoursesCarouselState extends State<CoursesCarousel>
    with SingleTickerProviderStateMixin {
  /// Offset actual (px) dentro de un ciclo completo [W].
  final ValueNotifier<double> _offset = ValueNotifier(0);

  /// Duración de un ciclo completo = 1 tarjeta * nº de tarjetas.
  late final Ticker _ticker;
  Duration _prev = Duration.zero;

  // Geometría (recalculada en cada build con LayoutBuilder).
  double _step = 1; // ancho de tarjeta + gap
  double _w = 1; // ancho total de una tira completa
  double _speed = 100; // px por segundo

  bool _paused = false;
  double? _jumpTo; // destino de una transición con ease (flechas/puntos)
  Timer? _resumeTimer;

  /// Tira de tarjetas cacheada: se reconstruye SOLO cuando cambia la
  /// geometría o los datos, nunca en cada fotograma del ticker.
  Widget? _strip;
  double? _stripCardWidth;
  int? _stripCount;
  List<TrainingCourse>? _stripCourses;

  @override
  void initState() {
    super.initState();
    _prev = Duration.zero;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _resumeTimer?.cancel();
    _offset.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    // dt con tope: si la pestaña estuvo en segundo plano, evita un salto.
    final dt = math.min((elapsed - _prev).inMicroseconds / 1e6, 0.05);
    _prev = elapsed;
    if (_w <= 0 || dt <= 0) return;

    var off = _offset.value;

    // Transición suave hacia un destino (flechas / puntos).
    if (_jumpTo != null) {
      final diff = _jumpTo! - off;
      if (diff.abs() < 1.5) {
        off = _jumpTo!;
        _jumpTo = null;
      } else {
        // Ease exponencial: rápido al inicio, suave al llegar.
        off += diff * (1 - math.pow(0.0015, dt));
      }
      _offset.value = off;
      return;
    }

    if (_paused) return;

    // Movimiento continuo y constante.
    off += _speed * dt;
    if (off >= _w) off -= _w;
    _offset.value = off;
  }

  /// Pausa mientras el usuario interactúa y reanuda a los 4 s.
  ///
  /// Se usa al tocar/flechar: la pausa es temporal para no "congelar"
  /// el carrusel si el usuario se distrae.
  void _pauseAndScheduleResume() {
    _paused = true;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 4), () {
      _paused = false;
    });
  }

  /// Pausa SIN reanudación automática: mientras el cursor siga dentro
  /// del carrusel la tarjeta no se mueve.
  ///
  /// Sin esto, al pasar el cursor se pausaba 4 s y el carrusel seguía
  /// aunque el usuario siguiera leyendo: la tarjeta se deslizaba bajo
  /// el cursor y el clic en "Más información" se perdía.
  void _pauseWhileHovered() {
    _resumeTimer?.cancel();
    _paused = true;
  }

  /// Reanuda el movimiento continuo al salir el cursor.
  void _resume() {
    _resumeTimer?.cancel();
    _paused = false;
  }

  /// Salta [cards] tarjetas hacia delante (positivo) o atrás (negativo),
  /// dando la vuelta al carrusel si hace falta.
  void _nudge(int cards) {
    _pauseAndScheduleResume();
    final target = _offset.value + cards * _step;
    // Elegimos la equivalencia más cercana dentro de [0, W).
    final delta = target - _offset.value;
    final wrapped =
        ((delta + _w / 2) % _w) - _w / 2; // resto euclidiano centrado
    _jumpTo = _offset.value + wrapped;
  }

  /// Salta directamente a la tarjeta [index] (puntos indicadores).
  void _goToCard(int index) {
    _pauseAndScheduleResume();
    final target = index * _step;
    final delta = target - _offset.value;
    final wrapped = ((delta + _w / 2) % _w) - _w / 2;
    _jumpTo = _offset.value + wrapped;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.courses.length;
    if (count == 0) return const SizedBox(height: CourseCard.cardHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isSmall = w < 800;

        final padding = isSmall ? 16.0 : 72.0;
        final gap = isSmall ? 14.0 : 24.0;
        final available = w - 2 * padding;

        // Nº de tarjetas por pantalla: 4 máx. en desktop, 2 en tablet,
        // 1 en móvil (mínimo 280 px por tarjeta para que se lea bien).
        var perView = ((available + gap) / (280 + gap)).floor();
        perView = perView.clamp(1, 4);

        final cardWidth = (available - gap * (perView - 1)) / perView;

        // Geometría del loop continuo.
        _step = cardWidth + gap;
        _w = _step * count;
        final intervalMs = math.max(widget.stepInterval.inMilliseconds, 200);
        _speed = _step * 1000 / intervalMs; // px/s

        // Reconstruimos la tira SOLO si cambia la geometría o los cursos.
        if (_strip == null ||
            _stripCardWidth != cardWidth ||
            _stripCount != count ||
            !identical(_stripCourses, widget.courses)) {
          _stripCardWidth = cardWidth;
          _stripCount = count;
          _stripCourses = widget.courses;
          _strip = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3 copias: la visible + entrantes + salientes.
              for (var copy = 0; copy < 3; copy++)
                for (var i = 0; i < count; i++) ...[
                  SizedBox(
                    width: cardWidth,
                    height: CourseCard.cardHeight,
                    child: CourseCard(
                      key: ValueKey('${widget.courses[i].id}-$copy'),
                      course: widget.courses[i],
                      // Sin botón de carrito en el home: el alta se
                      // hace desde el detalle del curso.
                      showCartButton: false,
                      onTap: () {
                        _pauseAndScheduleResume();
                        widget.onCourseTap?.call(widget.courses[i]);
                      },
                    ),
                  ),
                  SizedBox(width: gap),
                ],
            ],
          );
        }

        final carouselHeight = CourseCard.cardHeight + 34;

        return MouseRegion(
          onEnter: (_) => _pauseWhileHovered(),
          onExit: (_) => _resume(),
          child: Listener(
            onPointerDown: (_) => _pauseAndScheduleResume(),
            child: SizedBox(
              height: carouselHeight,
              child: Stack(
                children: [
                  // Tira de tarjetas (3 copias → loop sin cortes),
                  // recortada al área útil entre paddings.
                  Positioned(
                    top: 0,
                    left: padding,
                    right: padding,
                    height: CourseCard.cardHeight,
                    child: ClipRect(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _offset,
                        builder: (context, off, _) {
                          // OverflowBox: la tira (3 copias de 8 tarjetas) es
                          // mucho más ancha que el contenedor; le damos
                          // permiso para ocupar su ancho natural y el ClipRect
                          // se encarga de recortar lo que sobra (evita el
                          // overflow del RenderFlex).
                          return OverflowBox(
                            alignment: Alignment.topLeft,
                            minWidth: 0,
                            maxWidth: double.infinity,
                            minHeight: 0,
                            maxHeight: double.infinity,
                            // Solo cambia la traslación por fotograma;
                            // las tarjetas viven en la tira cacheada [_strip].
                            child: Transform.translate(
                              offset: Offset(-(off % _w), 0),
                              child: _strip,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Flechas (solo pantallas medianas+).
                  if (!isSmall) ...[
                    _ArrowButton(
                      icon: Icons.chevron_left,
                      left: padding / 3,
                      onTap: () => _nudge(-1),
                    ),
                    _ArrowButton(
                      icon: Icons.chevron_right,
                      right: padding / 3,
                      onTap: () => _nudge(1),
                    ),
                  ],
                  // Puntos indicadores (la tarjeta centrada se resalta).
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 4,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _offset,
                      builder: (context, off, _) {
                        final pos = off % _w;
                        final active =
                            (((pos / _step) + 0.5).floor() % count + count) %
                            count;
                        // Wrap (no Row): con muchos cursos los puntos
                        // desbordan el viewport en móvil.
                        return Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < count; i++)
                              GestureDetector(
                                onTap: () => _goToCard(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: i == active ? 24 : 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: i == active
                                        ? AppColors.primary
                                        : const Color(0xFFD4D4D4),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    this.left,
    this.right,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: CourseCard.cardHeight / 2 - 22,
      left: left,
      right: right,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
