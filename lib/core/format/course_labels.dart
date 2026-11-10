/// Traducción de claves de modalidad de curso (BD) a etiquetas en
/// español. Única fuente compartida por landing, cart y admin.
library;

/// Modalidades de curso (clave de la BD → etiqueta corta).
const kCourseModalityLabels = <String, String>{
  'asynchronous': 'Asíncrono',
  'live': 'En vivo',
};

/// Etiqueta corta de la modalidad de un curso ('live' → 'En vivo').
///
/// Si el valor no es una clave conocida se devuelve tal cual (tolerante
/// a datos heredados).
String courseModalityLabel(String modality) =>
    kCourseModalityLabels[modality] ?? modality;
