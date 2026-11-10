import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_record.dart';

/// DTO del pago del panel admin (`GET /admin/payments`). Único lugar
/// del feature que conoce su JSON; la UI solo ve [PaymentRecord].
class PaymentRecordModel extends Equatable {
  const PaymentRecordModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.pathId,
    this.pathTitle,
  });

  final String id;
  final String userId;
  final String email;
  final String fullName;
  final String courseId;
  final String courseTitle;
  final double amount;
  final String status;
  final String createdAt;
  final String? pathId;
  final String? pathTitle;

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) =>
      PaymentRecordModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        pathId: json['pathId'] as String?,
        pathTitle: json['pathTitle'] as String?,
      );

  /// Traduce a entidad de dominio (mapper).
  PaymentRecord toEntity() => PaymentRecord(
    id: id,
    userId: userId,
    email: email,
    fullName: fullName,
    courseId: courseId,
    courseTitle: courseTitle,
    amount: amount,
    status: status,
    createdAt: DateTime.tryParse(createdAt),
    pathId: pathId,
    pathTitle: pathTitle,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    email,
    fullName,
    courseId,
    courseTitle,
    amount,
    status,
    createdAt,
    pathId,
    pathTitle,
  ];
}
