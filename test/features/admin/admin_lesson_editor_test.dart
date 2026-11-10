import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/features/admin/domain/entities/admin_curriculum.dart';
import 'package:kontec/features/admin/presentation/widgets/admin_lesson_editor.dart';

/// Bombea el editor de lecciones real dentro de un diálogo admin y
/// ejercita el conmutador Editor / Vista previa.
///
/// Cubre el riesgo de runtime de la nueva pestaña: que el
/// [QuillEditor] de solo lectura se construya sin excepción y que el
/// contenido escrito en el editor aparezca en la vista previa.
void main() {
  const module = AdminModule(
    id: 'mod-1',
    title: 'Módulo 1: Introducción',
    orderIndex: 1,
    lessons: [],
  );

  Future<void> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 960,
                child: AdminLessonEditor(module: module),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el editor arranca en modo Editor con la barra de Quill',
      (tester) async {
    await pumpEditor(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Nombre de la lección'), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Vista previa'), findsOneWidget);
    // La toolbar de Quill solo debe verse en modo edición.
    expect(find.byType(QuillSimpleToolbar), findsOneWidget);
  });

  testWidgets('al pasar a Vista previa se oculta la toolbar y se ve el aviso',
      (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // La toolbar desaparece en modo preview.
    expect(find.byType(QuillSimpleToolbar), findsNothing);
    // Cabecera del preview con el tipo de contenido.
    expect(find.text('Vista previa'), findsWidgets);
    // Lección vacía → empty state invitando a escribir.
    expect(
      find.textContaining('aún no tiene contenido'),
      findsOneWidget,
    );
  });

  testWidgets('el texto escrito en el editor aparece en la vista previa',
      (tester) async {
    await pumpEditor(tester);

    // Escribe contenido dentro del editor Quill (modo edición).
    await tester.enterText(find.byType(EditableText).first, 'Hola clase');
    await tester.pump();

    // Cambia a vista previa y verifica que el texto se replica.
    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hola clase'), findsWidgets);
  });

  testWidgets('volver a Editor restaura la toolbar', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();
    expect(find.byType(QuillSimpleToolbar), findsNothing);

    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(QuillSimpleToolbar), findsOneWidget);
  });
}
