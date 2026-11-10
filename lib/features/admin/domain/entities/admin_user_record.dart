import 'package:equatable/equatable.dart';

/// Usuario del panel (cualquier rol: admin, teacher, student, sin rol).
class AdminUserRecord extends Equatable {
  const AdminUserRecord({
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

  /// false = cuenta desactivada (borrado lógico; los datos se conservan).
  final bool isActive;

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
