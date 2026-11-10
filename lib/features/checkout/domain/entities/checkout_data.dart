import 'package:equatable/equatable.dart';

/// Datos personales que el usuario entrega al pasar al pago.
///
/// Con ellos el backend actualiza `public.users` y crea las
/// inscripciones (`enrollments`) + pagos (`payments`) pendientes de
/// aprobación.
class CheckoutData extends Equatable {
  const CheckoutData({
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.documentNumber,
  });

  final String fullName;
  final String email;

  /// Teléfono de contacto.
  final String? phone;

  /// Nacionalidad (ej: "Peruana").
  final String? nationality;

  /// DNI / pasaporte / carnet de identidad.
  final String? documentNumber;

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    nationality,
    documentNumber,
  ];
}
