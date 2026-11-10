import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_user_record.dart';

/// DTO del usuario del panel (`GET/PATCH /admin/users`).
///
/// Único lugar del feature que conoce su JSON; la UI solo ve la
/// entidad [AdminUserRecord].
class AdminUserRecordModel extends Equatable {
  const AdminUserRecordModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.createdAt,
    this.roles = const [],
    this.isActive = true,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final DateTime? createdAt;

  /// Nombres de rol ('admin', 'teacher', 'student', ...).
  final List<String> roles;

  /// false = cuenta desactivada (borrado lógico).
  final bool isActive;

  factory AdminUserRecordModel.fromJson(Map<String, dynamic> json) =>
      AdminUserRecordModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        roles: List<String>.from(json['roles'] as List<dynamic>? ?? const []),
        isActive: json['isActive'] as bool? ?? true,
      );

  /// Traduce a entidad de dominio (mapper).
  AdminUserRecord toEntity() => AdminUserRecord(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    createdAt: createdAt,
    roles: roles,
    isActive: isActive,
  );

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phone,
    createdAt,
    roles,
    isActive,
  ];
}
