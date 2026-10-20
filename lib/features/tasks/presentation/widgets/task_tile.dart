import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// Widget de fila: puro, recibe datos y notifica eventos (sin estado propio
/// de negocio ni llamadas a red).
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.onToggle});

  final Task task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: task.isDone,
        onChanged: (_) => onToggle(),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
