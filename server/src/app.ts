import cors from 'cors';
import express, {
  type NextFunction,
  type Request,
  type Response,
} from 'express';
import multer from 'multer';

import type { createUseCases } from './application/compose.js';
import { parseSaveCartDTO } from './application/dtos/cart_dto.js';
import { parseCreateCategoryDTO, parseUpdateCategoryDTO } from './application/dtos/category_dto.js';
import { parseCreateCheckoutDTO } from './application/dtos/checkout_dto.js';
import { parseCourseDTO, parseListCoursesDTO } from './application/dtos/course_dto.js';
import { parseEnrollmentAccessDTO } from './application/dtos/enrollment_access_dto.js';
import { parseUploadImageDTO } from './application/dtos/image_dto.js';
import { parseCreateLessonDTO, parseUpdateLessonDTO } from './application/dtos/lesson_dto.js';
import {
  parseCreatePathDTO,
  parseSetPathCoursesDTO,
  parseUpdatePathDTO,
} from './application/dtos/learning_path_dto.js';
import {
  parseCreateMembershipDTO,
  parseCreatePlanDTO,
  parseUpdateMembershipDTO,
  parseUpdatePlanDTO,
} from './application/dtos/membership_dto.js';
import { parseLessonProgressDTO } from './application/dtos/lesson_progress_dto.js';
import { parseCreateModuleDTO, parseUpdateModuleDTO } from './application/dtos/module_dto.js';
import { parseListPaymentsDTO } from './application/dtos/payment_dto.js';
import { parsePaymentDecisionDTO } from './application/dtos/payment_action_dto.js';
import { parseCreateRoleDTO, parseSaveRolePermissionsDTO } from './application/dtos/role_dto.js';
import { parseCreateTodoDTO } from './application/dtos/todo_dto.js';
import { parseCreateAdminUserDTO, parseUpdateAdminUserDTO } from './application/dtos/user_dto.js';
import { AccessDeniedError, ValidationError } from './application/errors.js';
import type { AuthenticatedUser, CheckoutRepository } from './domain/checkout.js';

/** Casos de uso que la API necesita (inyección desde index.ts). */
export type AppUseCases = ReturnType<typeof createUseCases>;

export interface AppDependencies extends AppUseCases {
  /** Solo para los middlewares de sesión: verificar JWT, roles y permisos. */
  auth: Pick<CheckoutRepository, 'verifyToken' | 'getRoles' | 'getPermissions'>;
}

/**
 * Lee y verifica el JWT de Supabase (Authorization: Bearer ...).
 * Si es inválido responde 401 y devuelve null.
 */
async function requireAuth(
  req: Request,
  res: Response,
  auth: AppDependencies['auth'],
): Promise<AuthenticatedUser | null> {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';

  if (token.length === 0) {
    res.status(401).json({
      error: 'Falta el token de sesión (Authorization: Bearer <token>).',
    });
    return null;
  }

  const user = await auth.verifyToken(token);
  if (!user) {
    res.status(401).json({
      error: 'Sesión inválida o expirada. Inicia sesión de nuevo.',
    });
    return null;
  }
  return user;
}

/**
 * Igual que requireAuth + exige un permiso del catálogo
 * (`modulo:accion`, p. ej. 'payments:approve').
 *
 * Reemplaza al antiguo `requireAdmin`: el panel deja de ser binario y
 * cada ruta pide SU permiso, que el admin tiene siempre (bypass
 * calculado en `getPermissions`) y los demás según su matriz.
 */
async function requirePermission(
  req: Request,
  res: Response,
  auth: AppDependencies['auth'],
  code: string,
): Promise<AuthenticatedUser | null> {
  const user = await requireAuth(req, res, auth);
  if (!user) return null;

  const permissions = await auth.getPermissions(user.id);
  if (!permissions.includes(code)) {
    res.status(403).json({ error: `Permiso requerido: ${code}.` });
    return null;
  }
  return user;
}

/**
 * JWT opcional: sin Authorization o con token inválido → null (nunca
 * responde 401). Sirve a rutas PÚBLICAS que personalizan la respuesta
 * si hay sesión (ej. el temario del aula, que con pago aprobado
 * incluye el contenido del curso).
 */
async function optionalAuth(
  req: Request,
  auth: AppDependencies['auth'],
): Promise<AuthenticatedUser | null> {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';

  if (token.length === 0) return null;

  try {
    return await auth.verifyToken(token);
  } catch {
    return null;
  }
}

/**
 * Orígenes permitidos por CORS.
 *
 * Sin variable → abierto (desarrollo local: front en :8080, Edge aislado…).
 * En producción define `CORS_ORIGIN` en `.env` con el dominio del front
 * separado por comas (sin tocar código):
 *   CORS_ORIGIN=https://tudominio.com,https://www.tudominio.com
 */
function resolveCorsOptions(): cors.CorsOptions {
  const origins = (process.env.CORS_ORIGIN ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);

  return origins.length > 0 ? { origin: origins } : {};
}

/**
 * 🎨 Adaptador HTTP: CORS, JSON, rutas y manejo de errores.
 * Cada handler solo PARSEA la petición (DTO), INVOCÁ un caso de uso
 * y MAPEA el resultado a HTTP. Toda la lógica de negocio vive en
 * `application/usecases/`.
 */
export function createApp(deps: AppDependencies): express.Express {
  const app = express();

  // CORS: permite al frontend (otro origen/puerto) llamar a la API.
  // Producción restringe al dominio real vía CORS_ORIGIN (ver arriba).
  app.use(cors(resolveCorsOptions()));
  app.use(express.json());

  // GET / — health check
  app.get('/', (_req, res) => {
    res.json({
      app: 'Kontec API',
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  });

  // GET /todos — lista de tareas
  app.get('/todos', async (_req, res) => {
    res.json(await deps.listTodos.execute());
  });

  // POST /todos — crea una tarea  {"title": "..."}
  app.post('/todos', async (req, res) => {
    const dto = parseCreateTodoDTO(req.body);
    res.status(201).json(await deps.createTodo.execute(dto));
  });

  // GET /categories — categorías del catálogo (orden alfabético)
  app.get('/categories', async (_req, res) => {
    res.json(await deps.listCategories.execute());
  });

  // GET /courses — cursos del catálogo, con categoría embebida.
  // Filtros opcionales: /courses?status=active&limit=6
  app.get('/courses', async (req, res) => {
    res.json(await deps.listCourses.execute(parseListCoursesDTO(req.query)));
  });

  // POST /courses — crea un curso (panel administrativo).
  // Devuelve 201 con el curso creado y su categoría embebida.
  app.post('/courses', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseCourseDTO(req.body);
    res.status(201).json(await deps.createCourse.execute(dto));
  });

  // GET /courses/:id — detalle de un curso
  app.get('/courses/:id', async (req, res) => {
    const course = await deps.getCourseById.execute(req.params.id);
    if (!course) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.json(course);
  });

  // PATCH /courses/:id — actualiza un curso (panel administrativo).
  // Acepta los mismos campos que POST /courses. El "eliminar" del panel
  // es un CAMBIO DE ESTADO (status: 'inactive'); nunca se borra la fila.
  app.patch('/courses/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseCourseDTO(req.body);
    const course = await deps.updateCourse.execute(req.params.id, dto);
    if (!course) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.json(course);
  });

  // ─────────────────────────────────────────────────────────────
  // RUTAS DE ENTRENAMIENTO (agrupaciones de cursos con nivel)
  // ─────────────────────────────────────────────────────────────

  // GET /paths — rutas PUBLICADAS con sus cursos embebidos y ordenados.
  app.get('/paths', async (_req, res) => {
    res.json(await deps.listLearningPaths.execute());
  });

  // GET /paths/:slug — detalle de una ruta pública. 404 si no existe
  // o no está publicada.
  app.get('/paths/:slug', async (req, res) => {
    const path = await deps.getLearningPathBySlug.execute(req.params.slug);
    if (!path) {
      res.status(404).json({ error: 'Ruta no encontrada' });
      return;
    }
    res.json(path);
  });

  // ─────────────────────────────────────────────────────────────
  // AULA DEL ESTUDIANTE (temario + contenido + progreso)
  // ─────────────────────────────────────────────────────────────

  // GET /courses/:id/curriculum — temario (módulos + lecciones).
  // RUTA PÚBLICA con JWT opcional: el temario lo ve cualquiera; el
  // contenido (video/zoom/drive) solo viaja si el usuario tiene el
  // pago APROBADO (access: 'full'). access = full | pending |
  // rejected | none. 404 si el curso no existe.
  app.get('/courses/:id/curriculum', async (req, res) => {
    const user = await optionalAuth(req, deps.auth);
    const curriculum = await deps.getCurriculum.execute(user, req.params.id);

    if (!curriculum) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.json(curriculum);
  });

  // ─────────────────────────────────────────────────────────────
  // CUENTA (autenticación con Supabase)
  // ─────────────────────────────────────────────────────────────

  // GET /me — perfil + roles del usuario del JWT.
  app.get('/me', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    res.json(await deps.getMyProfile.execute(user));
  });

  // GET /me/profile — perfil PROPIO (auth, no admin): datos personales
  // + inscripciones, igual que /admin/students/:id pero SIEMPRE para el
  // usuario de la sesión. Un usuario que solo se registró (sin comprar)
  // no tiene fila en public.users → devuelve un perfil mínimo con el
  // email del JWT (el front completa el nombre desde su sesión).
  app.get('/me/profile', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    const profile = await deps.getStudentProfile.execute(user.id);
    if (profile) {
      res.json(profile);
      return;
    }
    res.json({
      id: user.id,
      fullName: '',
      email: user.email,
      phone: null,
      nationality: null,
      createdAt: null,
      isActive: true,
      enrollments: [],
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CHECKOUT (inscripciones + pagos pendientes de aprobación)
  // ─────────────────────────────────────────────────────────────

  // POST /checkout — registra la inscripción con datos personales.
  // Body: { fullName, email?, phone?, nationality?, documentNumber?,
  //         items: [{ courseId, amount }] }
  // Requiere: Authorization: Bearer <access_token de Supabase>.
  app.post('/checkout', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    // Si el front no envía email, se usa el de la sesión (JWT).
    const dto = parseCreateCheckoutDTO(req.body, user.email);
    res.status(201).json(await deps.createCheckout.execute(user, dto));
  });

  // ─────────────────────────────────────────────────────────────
  // CARRITO (persistido por usuario, estilo WooCommerce)
  // ─────────────────────────────────────────────────────────────

  // GET /cart — carrito del usuario del JWT, con título/precio resueltos
  // desde el catálogo (el precio siempre es el de la BD, nunca el del
  // cliente). Orden por addedAt asc; [] si está vacío.
  app.get('/cart', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    res.json(await deps.getCart.execute(user));
  });

  // PUT /cart — reemplaza el carrito COMPLETO del usuario.
  // Body: { items: [{ courseId }] } (máx 25; todos deben existir).
  // Responde { count: n } con los ítems que quedaron guardados.
  app.put('/cart', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    const dto = parseSaveCartDTO(req.body);
    res.json(await deps.saveCart.execute(user, dto));
  });

  // GET /my/courses — cursos inscritos del estudiante ("Mis cursos").
  // Devuelve TODOS los estados: los 'approved' son los que ya puede
  // entrar; los 'pending_payment' el front los muestra en revisión.
  app.get('/my/courses', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    res.json(await deps.getMyCourses.execute(user));
  });

  // PATCH /lessons/:id/progress — marca/desmarca una lección como
  // completada. Body: { completed: true|false }. Requiere pago del
  // curso APROBADO (si no → 403 AccessDeniedError); lección
  // inexistente → 404. Responde { lessonId, isCompleted }.
  app.patch('/lessons/:id/progress', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;

    const dto = parseLessonProgressDTO(req.body);
    const result = await deps.setLessonProgress.execute(
      user,
      req.params.id,
      dto.completed,
    );
    if (!result) {
      res.status(404).json({ error: 'Lección no encontrada' });
      return;
    }
    res.json(result);
  });

  // ─────────────────────────────────────────────────────────────
  // PANEL ADMINISTRATIVO (requiere rol "admin")
  // ─────────────────────────────────────────────────────────────

  // GET /admin/stats — KPIs del dashboard.
  app.get('/admin/stats', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'dashboard:view'))) return;
    res.json(await deps.getAdminStats.execute());
  });

  // GET /admin/students — estudiantes (usuarios) + cursos inscritos.
  app.get('/admin/students', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'students:view'))) return;
    res.json(await deps.listStudents.execute());
  });

  // GET /admin/carts — carritos abandonados: usuarios con carrito no
  // vacío, aplanados con datos del usuario y del curso (addedAt desc).
  app.get('/admin/carts', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'payments:view'))) return;
    res.json(await deps.listAbandonedCarts.execute());
  });

  // GET /admin/payments — pagos del panel. Filtro opcional:
  // /admin/payments?status=approved (por defecto pending_approval;
  // valores permitidos: pending_approval | approved | rejected).
  app.get('/admin/payments', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'payments:view'))) return;

    const dto = parseListPaymentsDTO(req.query);
    res.json(await deps.listPayments.execute(dto.status));
  });

  // PATCH /admin/payments/:id — decisión MANUAL del admin:
  // { action: 'approve' | 'reject' }. Al aprobar, la inscripción pasa
  // a 'approved' y el estudiante gana ACCESO al curso; al rechazar,
  // lo pierde. Responde { id, status } o 404 si el pago no existe.
  app.patch('/admin/payments/:id', async (req, res) => {
    const user = await requirePermission(req, res, deps.auth, 'payments:approve');
    if (!user) return;

    const dto = parsePaymentDecisionDTO(req.body);
    const decision = await deps.decidePayment.execute(
      user,
      req.params.id,
      dto.action,
    );
    if (!decision) {
      res.status(404).json({ error: 'Pago no encontrado' });
      return;
    }
    res.json(decision);
  });

  // GET /admin/courses/:id/participants — participantes del curso
  // (inscripción + nombre, correo, teléfono, estado y fecha). 404 si el
  // curso no existe.
  app.get('/admin/courses/:id/participants', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:view'))) return;

    const result = await deps.listCourseParticipants.execute(req.params.id);
    if (!result) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.json(result);
  });

  // GET /admin/students/:id — perfil del estudiante + sus inscripciones.
  // 404 si no existe.
  app.get('/admin/students/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'students:view'))) return;

    const profile = await deps.getStudentProfile.execute(req.params.id);
    if (!profile) {
      res.status(404).json({ error: 'Estudiante no encontrado' });
      return;
    }
    res.json(profile);
  });

  // PATCH /admin/students/:studentId/enrollments/:courseId — quita o
  // restaura el ACCESO al curso ({ action: 'revoke' | 'restore' }).
  // 'revoke' deja la inscripción en 'revoked' (sin acceso al aula);
  // 'restore' la vuelve a 'approved'. No toca el pago. 404 si no está
  // inscrito.
  app.patch(
    '/admin/students/:studentId/enrollments/:courseId',
    async (req, res) => {
      if (!(await requirePermission(req, res, deps.auth, 'students:manage'))) return;

      const dto = parseEnrollmentAccessDTO(req.body);
      const result = await deps.setEnrollmentAccess.execute(
        req.params.studentId,
        req.params.courseId,
        dto.action,
      );
      if (!result) {
        res
          .status(404)
          .json({ error: 'El estudiante no está inscrito en este curso' });
        return;
      }
      res.json(result);
    },
  );

  // GET /admin/users — todos los usuarios + sus roles
  // (admin / teacher / student / sin rol).
  app.get('/admin/users', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'users:view'))) return;
    res.json(await deps.listAdminUsers.execute());
  });

  // POST /admin/categories — crea una categoría { name, slug? }.
  app.post('/admin/categories', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'categories:edit'))) return;

    const dto = parseCreateCategoryDTO(req.body);
    res.status(201).json(await deps.createCategory.execute(dto));
  });

  // POST /admin/users — crea un usuario (auth + perfil + rol).
  // Body: { email, password, fullName, phone?, role? }  (role: admin|student)
  app.post('/admin/users', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'users:create'))) return;

    const dto = parseCreateAdminUserDTO(req.body);
    res.status(201).json(await deps.createAdminUser.execute(dto));
  });

  // PATCH /admin/categories/:id — renombra una categoría { name, slug? }.
  app.patch('/admin/categories/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'categories:edit'))) return;

    const dto = parseUpdateCategoryDTO(req.params.id, req.body);
    const category = await deps.updateCategory.execute(dto);
    if (!category) {
      res.status(404).json({ error: 'Categoría no encontrada' });
      return;
    }
    res.json(category);
  });

  // ─────────────────────────────────────────────────────────────
  // RUTAS DE ENTRENAMIENTO (CRUD del panel /admin/rutas)
  // ─────────────────────────────────────────────────────────────

  // GET /admin/paths — TODAS las rutas (incluye borradores).
  app.get('/admin/paths', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:view'))) return;
    res.json(await deps.listLearningPaths.execute(true));
  });

  // POST /admin/paths — crea una ruta { title, slug?, description?, ... }.
  app.post('/admin/paths', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseCreatePathDTO(req.body);
    res.status(201).json(await deps.createLearningPath.execute(dto));
  });

  // PATCH /admin/paths/:id — edita la cabecera. 404 si no existe.
  app.patch('/admin/paths/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseUpdatePathDTO(req.params.id, req.body);
    const path = await deps.updateLearningPath.execute(dto);
    if (!path) {
      res.status(404).json({ error: 'Ruta no encontrada' });
      return;
    }
    res.json(path);
  });

  // PUT /admin/paths/:id/courses — reemplaza TODOS los cursos de la
  // ruta. Body: { courses: [{ courseId, level?, sortOrder? }] }.
  // 404 si la ruta no existe; 400 si un curso no está en el catálogo.
  app.put('/admin/paths/:id/courses', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseSetPathCoursesDTO(req.body);
    const path = await deps.setLearningPathCourses.execute(
      req.params.id,
      dto,
    );
    if (!path) {
      res.status(404).json({ error: 'Ruta no encontrada' });
      return;
    }
    res.json(path);
  });

  // DELETE /admin/paths/:id — borra la ruta (sus cursos caen en cascada).
  app.delete('/admin/paths/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const deleted = await deps.deleteLearningPath.execute(req.params.id);
    if (!deleted) {
      res.status(404).json({ error: 'Ruta no encontrada' });
      return;
    }
    res.json({ deleted: true });
  });

  // ─────────────────────────────────────────────────────────────
  // MEMBRESÍAS (3 planes: mensual /6 meses / anual → acceso total)
  // ─────────────────────────────────────────────────────────────

  // GET /membership-plans — planes activos (página pública /membresias).
  app.get('/membership-plans', async (_req, res) => {
    res.json(await deps.listMembershipPlans.execute());
  });

  // GET /my/membership — membresía ACTIVA del usuario (banner).
  app.get('/my/membership', async (req, res) => {
    const user = await requireAuth(req, res, deps.auth);
    if (!user) return;
    res.json(await deps.getMyMembership.execute(user));
  });

  // GET /admin/membership-plans — todos los planes (incluye inactivos).
  app.get('/admin/membership-plans', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:view'))) return;
    res.json(await deps.listMembershipPlans.execute(true));
  });

  // POST /admin/membership-plans — crea un plan { name, months, price… }.
  app.post('/admin/membership-plans', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;
    const dto = parseCreatePlanDTO(req.body);
    res.status(201).json(await deps.createMembershipPlan.execute(dto));
  });

  // PATCH /admin/membership-plans/:id — edita un plan. 404 si no existe.
  app.patch('/admin/membership-plans/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;
    const dto = parseUpdatePlanDTO(req.params.id, req.body);
    const plan = await deps.updateMembershipPlan.execute(dto);
    if (!plan) {
      res.status(404).json({ error: 'Plan no encontrado' });
      return;
    }
    res.json(plan);
  });

  // DELETE /admin/membership-plans/:id — borra un plan.
  app.delete('/admin/membership-plans/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;
    const deleted = await deps.deleteMembershipPlan.execute(req.params.id);
    if (!deleted) {
      res.status(404).json({ error: 'Plan no encontrado' });
      return;
    }
    res.json({ deleted: true });
  });

  // GET /admin/memberships — todas las membresías (usuario + fechas).
  app.get('/admin/memberships', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:view'))) return;
    res.json(await deps.listMemberships.execute());
  });

  // POST /admin/memberships — alta manual { userId, planId, status? }.
  // Con status 'active' sin fechas, el caso de uso calcula el
  // rango desde hoy + meses del plan.
  app.post('/admin/memberships', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;
    const dto = parseCreateMembershipDTO(req.body);
    res.status(201).json(await deps.createMembership.execute(dto));
  });

  // PATCH /admin/memberships/:id — estado/fechas (revocar, renovar…).
  app.patch('/admin/memberships/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;
    const dto = parseUpdateMembershipDTO(req.params.id, req.body);
    const membership = await deps.updateMembership.execute(dto);
    if (!membership) {
      res.status(404).json({ error: 'Membresía no encontrada' });
      return;
    }
    res.json(membership);
  });

  // PATCH /admin/users/:id — edita un usuario { fullName?, phone?, role?,
  // isActive? }. "Desactivar" (isActive: false) es un BORRADO LÓGICO: la
  // cuenta y todos sus datos se conservan en la BD.
  app.patch('/admin/users/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'users:edit'))) return;

    const dto = parseUpdateAdminUserDTO(req.params.id, req.body);
    const user = await deps.updateAdminUser.execute(dto);
    if (!user) {
      res.status(404).json({ error: 'Usuario no encontrado' });
      return;
    }
    res.json(user);
  });

  // ─────────────────────────────────────────────────────────────
  // ROLES Y PERMISOS (matriz rol × permiso del panel)
  // ─────────────────────────────────────────────────────────────

  // GET /admin/roles — roles + catálogo de permisos + grants.
  // El rol admin sale con grants completos (bypass calculado).
  app.get('/admin/roles', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'roles:manage'))) return;
    res.json(await deps.listRolesMatrix.execute());
  });

  // POST /admin/roles — crea un rol { name, description? }.
  // name en minúsculas; 400 si ya existe (ValidationError).
  app.post('/admin/roles', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'roles:manage'))) return;

    const dto = parseCreateRoleDTO(req.body);
    res.status(201).json(await deps.createRole.execute(dto));
  });

  // PUT /admin/roles/:id/permissions — reemplaza TODOS los grants del
  // rol. Body: { codes: ['users:view', ...] } ([] = revoca todos).
  // 400 si el rol es `admin` (inmutable) o hay códigos desconocidos;
  // 404 si el rol no existe.
  app.put('/admin/roles/:id/permissions', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'roles:manage'))) return;

    const dto = parseSaveRolePermissionsDTO(req.body);
    const updated = await deps.saveRolePermissions.execute(
      req.params.id,
      dto.codes,
    );
    if (!updated) {
      res.status(404).json({ error: 'Rol no encontrado' });
      return;
    }
    res.json({ updated: true });
  });

  // DELETE /admin/roles/:id — borra un rol que no sea base y no tenga
  // usuarios asignados (grants y asignaciones caen en cascada por FK).
  app.delete('/admin/roles/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'roles:manage'))) return;

    const result = await deps.deleteRole.execute(req.params.id);

    switch (result) {
      case 'not_found':
        res.status(404).json({ error: 'Rol no encontrado' });
        return;
      case 'system':
        res
          .status(400)
          .json({ error: 'No se puede eliminar un rol base del sistema.' });
        return;
      case 'in_use':
        res
          .status(409)
          .json({ error: 'El rol tiene usuarios asignados; quítalos primero.' });
        return;
      default:
        res.json({ deleted: true });
    }
  });

  // ─────────────────────────────────────────────────────────────
  // TEMARIO (módulos + lecciones) — edición del panel admin
  // ─────────────────────────────────────────────────────────────

  // GET /admin/courses/:id/curriculum — temario COMPLETO del curso,
  // con todas las URLs de contenido (a diferencia del aula del alumno,
  // que solo ve las suyas y con el gate de pago).
  app.get('/admin/courses/:id/curriculum', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:view'))) return;

    const curriculum = await deps.getAdminCurriculum.execute(req.params.id);
    if (!curriculum) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.json(curriculum);
  });

  // POST /admin/courses/:id/modules — alta de módulo { title }.
  app.post('/admin/courses/:id/modules', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseCreateModuleDTO(req.body);
    if (!(await deps.getAdminCurriculum.execute(req.params.id))) {
      res.status(404).json({ error: 'Curso no encontrado' });
      return;
    }
    res.status(201).json(await deps.createModule.execute(req.params.id, dto));
  });

  // PATCH /admin/modules/:id — { title?, orderIndex? } (orderIndex mueve
  // el módulo dentro del curso, 1-based).
  app.patch('/admin/modules/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseUpdateModuleDTO(req.body);
    const module = await deps.updateModule.execute(req.params.id, dto);
    if (!module) {
      res.status(404).json({ error: 'Módulo no encontrado' });
      return;
    }
    res.json(module);
  });

  // DELETE /admin/modules/:id — borra el módulo EN CASCADA (sus
  // lecciones y su progreso). Irreversible.
  app.delete('/admin/modules/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    if (!(await deps.deleteModule.execute(req.params.id))) {
      res.status(404).json({ error: 'Módulo no encontrado' });
      return;
    }
    res.json({ deleted: true });
  });

  // POST /admin/modules/:id/lessons — alta de lección
  // { title, contentType, videoUrl?, zoomUrl?, driveUrl? }.
  app.post('/admin/modules/:id/lessons', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseCreateLessonDTO(req.body);
    try {
      res.status(201).json(await deps.createLesson.execute(req.params.id, dto));
    } catch (error) {
      // El módulo no existe: el repositorio lo señala por mensaje.
      if (error instanceof Error && error.message.includes('Módulo inexistente')) {
        res.status(404).json({ error: 'Módulo no encontrado' });
        return;
      }
      throw error;
    }
  });

  // PATCH /admin/lessons/:id — campos de la lección y/o orderIndex
  // (dentro de su módulo). Una URL puede borrarse con null.
  app.patch('/admin/lessons/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    const dto = parseUpdateLessonDTO(req.body);
    const lesson = await deps.updateLesson.execute(req.params.id, dto);
    if (!lesson) {
      res.status(404).json({ error: 'Lección no encontrada' });
      return;
    }
    res.json(lesson);
  });

  // DELETE /admin/lessons/:id — borra la lección y su progreso.
  app.delete('/admin/lessons/:id', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    if (!(await deps.deleteLesson.execute(req.params.id))) {
      res.status(404).json({ error: 'Lección no encontrada' });
      return;
    }
    res.json({ deleted: true });
  });

  // POST /admin/upload-image — sube una imagen local (multipart/form-data,
  // campo "image", máx 5 MB) al bucket PÚBLICO "courses" de Supabase
  // Storage y devuelve { path, publicUrl }. La URL pública es la que se
  // guarda en courses.image_url.
  const uploadImageMiddleware = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
  }).single('image');

  const runUploadImage = (req: Request, res: Response): Promise<void> =>
    new Promise((resolve, reject) => {
      uploadImageMiddleware(req, res, (err: unknown) =>
        err ? reject(err) : resolve(),
      );
    });

  app.post('/admin/upload-image', async (req, res) => {
    if (!(await requirePermission(req, res, deps.auth, 'courses:create'))) return;

    try {
      await runUploadImage(req, res);
    } catch (err) {
      res.status(400).json({
        error: err instanceof Error ? err.message : 'Archivo inválido',
      });
      return;
    }

    const dto = parseUploadImageDTO(req.file);
    res.status(201).json(await deps.uploadImage.execute(dto));
  });

  // 404 — ruta desconocida
  app.use((_req, res) => {
    res.status(404).json({ error: 'Ruta no encontrada' });
  });

  // Errores: ValidationError (casos de uso/DTOs) → 400; JSON inválido u
  // otros → respuesta JSON controlada.
  app.use(
    (err: unknown, _req: Request, res: Response, next: NextFunction) => {
      if (res.headersSent) {
        next(err);
        return;
      }

      if (err instanceof ValidationError) {
        res.status(400).json({ error: err.message });
        return;
      }

      if (err instanceof AccessDeniedError) {
        res.status(403).json({ error: err.message });
        return;
      }

      const status =
        typeof err === 'object' && err !== null && 'status' in err
          ? Number((err as { status: unknown }).status)
          : 500;
      const isBadRequest = status >= 400 && status < 500;

      // Siempre dejamos rastro en consola del error real (si la BD o la
      // red fallan, el 500 solo no dice nada).
      // eslint-disable-next-line no-console
      console.error(
        `[ERROR] ${_req.method} ${_req.path} →`,
        err instanceof Error ? err.message : err,
      );

      res
        .status(isBadRequest ? status : 500)
        .json(
          isBadRequest
            ? { error: 'Cuerpo JSON inválido' }
            : { error: 'Error interno del servidor' },
        );
    },
  );

  return app;
}
