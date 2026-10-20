import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/task_repository_impl.dart';
import 'domain/usecases/create_task.dart';
import 'domain/usecases/get_tasks.dart';

/// Composition root del feature: aquí se "ensambla" la dependencia de cada
/// capa. El `domain` puro NO importa a `data`; el ensamble ocurre aquí.
///
/// Si mañana cambias REST por una base de datos local, solo se edita este
/// archivo (y la capa `data`), sin tocar el dominio ni la presentación.
export 'data/repositories/task_repository_impl.dart' show taskRepositoryProvider;

final getTasksProvider = Provider<GetTasks>(
  (ref) => GetTasks(ref.watch(taskRepositoryProvider)),
);

final createTaskProvider = Provider<CreateTask>(
  (ref) => CreateTask(ref.watch(taskRepositoryProvider)),
);
