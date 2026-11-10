import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/admin_repository_impl.dart';
import 'data/repositories/admin_session_repository_impl.dart';
import 'data/repositories/course_admin_repository_impl.dart';
import 'data/repositories/memberships_repository_impl.dart';
import 'data/repositories/paths_repository_impl.dart';
import 'data/repositories/roles_repository_impl.dart';
import 'domain/usecases/create_admin_user.dart';
import 'domain/usecases/create_category.dart';
import 'domain/usecases/create_course.dart';
import 'domain/usecases/create_path.dart';
import 'domain/usecases/create_plan.dart';
import 'domain/usecases/create_role.dart';
import 'domain/usecases/decide_payment.dart';
import 'domain/usecases/delete_lesson.dart';
import 'domain/usecases/delete_module.dart';
import 'domain/usecases/delete_path.dart';
import 'domain/usecases/delete_plan.dart';
import 'domain/usecases/delete_role.dart';
import 'domain/usecases/get_admin_curriculum.dart';
import 'domain/usecases/get_admin_stats.dart';
import 'domain/usecases/get_admin_users.dart';
import 'domain/usecases/get_roles_matrix.dart';
import 'domain/usecases/get_session_access.dart';
import 'domain/usecases/get_my_profile.dart';
import 'domain/usecases/get_student_profile.dart';
import 'domain/usecases/get_students.dart';
import 'domain/usecases/grant_membership.dart';
import 'domain/usecases/list_abandoned_carts.dart';
import 'domain/usecases/list_course_participants.dart';
import 'domain/usecases/list_memberships.dart';
import 'domain/usecases/list_paths.dart';
import 'domain/usecases/list_payments.dart';
import 'domain/usecases/list_plans.dart';
import 'domain/usecases/save_lesson.dart';
import 'domain/usecases/save_module.dart';
import 'domain/usecases/save_path_courses.dart';
import 'domain/usecases/save_role_permissions.dart';
import 'domain/usecases/set_enrollment_access.dart';
import 'domain/usecases/update_category.dart';
import 'domain/usecases/update_course.dart';
import 'domain/usecases/update_membership.dart';
import 'domain/usecases/update_path.dart';
import 'domain/usecases/update_plan.dart';
import 'domain/usecases/update_user.dart';
import 'domain/usecases/upload_course_image.dart';

/// Composition root del feature `admin`.
/// Aquí se ensamblan las capas; el dominio no importa data.
export 'data/repositories/admin_repository_impl.dart'
    show adminRepositoryProvider;
export 'data/repositories/admin_session_repository_impl.dart'
    show adminSessionRepositoryProvider;
export 'data/repositories/course_admin_repository_impl.dart'
    show courseAdminRepositoryProvider;
export 'data/repositories/memberships_repository_impl.dart'
    show membershipsRepositoryProvider;
export 'data/repositories/paths_repository_impl.dart'
    show pathsRepositoryProvider;
export 'data/repositories/roles_repository_impl.dart'
    show rolesRepositoryProvider;
export 'domain/usecases/create_admin_user.dart' show CreateAdminUserParams;
export 'domain/usecases/create_category.dart' show CreateCategoryParams;
export 'domain/usecases/create_path.dart' show CreatePath;
export 'domain/usecases/create_role.dart' show CreateRoleParams;
export 'domain/usecases/decide_payment.dart' show DecidePaymentParams;
export 'domain/repositories/paths_repository.dart'
    show AdminPathInput, PathCourseAssignment;
export 'domain/repositories/memberships_repository.dart'
    show AdminGrantInput, AdminPlanInput, MembershipRecord;
export 'domain/usecases/save_path_courses.dart' show SavePathCoursesParams;
export 'domain/usecases/update_path.dart' show UpdatePathParams;
export 'domain/usecases/update_plan.dart' show UpdatePlanParams;
export 'domain/usecases/update_membership.dart' show UpdateMembershipParams;
export 'domain/usecases/list_payments.dart' show ListPaymentsParams;
export 'domain/usecases/save_lesson.dart' show SaveLessonParams;
export 'domain/usecases/save_role_permissions.dart'
    show SaveRolePermissionsParams;
export 'domain/usecases/set_enrollment_access.dart'
    show SetEnrollmentAccessParams;
export 'domain/usecases/update_category.dart' show UpdateCategoryParams;
export 'domain/usecases/update_course.dart' show UpdateCourseParams;
export 'domain/usecases/update_user.dart' show UpdateUserParams;
export 'domain/usecases/upload_course_image.dart' show UploadCourseImageParams;

final createCourseProvider = Provider<CreateCourse>(
  (ref) => CreateCourse(ref.watch(courseAdminRepositoryProvider)),
);

// ── RUTAS DE ENTRENAMIENTO (/admin/rutas) ──────────────────────

final listPathsProvider = Provider<ListPaths>(
  (ref) => ListPaths(ref.watch(pathsRepositoryProvider)),
);

final createPathProvider = Provider<CreatePath>(
  (ref) => CreatePath(ref.watch(pathsRepositoryProvider)),
);

final updatePathProvider = Provider<UpdatePath>(
  (ref) => UpdatePath(ref.watch(pathsRepositoryProvider)),
);

final savePathCoursesProvider = Provider<SavePathCourses>(
  (ref) => SavePathCourses(ref.watch(pathsRepositoryProvider)),
);

final deletePathProvider = Provider<DeletePath>(
  (ref) => DeletePath(ref.watch(pathsRepositoryProvider)),
);

// ── MEMBRESÍAS (3 planes + acceso total) ────────────────────────

final listPlansProvider = Provider<ListPlans>(
  (ref) => ListPlans(ref.watch(membershipsRepositoryProvider)),
);

final createPlanProvider = Provider<CreatePlan>(
  (ref) => CreatePlan(ref.watch(membershipsRepositoryProvider)),
);

final updatePlanProvider = Provider<UpdatePlan>(
  (ref) => UpdatePlan(ref.watch(membershipsRepositoryProvider)),
);

final deletePlanProvider = Provider<DeletePlan>(
  (ref) => DeletePlan(ref.watch(membershipsRepositoryProvider)),
);

final listMembershipsProvider = Provider<ListMemberships>(
  (ref) => ListMemberships(ref.watch(membershipsRepositoryProvider)),
);

final grantMembershipProvider = Provider<GrantMembership>(
  (ref) => GrantMembership(ref.watch(membershipsRepositoryProvider)),
);

final updateMembershipProvider = Provider<UpdateMembership>(
  (ref) => UpdateMembership(ref.watch(membershipsRepositoryProvider)),
);

// ── TEMARIO (módulos + lecciones) ──────────────────────────────

final getAdminCurriculumProvider = Provider<GetAdminCurriculum>(
  (ref) => GetAdminCurriculum(ref.watch(courseAdminRepositoryProvider)),
);

final saveModuleProvider = Provider<SaveModule>(
  (ref) => SaveModule(ref.watch(courseAdminRepositoryProvider)),
);

final deleteModuleProvider = Provider<DeleteModule>(
  (ref) => DeleteModule(ref.watch(courseAdminRepositoryProvider)),
);

final saveLessonProvider = Provider<SaveLesson>(
  (ref) => SaveLesson(ref.watch(courseAdminRepositoryProvider)),
);

final deleteLessonProvider = Provider<DeleteLesson>(
  (ref) => DeleteLesson(ref.watch(courseAdminRepositoryProvider)),
);

final updateCourseProvider = Provider<UpdateCourse>(
  (ref) => UpdateCourse(ref.watch(courseAdminRepositoryProvider)),
);

final updateCategoryProvider = Provider<UpdateCategory>(
  (ref) => UpdateCategory(ref.watch(adminRepositoryProvider)),
);

final updateUserProvider = Provider<UpdateUser>(
  (ref) => UpdateUser(ref.watch(adminRepositoryProvider)),
);

final getAdminStatsProvider = Provider<GetAdminStats>(
  (ref) => GetAdminStats(ref.watch(adminRepositoryProvider)),
);

final getStudentsProvider = Provider<GetStudents>(
  (ref) => GetStudents(ref.watch(adminRepositoryProvider)),
);

final createCategoryProvider = Provider<CreateCategory>(
  (ref) => CreateCategory(ref.watch(adminRepositoryProvider)),
);

final createAdminUserProvider = Provider<CreateAdminUser>(
  (ref) => CreateAdminUser(ref.watch(adminRepositoryProvider)),
);

final getAdminUsersProvider = Provider<GetAdminUsers>(
  (ref) => GetAdminUsers(ref.watch(adminRepositoryProvider)),
);

final getRolesMatrixProvider = Provider<GetRolesMatrix>(
  (ref) => GetRolesMatrix(ref.watch(rolesRepositoryProvider)),
);

final saveRolePermissionsProvider = Provider<SaveRolePermissions>(
  (ref) => SaveRolePermissions(ref.watch(rolesRepositoryProvider)),
);

final createRoleProvider = Provider<CreateRole>(
  (ref) => CreateRole(ref.watch(rolesRepositoryProvider)),
);

final deleteRoleProvider = Provider<DeleteRole>(
  (ref) => DeleteRole(ref.watch(rolesRepositoryProvider)),
);

final getSessionAccessProvider = Provider<GetSessionAccess>(
  (ref) => GetSessionAccess(ref.watch(adminSessionRepositoryProvider)),
);

final uploadCourseImageProvider = Provider<UploadCourseImage>(
  (ref) => UploadCourseImage(ref.watch(adminRepositoryProvider)),
);

final listAbandonedCartsProvider = Provider<ListAbandonedCarts>(
  (ref) => ListAbandonedCarts(ref.watch(adminRepositoryProvider)),
);

final listPaymentsProvider = Provider<ListPayments>(
  (ref) => ListPayments(ref.watch(adminRepositoryProvider)),
);

final decidePaymentProvider = Provider<DecidePayment>(
  (ref) => DecidePayment(ref.watch(adminRepositoryProvider)),
);

// ── PARTICIPANTES + PERFIL DEL ESTUDIANTE ──────────────────────

final listCourseParticipantsProvider = Provider<ListCourseParticipants>(
  (ref) => ListCourseParticipants(ref.watch(adminRepositoryProvider)),
);

final getStudentProfileProvider = Provider<GetStudentProfile>(
  (ref) => GetStudentProfile(ref.watch(adminRepositoryProvider)),
);

final getMyProfileProvider = Provider<GetMyProfile>(
  (ref) => GetMyProfile(ref.watch(adminRepositoryProvider)),
);

final setEnrollmentAccessProvider = Provider<SetEnrollmentAccess>(
  (ref) => SetEnrollmentAccess(ref.watch(adminRepositoryProvider)),
);
