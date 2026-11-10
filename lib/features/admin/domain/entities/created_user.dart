import 'package:equatable/equatable.dart';

/// Usuario recién creado desde el panel admin (`POST /admin/users`).
class CreatedUser extends Equatable {
  const CreatedUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
