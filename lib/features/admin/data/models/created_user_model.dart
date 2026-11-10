import 'package:equatable/equatable.dart';

import '../../domain/entities/created_user.dart';

/// DTO del usuario recién creado (`POST /admin/users`).
class CreatedUserModel extends Equatable {
  const CreatedUserModel({required this.id, required this.email});

  final String id;
  final String email;

  factory CreatedUserModel.fromJson(Map<String, dynamic> json) =>
      CreatedUserModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  /// Traduce a entidad de dominio (mapper).
  CreatedUser toEntity() => CreatedUser(id: id, email: email);

  @override
  List<Object?> get props => [id, email];
}
