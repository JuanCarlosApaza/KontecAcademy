import 'dart:convert';
import 'dart:io';

import 'package:api/todo_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/todos/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late TodoRepository repository;

  RequestContext buildContext(HttpMethod method, {String body = ''}) {
    final context = _MockRequestContext();
    when(() => context.request).thenReturn(
      Request(
        method.name.toUpperCase(),
        Uri.parse('http://localhost:3000/todos'),
        body: body,
      ),
    );
    when(() => context.read<TodoRepository>()).thenReturn(repository);
    return context;
  }

  setUp(() => repository = InMemoryTodoRepository());

  group('GET /todos', () {
    test('responde 200 con la lista de tareas', () async {
      repository.create('Estudiar Clean Architecture');

      final response = await route.onRequest(buildContext(HttpMethod.get));

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = jsonDecode(await response.body()) as List<dynamic>;
      expect(body, hasLength(1));
      expect(body.first, containsPair('title', 'Estudiar Clean Architecture'));
      expect(body.first, containsPair('completed', false));
    });
  });

  group('POST /todos', () {
    test('responde 201 y crea la tarea', () async {
      final response = await route.onRequest(
        buildContext(HttpMethod.post, body: '{"title": "Comprar café"}'),
      );

      expect(response.statusCode, equals(HttpStatus.created));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['id'], equals(1));
      expect(body['title'], equals('Comprar café'));
      expect(repository.findAll(), hasLength(1));
    });

    test('responde 400 si falta el título', () async {
      final response = await route.onRequest(
        buildContext(HttpMethod.post, body: '{"title": "  "}'),
      );

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(repository.findAll(), isEmpty);
    });

    test('responde 400 si el cuerpo no es JSON válido', () async {
      final response = await route.onRequest(
        buildContext(HttpMethod.post, body: 'esto no es json'),
      );

      expect(response.statusCode, equals(HttpStatus.badRequest));
    });
  });
}
