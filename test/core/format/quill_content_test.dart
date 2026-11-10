import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/core/format/quill_content.dart';

void main() {
  group('isQuillDelta', () {
    test('detecta Delta JSON', () {
      expect(isQuillDelta('[{"insert":"Hola\\n"}]'), isTrue);
      expect(isQuillDelta('  [{"insert":"x\\n"}]'), isTrue);
    });

    test('texto plano no es Delta', () {
      expect(isQuillDelta('¡Bienvenido al curso!'), isFalse);
      expect(isQuillDelta(''), isFalse);
      expect(isQuillDelta('[esto no es json'), isFalse);
      expect(isQuillDelta('[1, 2, 3]'), isFalse);
    });
  });

  group('documentFromContentText', () {
    test('null o vacío → documento vacío', () {
      expect(documentFromContentText(null).toPlainText().trim(), isEmpty);
      expect(documentFromContentText('   ').toPlainText().trim(), isEmpty);
    });

    test('texto plano heredado se convierte a Delta conservando saltos', () {
      final doc = documentFromContentText('línea uno\nlínea dos');
      expect(doc.toPlainText(), 'línea uno\nlínea dos\n');
      expect(isQuillDelta(contentTextFromDocument(doc)), isTrue);
    });

    test('Delta JSON se carga como estaba', () {
      const delta = '[{"insert":"Con "},'
          '{"insert":"formato","attributes":{"bold":true}},'
          '{"insert":"\\n"}]';
      final doc = documentFromContentText(delta);
      expect(doc.toPlainText(), 'Con formato\n');
      final boldOp = doc
          .toDelta()
          .toJson()
          .firstWhere((op) => '${op['insert']}'.contains('formato'));
      expect(boldOp['attributes']['bold'], isTrue);
    });

    test('Delta inválido cae a texto plano en vez de lanzar', () {
      final doc = documentFromContentText('[{"borroso": true}]');
      expect(doc.toPlainText(), isNotEmpty);
    });
  });

  group('contentTextFromDocument', () {
    test('documento con texto → Delta JSON', () {
      final doc = Document()..insert(0, 'Hola');
      final saved = contentTextFromDocument(doc);
      expect(isQuillDelta(saved), isTrue);
      expect(documentFromContentText(saved).toPlainText(), 'Hola\n');
    });

    test('documento vacío → cadena vacía (limpia el campo en edición)', () {
      expect(contentTextFromDocument(Document()), isEmpty);
    });
  });
}
