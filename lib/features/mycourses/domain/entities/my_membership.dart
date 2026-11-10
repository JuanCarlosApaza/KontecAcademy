/// Membresía ACTIVA del usuario (banner en "Mis cursos").
class MyMembership {
  const MyMembership({
    required this.planName,
    required this.months,
    required this.startDate,
    required this.endDate,
  });

  final String planName;
  final int months;

  /// ISO8601 (UTC).
  final String startDate;
  final String endDate;

  /// dd/MM/yyyy de [endDate] para el banner.
  String get endDateLabel {
    final date = DateTime.tryParse(endDate)?.toLocal();
    if (date == null) return endDate;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
