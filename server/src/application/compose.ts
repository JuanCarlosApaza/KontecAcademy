import type { AdminRepository } from '../domain/admin.js';
import type { CartRepository } from '../domain/cart.js';
import type { CatalogRepository } from '../domain/catalog.js';
import type { CheckoutRepository } from '../domain/checkout.js';
import type { CurriculumRepository } from '../domain/curriculum.js';
import type { LearningPathRepository } from '../domain/learning-path.js';
import type { MembershipRepository } from '../domain/membership.js';
import type { RolesRepository } from '../domain/roles.js';
import type { TodoRepository } from '../domain/todo.js';
import { CreateAdminUser } from './usecases/create-admin-user.js';
import { CreateCategory } from './usecases/create-category.js';
import { CreateCheckout } from './usecases/create-checkout.js';
import { CreateCourse } from './usecases/create-course.js';
import { CreateLearningPath } from './usecases/create-learning-path.js';
import { CreateLesson } from './usecases/create-lesson.js';
import { CreateMembership } from './usecases/create-membership.js';
import { CreateMembershipPlan } from './usecases/create-membership-plan.js';
import { CreateModule } from './usecases/create-module.js';
import { CreateRole } from './usecases/create-role.js';
import { CreateTodo } from './usecases/create-todo.js';
import { DecidePayment } from './usecases/decide-payment.js';
import { DeleteLearningPath } from './usecases/delete-learning-path.js';
import { DeleteLesson } from './usecases/delete-lesson.js';
import { DeleteMembershipPlan } from './usecases/delete-membership-plan.js';
import { DeleteModule } from './usecases/delete-module.js';
import { DeleteRole } from './usecases/delete-role.js';
import { GetAdminCurriculum } from './usecases/get-admin-curriculum.js';
import { GetAdminStats } from './usecases/get-admin-stats.js';
import { GetCart } from './usecases/get-cart.js';
import { GetCourseById } from './usecases/get-course-by-id.js';
import { GetCurriculum } from './usecases/get-curriculum.js';
import { GetLearningPathBySlug } from './usecases/get-learning-path-by-slug.js';
import { GetMyCourses } from './usecases/get-my-courses.js';
import { GetMyMembership } from './usecases/get-my-membership.js';
import { GetMyProfile } from './usecases/get-my-profile.js';
import { GetStudentProfile } from './usecases/get-student-profile.js';
import { ListAbandonedCarts } from './usecases/list-abandoned-carts.js';
import { ListAdminUsers } from './usecases/list-admin-users.js';
import { ListCategories } from './usecases/list-categories.js';
import { ListCourseParticipants } from './usecases/list-course-participants.js';
import { ListCourses } from './usecases/list-courses.js';
import { ListLearningPaths } from './usecases/list-learning-paths.js';
import { ListMembershipPlans } from './usecases/list-membership-plans.js';
import { ListMemberships } from './usecases/list-memberships.js';
import { ListPayments } from './usecases/list-payments.js';
import { ListRolesMatrix } from './usecases/list-roles-matrix.js';
import { ListStudents } from './usecases/list-students.js';
import { ListTodos } from './usecases/list-todos.js';
import { SaveCart } from './usecases/save-cart.js';
import { SaveRolePermissions } from './usecases/save-role-permissions.js';
import { SetEnrollmentAccess } from './usecases/set-enrollment-access.js';
import { SetLearningPathCourses } from './usecases/set-learning-path-courses.js';
import { SetLessonProgress } from './usecases/set-lesson-progress.js';
import { UpdateAdminUser } from './usecases/update-admin-user.js';
import { UpdateCategory } from './usecases/update-category.js';
import { UpdateCourse } from './usecases/update-course.js';
import { UpdateLearningPath } from './usecases/update-learning-path.js';
import { UpdateLesson } from './usecases/update-lesson.js';
import { UpdateMembership } from './usecases/update-membership.js';
import { UpdateMembershipPlan } from './usecases/update-membership-plan.js';
import { UpdateModule } from './usecases/update-module.js';
import { UploadImage } from './usecases/upload-image.js';

/** Repositorios con los que se ensamblan los casos de uso. */
export interface UseCaseSources {
  todos: TodoRepository;
  catalog: CatalogRepository;
  checkout: CheckoutRepository;
  admin: AdminRepository;
  cart: CartRepository;
  curriculum: CurriculumRepository;
  roles: RolesRepository;
  paths: LearningPathRepository;
  memberships: MembershipRepository;
}

/**
 * Ensambra todos los casos de uso a partir de los repositorios
 * (una acción del sistema = una clase con execute()). Usado por el
 * composition root (`index.ts`) y por los tests.
 */
export function createUseCases(sources: UseCaseSources) {
  const {
    todos,
    catalog,
    checkout,
    admin,
    cart,
    curriculum,
    roles,
    paths,
    memberships,
  } = sources;

  return {
    listTodos: new ListTodos(todos),
    createTodo: new CreateTodo(todos),
    listCategories: new ListCategories(catalog),
    listCourses: new ListCourses(catalog),
    createCourse: new CreateCourse(catalog),
    updateCourse: new UpdateCourse(catalog),
    getCourseById: new GetCourseById(catalog),
    getCurriculum: new GetCurriculum(curriculum),
    setLessonProgress: new SetLessonProgress(curriculum),
    getMyCourses: new GetMyCourses(checkout, curriculum),
    getMyProfile: new GetMyProfile(checkout),
    getCart: new GetCart(cart),
    saveCart: new SaveCart(cart),
    getAdminStats: new GetAdminStats(admin),
    listStudents: new ListStudents(admin),
    listAbandonedCarts: new ListAbandonedCarts(admin),
    listPayments: new ListPayments(admin),
    decidePayment: new DecidePayment(admin),
    listAdminUsers: new ListAdminUsers(admin),
    // Participantes por curso + perfil del estudiante + acceso.
    listCourseParticipants: new ListCourseParticipants(admin, catalog),
    getStudentProfile: new GetStudentProfile(admin),
    setEnrollmentAccess: new SetEnrollmentAccess(checkout),
    createCategory: new CreateCategory(admin),
    updateCategory: new UpdateCategory(admin),
    createAdminUser: new CreateAdminUser(admin),
    updateAdminUser: new UpdateAdminUser(admin),
    uploadImage: new UploadImage(admin),
    // Temario (sección "Temario" del panel admin).
    getAdminCurriculum: new GetAdminCurriculum(admin),
    createModule: new CreateModule(admin),
    updateModule: new UpdateModule(admin),
    deleteModule: new DeleteModule(admin),
    createLesson: new CreateLesson(admin),
    updateLesson: new UpdateLesson(admin),
    deleteLesson: new DeleteLesson(admin),
    // Roles y permisos (matriz del panel /admin/roles).
    listRolesMatrix: new ListRolesMatrix(roles),
    saveRolePermissions: new SaveRolePermissions(roles),
    createRole: new CreateRole(roles),
    deleteRole: new DeleteRole(roles),
    // Rutas de entrenamiento (/rutas + CRUD del panel).
    listLearningPaths: new ListLearningPaths(paths),
    getLearningPathBySlug: new GetLearningPathBySlug(paths),
    createLearningPath: new CreateLearningPath(paths),
    updateLearningPath: new UpdateLearningPath(paths),
    deleteLearningPath: new DeleteLearningPath(paths),
    setLearningPathCourses: new SetLearningPathCourses(paths, catalog),
    // Membresías (3 planes + acceso total a los cursos).
    createCheckout: new CreateCheckout(checkout, memberships),
    listMembershipPlans: new ListMembershipPlans(memberships),
    getMyMembership: new GetMyMembership(memberships),
    listMemberships: new ListMemberships(memberships),
    createMembershipPlan: new CreateMembershipPlan(memberships),
    updateMembershipPlan: new UpdateMembershipPlan(memberships),
    deleteMembershipPlan: new DeleteMembershipPlan(memberships),
    createMembership: new CreateMembership(memberships),
    updateMembership: new UpdateMembership(memberships),
  };
}
