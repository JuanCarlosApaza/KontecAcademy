import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/course_repository_impl.dart';
import 'data/repositories/learning_path_repository_impl.dart';
import 'data/repositories/membership_plan_repository_impl.dart';
import 'domain/usecases/get_all_courses.dart';
import 'domain/usecases/get_categories.dart';
import 'domain/usecases/get_course_by_id.dart';
import 'domain/usecases/get_featured_courses.dart';
import 'domain/usecases/get_learning_path_by_slug.dart';
import 'domain/usecases/get_learning_paths.dart';
import 'domain/usecases/get_membership_plans.dart';

/// Composition root del feature `landing`.
/// Aquí se ensamblan las capas; el dominio no importa data.
export 'data/repositories/course_repository_impl.dart'
    show courseRepositoryProvider;
export 'data/repositories/learning_path_repository_impl.dart'
    show learningPathRepositoryProvider;
export 'data/repositories/membership_plan_repository_impl.dart'
    show membershipPlanRepositoryProvider;

final getFeaturedCoursesProvider = Provider<GetFeaturedCourses>(
  (ref) => GetFeaturedCourses(ref.watch(courseRepositoryProvider)),
);

final getAllCoursesProvider = Provider<GetAllCourses>(
  (ref) => GetAllCourses(ref.watch(courseRepositoryProvider)),
);

final getCategoriesProvider = Provider<GetCategories>(
  (ref) => GetCategories(ref.watch(courseRepositoryProvider)),
);

final getCourseByIdProvider = Provider<GetCourseById>(
  (ref) => GetCourseById(ref.watch(courseRepositoryProvider)),
);

/// Rutas de entrenamiento (/rutas y /rutas/:slug).
final getLearningPathsProvider = Provider<GetLearningPaths>(
  (ref) => GetLearningPaths(ref.watch(learningPathRepositoryProvider)),
);

final getLearningPathBySlugProvider = Provider<GetLearningPathBySlug>(
  (ref) => GetLearningPathBySlug(ref.watch(learningPathRepositoryProvider)),
);

/// Planes de membresía (/membresias).
final getMembershipPlansProvider = Provider<GetMembershipPlans>(
  (ref) => GetMembershipPlans(ref.watch(membershipPlanRepositoryProvider)),
);
