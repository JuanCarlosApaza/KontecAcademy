import 'package:flutter_test/flutter_test.dart';
import 'package:kontec/features/landing/data/models/learning_path_model.dart';

void main() {
  test('fromJson → entity conserva cursos, niveles y orden', () {
    final model = LearningPathModel.fromJson({
      'id': 'ruta-1',
      'slug': 'estructuras-y-diseno',
      'title': 'Estructuras y diseño',
      'description': 'Ruta de prueba',
      'coverUrl': null,
      'modality': 'live',
      'durationHours': 80,
      'accessMonths': 6,
      'discountPercent': 20,
      'totalCoursesPrice': 250,
      'price': 200,
      'sortOrder': 2,
      'isPublished': false,
      'courses': [
        {
          'courseId': 'c2',
          'title': 'Curso intermedio',
          'imageUrl': 'https://img/2.png',
          'price': 120.5,
          'hours': 50,
          'level': 'Intermedio',
          'sortOrder': 1,
        },
        {
          'courseId': 'c1',
          'title': 'Curso intro',
          'imageUrl': null,
          'price': 60,
          'hours': 30,
          'level': 'Introductorio',
          'sortOrder': 0,
        },
      ],
    });

    final path = model.toEntity();

    expect(path.slug, 'estructuras-y-diseno');
    expect(path.modality, 'live');
    expect(path.durationHours, 80);
    expect(path.accessMonths, 6);
    expect(path.isPublished, isFalse);
    // Precio de la ruta: total con la rebaja tal cual viene del API.
    expect(path.discountPercent, 20);
    expect(path.totalCoursesPrice, 250);
    expect(path.price, 200);
    // El mapper conserva el orden que trae la API (sortOrder).
    expect(path.courses, hasLength(2));
    expect(path.courses.first.courseId, 'c2');
    expect(path.courses.first.level, 'Intermedio');
    expect(path.courses.first.price, 120.5);
    expect(path.courses.last.hours, 30);
  });

  test('fromJson tolera campos ausentes (defaults defensivos)', () {
    final path = LearningPathModel.fromJson({'id': 'x', 'title': ''}).toEntity();

    expect(path.description, '');
    expect(path.modality, 'asynchronous');
    expect(path.accessMonths, 12);
    expect(path.isPublished, isTrue);
    expect(path.courses, isEmpty);
    expect(path.durationHours, 0);
    expect(path.discountPercent, 0);
    expect(path.price, 0);
  });
}
