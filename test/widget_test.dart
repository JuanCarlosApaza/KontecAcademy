import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/app/app.dart';
import 'package:kontec/core/error/failures.dart';
import 'package:kontec/features/tasks/domain/entities/task.dart';
import 'package:kontec/features/tasks/domain/repositories/task_repository.dart';
import 'package:kontec/features/tasks/task_injector.dart';

/// Repositorio falso en memoria: permite probar la UI sin red.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this.seed);

  List<Task> seed;

  @override
  Future<(List<Task>, Failure?)> getTasks() async => (seed, null);

  @override
  Future<(Task, Failure?)> createTask(String title) async {
    final task = Task(id: 'local-${seed.length + 1}', title: title);
    seed = [...seed, task];
    return (task, null);
  }
}

void main() {
  testWidgets('muestra las tareas y permite añadir una', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(
            FakeTaskRepository(const [
              Task(id: '1', title: 'Aprender Clean Architecture'),
            ]),
          ),
        ],
        child: const KontecApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aprender Clean Architecture'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Crear capa de red');
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    expect(find.text('Crear capa de red'), findsOneWidget);
  });
}
