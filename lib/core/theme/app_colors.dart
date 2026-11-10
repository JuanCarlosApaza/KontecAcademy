import 'package:flutter/material.dart';

/// Paleta de marca: **blanco, naranja y negro**.
/// Centralizada para que toda la UI comparta los mismos colores.
class AppColors {
  AppColors._();

  /// Naranja principal de la marca.
  static const primary = Color(0xFFFF6B00);
  static const primaryDark = Color(0xFFE85D00);
  static const primaryLight = Color(0xFFFF8C33);

  /// Negros (hero, footer, texto).
  static const black = Color(0xFF0A0A0A);
  static const blackSoft = Color(0xFF161616);

  /// Textos sobre blanco.
  static const textDark = Color(0xFF161616);
  static const textMuted = Color(0xFF6B7280);

  /// Fondo general.
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);

  /// Botón flotante de WhatsApp.
  static const whatsapp = Color(0xFF25D366);
}
