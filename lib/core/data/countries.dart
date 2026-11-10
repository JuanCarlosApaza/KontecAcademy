/// País con prefijo telefónico, para el dropdown de registro.
class CountryCode {
  const CountryCode({
    required this.iso,
    required this.name,
    required this.dial,
    required this.flag,
  });

  /// Código ISO 3166-1 alfa-2 (para selects/BD).
  final String iso;

  final String name;

  /// Prefijo telefónico SIN '+' (ej: '591').
  final String dial;

  /// Emoji de bandera (los glyphs del font del navegador lo permiten).
  final String flag;

  @override
  String toString() => '$flag $name (+$dial)';
}

/// Países disponibles en el registro (LatAm completo + principales).
/// TODO(back): ampliar si se necesita el listado ISO completo.
const kCountries = <CountryCode>[
  CountryCode(iso: 'AR', name: 'Argentina', dial: '54', flag: '🇦🇷'),
  CountryCode(iso: 'AU', name: 'Australia', dial: '61', flag: '🇦🇺'),
  CountryCode(iso: 'BO', name: 'Bolivia', dial: '591', flag: '🇧🇴'),
  CountryCode(iso: 'BR', name: 'Brasil', dial: '55', flag: '🇧🇷'),
  CountryCode(iso: 'CA', name: 'Canadá', dial: '1', flag: '🇨🇦'),
  CountryCode(iso: 'CL', name: 'Chile', dial: '56', flag: '🇨🇱'),
  CountryCode(iso: 'CO', name: 'Colombia', dial: '57', flag: '🇨🇴'),
  CountryCode(iso: 'CR', name: 'Costa Rica', dial: '506', flag: '🇨🇷'),
  CountryCode(iso: 'CU', name: 'Cuba', dial: '53', flag: '🇨🇺'),
  CountryCode(iso: 'DO', name: 'República Dominicana', dial: '1809', flag: '🇩🇴'),
  CountryCode(iso: 'EC', name: 'Ecuador', dial: '593', flag: '🇪🇨'),
  CountryCode(iso: 'SV', name: 'El Salvador', dial: '503', flag: '🇸🇻'),
  CountryCode(iso: 'ES', name: 'España', dial: '34', flag: '🇪🇸'),
  CountryCode(iso: 'US', name: 'Estados Unidos', dial: '1', flag: '🇺🇸'),
  CountryCode(iso: 'FR', name: 'Francia', dial: '33', flag: '🇫🇷'),
  CountryCode(iso: 'GT', name: 'Guatemala', dial: '502', flag: '🇬🇹'),
  CountryCode(iso: 'HN', name: 'Honduras', dial: '504', flag: '🇭🇳'),
  CountryCode(iso: 'IN', name: 'India', dial: '91', flag: '🇮🇳'),
  CountryCode(iso: 'IT', name: 'Italia', dial: '39', flag: '🇮🇹'),
  CountryCode(iso: 'MX', name: 'México', dial: '52', flag: '🇲🇽'),
  CountryCode(iso: 'NI', name: 'Nicaragua', dial: '505', flag: '🇳🇮'),
  CountryCode(iso: 'PA', name: 'Panamá', dial: '507', flag: '🇵🇦'),
  CountryCode(iso: 'PY', name: 'Paraguay', dial: '595', flag: '🇵🇾'),
  CountryCode(iso: 'PE', name: 'Perú', dial: '51', flag: '🇵🇪'),
  CountryCode(iso: 'PT', name: 'Portugal', dial: '351', flag: '🇵🇹'),
  CountryCode(iso: 'PR', name: 'Puerto Rico', dial: '1787', flag: '🇵🇷'),
  CountryCode(iso: 'GB', name: 'Reino Unido', dial: '44', flag: '🇬🇧'),
  CountryCode(iso: 'UY', name: 'Uruguay', dial: '598', flag: '🇺🇾'),
  CountryCode(iso: 'VE', name: 'Venezuela', dial: '58', flag: '🇻🇪'),
];

/// Países ordenados alfabéticamente (para el dropdown).
final List<CountryCode> kCountriesSorted = List<CountryCode>.of(kCountries)
  ..sort((a, b) => a.name.compareTo(b.name));

/// Prefijos telefónicos únicos, ordenados por número (dropdown de código).
final List<String> kCountryDialCodes = {
  for (final country in kCountries) country.dial,
}.toList()
  ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

/// País por defecto del dropdown (mercado principal).
CountryCode defaultCountry() =>
    kCountries.firstWhere((country) => country.iso == 'BO');
