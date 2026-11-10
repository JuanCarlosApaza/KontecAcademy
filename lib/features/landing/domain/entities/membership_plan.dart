/// Plan de membresía (tipo: mensual /6 meses / anual…).
///
/// Los planes los gestiona el panel admin; el precio es lo que se paga
/// por acceder a TODOS los cursos durante [months] meses.
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.slug,
    required this.name,
    required this.months,
    required this.price,
    this.isActive = true,
    this.sortOrder = 0,
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String name;

  /// Duración en meses (1 | 6 | 12 …).
  final int months;
  final double price;
  final bool isActive;
  final int sortOrder;

  /// Imagen de la tarjeta (subida desde el panel admin); null si no tiene.
  final String? imageUrl;
}
