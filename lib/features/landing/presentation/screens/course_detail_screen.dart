import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_alerts.dart';
import '../../../auth/presentation/widgets/login_required_dialog.dart';
import '../../../aula/domain/entities/course_curriculum.dart';
import '../../../aula/presentation/viewmodels/curriculum_providers.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../domain/entities/training_course.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import '../widgets/course_display.dart';
import '../widgets/insight_navbar.dart';
import '../widgets/site_footer.dart';
import '../widgets/whatsapp_button.dart';

/// DETALLE DE CURSO: /capacitaciones/:id
///
/// Landing de venta con la plantilla e-commerce:
///  * Área multimedia superior (imagen estática del curso).
///  * 7 pestañas: Descripción, Contenido, Profesorado, Método didáctico,
///    Dirigido a, Certificado y Salidas laborales.
///  * Sidebar derecha de matriculación (tarifa + CTA).
///
/// Los datos llegan por la URL (id) y los carga GetCourseById.
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      appBar: const InsightNavbar(),
      drawer: const InsightDrawer(),
      backgroundColor: AppColors.background,
      floatingActionButton: const WhatsAppButton(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          courseAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _LoadError(
              courseId: courseId,
              message: error is Failure
                  ? error.message
                  : 'No se pudo cargar el curso.',
            ),
            data: (course) {
              if (course == null) return _NotFound(courseId: courseId);
              return _CourseDetailBody(course: course);
            },
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}

/// Cabecera de la plantilla: imagen a la izquierda y, a la derecha,
/// título + datos del curso + caja de tarifas con la compra.
class _CourseIntro extends StatelessWidget {
  const _CourseIntro({
    required this.course,
    required this.access,
    required this.onAddToCart,
    required this.onEnrollNow,
  });

  final TrainingCourse course;
  final String? access;
  final VoidCallback onAddToCart;
  final VoidCallback onEnrollNow;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    final image = _CourseImage(course: course);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 14),
        _InfoLine(
          icon: Icons.laptop_mac,
          label: 'Modalidad',
          value: course.modalityLabel,
        ),
        const SizedBox(height: 10),
        _InfoLine(
          icon: Icons.schedule,
          label: 'Duración',
          value: course.totalWeeks == null
              ? '${course.hours} horas'
              : '${course.hours} horas / ${course.totalWeeks} semanas',
        ),
        const SizedBox(height: 10),
        _InfoLine(
          icon: Icons.category_outlined,
          label: 'Categoría',
          value: course.category,
        ),
        const SizedBox(height: 20),
        _PriceBox(
          course: course,
          access: access,
          onAddToCart: onAddToCart,
          onEnrollNow: onEnrollNow,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [image, const SizedBox(height: 24), info],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: image),
        const SizedBox(width: 40),
        Expanded(flex: 5, child: info),
      ],
    );
  }
}

/// Imagen del curso (portada real o degradado placeholder) con badge
/// arriba a la derecha y caption abajo, como la plantilla.
class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasCaption = course.description.trim().isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo de respaldo si la imagen no carga.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: course.coverColors,
                ),
              ),
            ),
            if (hasImage)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            // Scrim inferior para que el caption se lea sobre la foto.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                ),
              ),
            ),
            // Chip de categoría (arriba a la derecha).
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.badge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Caption abajo a la izquierda.
            if (hasCaption)
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

/// Fila de datos de la cabecera: icono naranja + "Etiqueta: valor".
class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Caja de tarifas (fondo gris claro con la tarifa blanca dentro):
/// precio + CTA, o el estado de la inscripción si ya compró.
class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.course,
    required this.access,
    required this.onAddToCart,
    required this.onEnrollNow,
  });

  final TrainingCourse course;
  final String? access;
  final VoidCallback onAddToCart;
  final VoidCallback onEnrollNow;

  @override
  Widget build(BuildContext context) {
    final hasPrice = course.price > 0;
    final offer = course.offerPrice;
    // En oferta: se pinta el precio general TACHADO y, al lado, el
    // precio de oferta (lo que paga el cliente). Sin oferta: solo el
    // precio general.
    final onSale = hasPrice && offer != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tarifa General',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              children: [
                if (onSale) ...[
                  // Precio general tachado: lo que costaba sin oferta.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      formatDollars(course.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  // Precio de oferta: lo que realmente se paga.
                  Text(
                    formatDollars(offer),
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ] else
                  Text(
                    hasPrice ? formatDollars(course.price) : 'A consultar',
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pago único con acceso completo al curso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _EnrollmentCta(
              access: access,
              courseId: course.id,
              onAddToCart: onAddToCart,
              onEnrollNow: onEnrollNow,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuerpo de la landing: pestañas (izquierda) + sidebar de compra (derecha).
class _CourseDetailBody extends ConsumerStatefulWidget {
  const _CourseDetailBody({required this.course});

  final TrainingCourse course;

  @override
  ConsumerState<_CourseDetailBody> createState() => _CourseDetailBodyState();
}

class _CourseDetailBodyState extends ConsumerState<_CourseDetailBody>
    with SingleTickerProviderStateMixin {
  /// Pestaña activa: la maneja un [TabController] propio (el contenido
  /// vive dentro del ListView de la página, sin TabBarView).
  static const _tabs = [
    'DESCRIPCIÓN',
    'CONTENIDO',
    'PROFESORADO',
    'MÉTODO DIDÁCTICO',
    'DIRIGIDO A',
    'CERTIFICADO',
    'SALIDAS LABORALES',
  ];

  TrainingCourse get course => widget.course;

  late final TabController _tabController = TabController(
    length: _tabs.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    // Al cambiar de pestaña se repinta el contenido del ListView.
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Agrega al carrito exigiendo sesión (flujo de compra) y VALIDANDO
  /// que no haya comprado ya el curso (evita duplicar el pago).
  Future<bool> _addToCart(BuildContext context) async {
    final access = ref.read(curriculumProvider(course.id)).value?.access;
    if (access == 'full') {
      _showCourseAlreadyMessage(
        context,
        'Ya tienes este curso inscrito 🎓 Encuéntralo en "Mis cursos".',
      );
      return false;
    }
    if (access == 'pending') {
      _showCourseAlreadyMessage(
        context,
        'Ya solicitaste este curso: el pago está en verificación.',
      );
      return false;
    }

    final ok = await ensureAuthenticated(
      context,
      ref,
      action: 'agregar cursos al carrito',
    );
    if (!ok || !context.mounted) return false;

    await ref
        .read(cartViewModelProvider.notifier)
        .addItem(
          CartItem(
            courseId: course.id,
            title: course.title,
            // Se cobra el precio de OFERTA si existe; si no, el general.
            price: course.effectivePrice,
            modality: course.modalityLabel,
            imageUrl: course.imageUrl,
          ),
        );
    return true;
  }

  /// "Agregar al carrito": pide sesión, agrega y avisa.
  Future<void> _onAddToCart() async {
    final added = await _addToCart(context);
    if (!added || !mounted) return;
    await showAppAlert(
      context,
      type: AppAlertType.success,
      title: 'Carrito',
      message: 'Curso agregado al carrito 🛒',
    );
  }

  /// "Inscribirme ahora": pide sesión, agrega al carrito y pasa
  /// directo a la modalidad de pago.
  Future<void> _onEnrollNow() async {
    final added = await _addToCart(context);
    if (!added || !mounted) return;
    context.go('/checkout');
  }

  void _showCourseAlreadyMessage(BuildContext context, String message) {
    // ignore: unawaited_futures
    showAppAlert(
      context,
      type: AppAlertType.warning,
      title: 'Atención',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    // Mismo provider que la pestaña Contenido: da `access` para la
    // caja de tarifas y el temario para el accordion.
    final curriculum = ref.watch(curriculumProvider(course.id));
    final tabIndex = _tabController.index;

    final tabBar = _LandingTabBar(tabs: _tabs, controller: _tabController);

    final intro = _CourseIntro(
      course: course,
      access: curriculum.value?.access,
      onAddToCart: _onAddToCart,
      onEnrollNow: _onEnrollNow,
    );

    final content = _tabContent(curriculum, tabIndex);

    // Pestañas + contenido en una tarjeta blanca con borde (la pestaña
    // activa lleva píldora naranja claro, como la plantilla).
    final tabsCard = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tabBar,
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: content,
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 72,
        vertical: 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              intro,
              const SizedBox(height: 32),
              tabsCard,
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabContent(AsyncValue<CourseCurriculum?> data, int tabIndex) {
    return switch (tabIndex) {
      0 => _DescriptionTab(course: course),
      1 => _CurriculumTab(data: data),
      2 => _TextSection(
        icon: Icons.school_outlined,
        title: 'Profesorado',
        body: Text(
          course.professorBio ?? '',
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textMuted,
          ),
        ),
      ),
      3 => _BulletSection(
        icon: Icons.menu_book_outlined,
        title: 'Método didáctico',
        lines: course.teachingMethod,
        bulletIcon: Icons.check_circle_outline,
      ),
      4 => _BulletSection(
        icon: Icons.groups_outlined,
        title: 'Dirigido a',
        lines: course.targetAudience,
        bulletIcon: Icons.check_circle,
      ),
      5 => _TextSection(
        icon: Icons.verified_outlined,
        title: 'Certificado',
        body: Text(
          course.certificateInfo ?? '',
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textMuted,
          ),
        ),
      ),
      _ => _BulletSection(
        icon: Icons.work_outline,
        title: 'Salidas laborales',
        lines: course.careerOpportunities,
        bulletIcon: Icons.arrow_forward,
      ),
    };
  }
}

/// Barra de pestañas de la landing (naranja activo, scroll horizontal).
class _LandingTabBar extends StatelessWidget {
  const _LandingTabBar({required this.tabs, required this.controller});

  final List<String> tabs;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Material(
        color: Colors.white,
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textDark,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .4,
          ),
          // Píldora naranja claro + subrayado naranja (plantilla).
          indicator: BoxDecoration(
            color: const Color(0xFFFFEFE2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: const Border(
              bottom: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          dividerColor: const Color(0xFFE5E7EB),
          tabs: [for (final tab in tabs) Tab(text: tab)],
        ),
      ),
    );
  }
}

/// Pestaña 1: descripción + qué incluye.
class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.description.isEmpty
              ? 'Este curso aún no tiene descripción.'
              : course.description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '¿Qué incluye?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        for (final point in course.highlights) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  point,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Pestaña 2: temario en accordion (módulos y lecciones reales del
/// curso; el backend gatea el contenido con `contentUrl`).
class _CurriculumTab extends StatelessWidget {
  const _CurriculumTab({required this.data});

  final AsyncValue<CourseCurriculum?> data;

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _SectionPlaceholder(
        text: 'No se pudo cargar el temario.',
      ),
      data: (curriculum) {
        final modules = curriculum?.modules ?? const [];
        if (modules.isEmpty) {
          return const _SectionPlaceholder(text: 'Aún no hay temario publicado.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final module in modules)
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  childrenPadding: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    bottom: 12,
                  ),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.primary,
                  title: Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  children: [
                    for (final lesson in module.lessons)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              lesson.hasContent
                                  ? Icons.play_circle_outline
                                  : Icons.lock_outline,
                              size: 18,
                              color: lesson.hasContent
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (module.lessons.isEmpty)
                      const Text(
                        'Este módulo aún no tiene lecciones.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Sección de pestaña con título + párrafo (null o vacío → placeholder).
class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final text = (body as Text).data ?? '';
    if (text.trim().isEmpty) {
      return _SectionPlaceholder(text: '$title: aún sin contenido.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 14),
        body,
      ],
    );
  }
}

/// Sección de pestaña con título + lista de viñetas (una por línea).
class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.icon,
    required this.title,
    required this.lines,
    required this.bulletIcon,
  });

  final IconData icon;
  final String title;
  final String? lines;
  final IconData bulletIcon;

  List<String> get _lines =>
      (lines ?? '')
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

  @override
  Widget build(BuildContext context) {
    final items = _lines;
    if (items.isEmpty) {
      return _SectionPlaceholder(text: '$title: aún sin contenido.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 14),
        for (final line in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(bulletIcon, size: 17, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    );
  }
}

/// Llamada a la acción del curso, según el estado de la inscripción:
///  * `full`     → ya compró el curso: entra al aula, no se vende.
///  * `pending`  → su pago sigue en verificación manual.
///  * `rejected` → su pago fue rechazado.
///  * (sin dato) → el flujo normal de compra.
class _EnrollmentCta extends StatelessWidget {
  const _EnrollmentCta({
    required this.access,
    required this.courseId,
    required this.onAddToCart,
    required this.onEnrollNow,
  });

  final String? access;
  final String courseId;
  final VoidCallback onAddToCart;
  final VoidCallback onEnrollNow;

  @override
  Widget build(BuildContext context) {
    // Con acceso: ya TOMÓ el curso → advertencia clara, no se vende.
    if (access == 'full') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Color(0xFF059669),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ya tomaste este curso',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Estás inscrito con pago aprobado y acceso completo. '
              'Lo encuentras en "Mis cursos".',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: () => context.go('/capacitaciones/$courseId/aula'),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Entrar al curso'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
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

    if (access == 'pending' || access == 'rejected') {
      final pending = access == 'pending';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pending ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pending ? Icons.schedule : Icons.info_outline,
                  size: 20,
                  color: pending
                      ? const Color(0xFFD97706)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pending ? 'Pago en verificación' : 'Pago rechazado',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              pending
                  ? 'Ya solicitaste este curso. Cuando el pago sea revisado '
                      'y aprobado, aparecerá en "Mis cursos" con acceso.'
                  : 'El pago de este curso fue rechazado. Puedes solicitarlo '
                      'de nuevo desde el catálogo.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.go('/mis-cursos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Ir a Mis cursos'),
            ),
          ],
        ),
      );
    }

    // Sin inscripción (o sin sesión): flujo de compra completo,
    // botones apilados (ancho completo de la sidebar).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: onAddToCart,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Agregar al carrito'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: onEnrollNow,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Inscribirme ahora'),
          ),
        ),
      ],
    );
  }
}

/// Error de carga del curso (red o servidor) con reintento.
class _LoadError extends ConsumerWidget {
  const _LoadError({required this.courseId, required this.message});

  final String courseId;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(courseDetailProvider(courseId)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Curso no encontrado (id inválido en la URL).
class _NotFound extends StatelessWidget {
  const _NotFound({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No encontramos el curso "$courseId".',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Volver al catálogo'),
          ),
        ],
      ),
    );
  }
}
