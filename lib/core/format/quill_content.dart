import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

/// CONTENIDO DE LECCIÓN — puente entre `content_text` (TEXT en la BD) y
/// el editor rico Quill.
///
/// El panel admin guarda el contenido como Delta JSON (`[{"insert":…}]`);
/// las lecciones creadas con el textarea anterior guardan texto plano.
/// Estas funciones permiten leer cualquiera de los dos formatos y
/// escribir siempre Delta JSON.

/// true si [text] es Delta JSON (Quill) y no texto plano heredado.
bool isQuillDelta(String text) {
  final trimmed = text.trimLeft();
  if (!trimmed.startsWith('[')) return false;
  try {
    final decoded = jsonDecode(trimmed);
    return decoded is List && decoded.isNotEmpty && decoded.first is Map;
  } catch (_) {
    return false;
  }
}

/// Convierte `content_text` de la BD a un Document de Quill.
///
/// El texto plano heredado se convierte a Delta línea a línea para que
/// se siga viendo igual en el aula y pueda seguir editándose. Si el
/// texto parece Delta JSON pero no lo es (o está roto), se pinta tal
/// cual como texto plano.
Document documentFromContentText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return Document();

  if (isQuillDelta(raw)) {
    try {
      return Document.fromJson(jsonDecode(raw.trim()) as List);
    } catch (_) {
      // Delta inválido: cae al texto plano de abajo.
    }
  }

  final lines = raw.split('\n');
  return Document.fromJson([
    for (final line in lines) {'insert': '$line\n'},
  ]);
}

/// Serializa el documento del editor para guardarlo en `content_text`.
///
/// Devuelve Delta JSON, o `''` si no hay contenido (para que en edición
/// el servidor reciba el campo y lo limpie; `null` omitiría la clave).
String contentTextFromDocument(Document document) {
  final plain = document.toPlainText().trim();
  if (plain.isEmpty) return '';
  return jsonEncode(document.toDelta().toJson());
}
