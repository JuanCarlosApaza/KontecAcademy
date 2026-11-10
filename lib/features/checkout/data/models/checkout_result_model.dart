import 'package:equatable/equatable.dart';

import '../../domain/entities/checkout_result.dart';

/// DTO de la respuesta de `POST /checkout` (inscripción + pagos
/// registrados).
///
/// Único lugar del feature que conoce el JSON de esa respuesta.
class CheckoutResultModel extends Equatable {
  const CheckoutResultModel({
    required this.enrollmentIds,
    required this.paymentIds,
    required this.total,
  });

  final List<String> enrollmentIds;
  final List<String> paymentIds;

  /// Total cobrado (USD), calculado por el backend.
  final double total;

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) =>
      CheckoutResultModel(
        enrollmentIds: _ids(json['enrollments']),
        paymentIds: _ids(json['payments']),
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

  /// Filas `[{id: ...}, ...]` → lista de ids (las filas vacías se ignoran).
  static List<String> _ids(dynamic rows) {
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map && row['id'] is String) row['id'] as String,
    ];
  }

  /// Traduce a entidad de dominio (mapper).
  CheckoutResult toEntity() => CheckoutResult(
    enrollmentIds: enrollmentIds,
    paymentIds: paymentIds,
    total: total,
  );

  @override
  List<Object?> get props => [enrollmentIds, paymentIds, total];
}
