/// Configuración de Supabase (autenticación).
///
/// Valores por defecto para desarrollo. Para otros entornos (producción,
/// otro proyecto) se sobreescriben SIN tocar código:
///
/// ```powershell
/// flutter run -d chrome `
///   --dart-define=SUPABASE_URL=https://mi-proyecto.supabase.co `
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
/// ```
///
/// ⚠️ La clave que va aquí es la **publishable / anon public**
/// (Supabase → Project Settings → API Keys). NUNCA la service_role:
/// esa secreta vive solo en `server/.env`.
class SupabaseConfig {
  SupabaseConfig._();

  /// URL del proyecto Supabase.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xaratebbmgffxijfigio.supabase.co',
  );

  /// Clave pública del cliente (publishable / anon public).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-SPIlwqaYPZm8qiC1uv6Zg_f_a_hYuI',
  );

  /// true cuando la clave fue configurada (no es el placeholder).
  static bool get isConfigured => !anonKey.startsWith('PEGA_AQUI');
}
