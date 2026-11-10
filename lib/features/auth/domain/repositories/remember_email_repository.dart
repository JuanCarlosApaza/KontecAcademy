/// Contrato de "Recuérdame": conserva el correo del último login en el
/// dispositivo para prellenarlo la próxima vez (nunca la contraseña).
abstract interface class RememberEmailRepository {
  Future<String?> getRememberedEmail();

  /// Guarda (o borra si [remember] es false) el correo recordado.
  Future<void> setRememberedEmail(String email, {required bool remember});
}
