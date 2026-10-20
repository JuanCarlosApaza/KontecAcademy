import 'dart:convert';
import 'dart:io';

import 'package:api/todo_repository.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rutas de tareas:
///   GET  /todos -> lista de tareas
///   POST /todos -> crea una tarea  {"title": "..."}
Future<Response> onRequest(RequestContext context) async {
  final repository = context.read<TodoRepository>();
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return Response.json(
      body: repository.findAll().map((t) => t.toJson()).toList(),
    );
  }

  if (method == HttpMethod.post) {
    return _create(repository, context);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _create(
  TodoRepository repository,
  RequestContext context,
) async {
  final raw = await context.request.body();

  Map<String, dynamic> bodyJson;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    bodyJson = decoded;
  } catch (_) {
    return Response.json(
      body: {'error': 'Cuerpo JSON inválido'},
      statusCode: HttpStatus.badRequest,
    );
  }

  final title = (bodyJson['title'] as String?)?.trim() ?? '';
  if (title.isEmpty) {
    return Response.json(
      body: {'error': 'El campo "title" es obligatorio'},
      statusCode: HttpStatus.badRequest,
    );
  }

  final todo = repository.create(title);
  return Response.json(body: todo.toJson(), statusCode: HttpStatus.created);
}
