import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { createUseCases } from '../src/application/compose.js';
import { InMemoryAdminRepository } from '../src/data/in-memory-admin-repository.js';
import { InMemoryCartRepository } from '../src/data/in-memory-cart-repository.js';
import { InMemoryCatalogRepository } from '../src/data/in-memory-catalog-repository.js';
import { InMemoryCheckoutRepository } from '../src/data/in-memory-checkout-repository.js';
import { InMemoryCurriculumRepository } from '../src/data/in-memory-curriculum-repository.js';
import { InMemoryLearningPathRepository } from '../src/data/in-memory-learning-path-repository.js';
import { InMemoryMembershipRepository } from '../src/data/in-memory-membership-repository.js';
import { InMemoryRolesRepository } from '../src/data/in-memory-roles-repository.js';
import { InMemoryTodoRepository } from '../src/data/in-memory-todo-repository.js';

function buildApp() {
  const todos = new InMemoryTodoRepository();
  const catalog = new InMemoryCatalogRepository();
  const checkout = new InMemoryCheckoutRepository(catalog);
  // En memoria el admin comparte el checkout: aprobar un pago cambia
  // la inscripción (y por tanto el acceso al aula), como en la BD.
  // El catálogo le sirve para validar existencia del curso al
  // editar su temario.
  const admin = new InMemoryAdminRepository(checkout, catalog);
  const paths = new InMemoryLearningPathRepository(catalog);
  const memberships = new InMemoryMembershipRepository();
  const cart = new InMemoryCartRepository(catalog, paths, memberships);
  const curriculum = new InMemoryCurriculumRepository(
    catalog,
    checkout,
    memberships,
  );
  const roles = new InMemoryRolesRepository();

  return createApp({
    auth: checkout,
    ...createUseCases({
      todos,
      catalog,
      checkout,
      admin,
      cart,
      curriculum,
      roles,
      paths,
      memberships,
    }),
  });
}

/**
 * App con `auth` mockeado: cualquier token verifica como el usuario
 * `u1` (rol teacher) con EXACTAMENTE los permisos indicados.
 *
 * El repo en memoria hace bypass de admin (devuelve todos los códigos),
 * así que sin este helper no se puede probar un 403.
 */
function appWithPermissions(codes: string[]) {
  const todos = new InMemoryTodoRepository();
  const catalog = new InMemoryCatalogRepository();
  const checkout = new InMemoryCheckoutRepository(catalog);

  return createApp({
    auth: {
      verifyToken: async () => ({ id: 'u1', email: 'docente@ejemplo.com' }),
      getRoles: async () => ['teacher'],
      getPermissions: async () => codes,
    },
    ...createUseCases({
      todos,
      catalog,
      checkout,
      admin: new InMemoryAdminRepository(checkout, catalog),
      cart: new InMemoryCartRepository(catalog, new InMemoryLearningPathRepository(catalog), new InMemoryMembershipRepository()),
      curriculum: new InMemoryCurriculumRepository(catalog, checkout, new InMemoryMembershipRepository()),
      roles: new InMemoryRolesRepository(),
      paths: new InMemoryLearningPathRepository(catalog),
      memberships: new InMemoryMembershipRepository(),
    }),
  });
}

describe('GET /', () => {
  it('responde 200 con el health check en JSON', async () => {
    const res = await request(buildApp()).get('/');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.app).toBe('Kontec API');
  });
});

describe('GET /todos', () => {
  it('responde 200 con la lista de tareas', async () => {
    const app = buildApp();
    await request(app)
      .post('/todos')
      .send({ title: 'Estudiar Clean Architecture' });

    const res = await request(app).get('/todos');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({
      title: 'Estudiar Clean Architecture',
      completed: false,
    });
  });
});

describe('POST /todos', () => {
  it('responde 201 y crea la tarea', async () => {
    const app = buildApp();

    const res = await request(app)
      .post('/todos')
      .send({ title: 'Comprar café' });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ id: 1, title: 'Comprar café' });
    expect((await request(app).get('/todos')).body).toHaveLength(1);
  });

  it('responde 400 si falta el título', async () => {
    const app = buildApp();

    const res = await request(app).post('/todos').send({ title: '   ' });

    expect(res.status).toBe(400);
    expect((await request(app).get('/todos')).body).toHaveLength(0);
  });

  it('responde 400 si el cuerpo no es JSON válido', async () => {
    const res = await request(buildApp())
      .post('/todos')
      .set('Content-Type', 'application/json')
      .send('esto no es json');

    expect(res.status).toBe(400);
  });
});

describe('GET /categories', () => {
  it('responde 200 con la lista de categorías', async () => {
    const res = await request(buildApp()).get('/categories');

    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0]).toMatchObject({ id: expect.any(String), name: expect.any(String), slug: expect.any(String) });
  });
});

describe('GET /courses', () => {
  it('responde 200 con los cursos y su categoría embebida', async () => {
    const res = await request(buildApp()).get('/courses');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({
      id: 'a0000000-0000-0000-0000-000000000001',
      totalHours: 40,
      price: 150,
      status: 'active',
      category: { name: 'Estructuras y Concreto' },
    });
  });

  it('filtra por status con ?status=', async () => {
    const res = await request(buildApp()).get('/courses?status=draft');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(0);
  });

  it('ignora un ?limit= no válido y devuelve la lista completa', async () => {
    const res = await request(buildApp()).get('/courses?limit=0');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
  });
});

describe('POST /courses', () => {
  const auth = { Authorization: 'Bearer token-valido' };

  it('responde 401 sin sesión y 403 sin el permiso courses:create', async () => {
    const app = buildApp();

    expect((await request(app).post('/courses')).status).toBe(401);

    const forbidden = await request(
      appWithPermissions(['dashboard:view']),
    )
      .post('/courses')
      .set(auth)
      .send({ title: 'X', modality: 'live' });
    expect(forbidden.status).toBe(403);
    expect(forbidden.body.error).toContain('courses:create');
  });

  it('responde 201, crea el curso y aparece en el listado', async () => {
    const app = buildApp();

    const res = await request(app).post('/courses').set(auth).send({
      title: 'Fundamentos de Geotecnia',
      description: 'Mecánica de suelos aplicada.',
      categoryId: '24999c81-5dfd-4265-a8b8-237e077f0d2a',
      modality: 'live',
      totalHours: 30,
      totalWeeks: 6,
      price: 120,
      compareAtPrice: 180,
      status: 'active',
      professorBio: 'Ing. con 10 años en suelos.',
      teachingMethod: 'Clases en vivo\nCasos reales',
      targetAudience: 'Ingenieros civiles\nProyectistas',
      certificateInfo: 'Certificado con QR',
      careerOpportunities: 'Geotécnico\nSupervisor de obra',
    });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      id: expect.any(String),
      title: 'Fundamentos de Geotecnia',
      modality: 'live',
      totalHours: 30,
      totalWeeks: 6,
      status: 'active',
      category: { name: 'Geotecnia y Vías' },
      professorBio: 'Ing. con 10 años en suelos.',
      teachingMethod: 'Clases en vivo\nCasos reales',
      targetAudience: 'Ingenieros civiles\nProyectistas',
      certificateInfo: 'Certificado con QR',
      careerOpportunities: 'Geotécnico\nSupervisor de obra',
    });

    const list = await request(app).get('/courses');
    expect(list.body).toHaveLength(2);
    expect(list.body[0].title).toBe('Fundamentos de Geotecnia');
  });

  it('responde 400 si falta el título', async () => {
    const res = await request(buildApp())
      .post('/courses')
      .set(auth)
      .send({ totalHours: 10 });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('title');
  });

  it('responde 400 si la modalidad o el estado no son válidos', async () => {
    const app = buildApp();

    const badModality = await request(app)
      .post('/courses')
      .set(auth)
      .send({ title: 'X', modality: 'presencial' });
    expect(badModality.status).toBe(400);

    const badStatus = await request(app)
      .post('/courses')
      .set(auth)
      .send({ title: 'X', status: 'borrador' });
    expect(badStatus.status).toBe(400);
  });

  it('responde 400 si la categoría no existe o los números son negativos', async () => {
    const app = buildApp();

    const badCategory = await request(app)
      .post('/courses')
      .set(auth)
      .send({ title: 'X', categoryId: 'no-existe' });
    expect(badCategory.status).toBe(400);

    const badNumber = await request(app)
      .post('/courses')
      .set(auth)
      .send({ title: 'X', totalHours: -5 });
    expect(badNumber.status).toBe(400);

    const badWeeks = await request(app)
      .post('/courses')
      .set(auth)
      .send({ title: 'X', totalWeeks: 2.5 });
    expect(badWeeks.status).toBe(400);
  });
});

describe('GET /courses/:id', () => {
  it('responde 200 con el curso existente', async () => {
    const res = await request(buildApp()).get(
      '/courses/a0000000-0000-0000-0000-000000000001',
    );

    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Diseño Avanzado de Estructuras de Concreto Armado');
  });

  it('responde 404 si el curso no existe', async () => {
    const res = await request(buildApp()).get('/courses/no-existe');

    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Curso no encontrado');
  });
});

describe('CORS', () => {
  it('contesta al preflight OPTIONS con cabeceras permitidas', async () => {
    const res = await request(buildApp())
      .options('/todos')
      .set('Origin', 'http://localhost:8080')
      .set('Access-Control-Request-Method', 'POST');

    expect(res.status).toBe(204);
    expect(res.headers['access-control-allow-origin']).toBeTruthy();
    expect(res.headers['access-control-allow-methods']).toContain('POST');
  });
});

describe('GET /me', () => {
  it('responde 401 sin token', async () => {
    const res = await request(buildApp()).get('/me');

    expect(res.status).toBe(401);
  });

  it('responde 200 con id, email, roles y permisos del JWT', async () => {
    const res = await request(buildApp())
      .get('/me')
      .set('Authorization', 'Bearer token-valido');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      id: 'mem-user-1',
      email: 'dev@kontec.pe',
      roles: expect.arrayContaining(['admin']),
      // El repo en memoria hace bypass de admin: catálogo completo.
      permissions: expect.arrayContaining([
        'dashboard:view',
        'roles:manage',
        'payments:approve',
      ]),
    });
  });
});

describe('POST /checkout', () => {
  const payload = {
    fullName: 'Carla Quispe',
    email: 'carla@ejemplo.com',
    phone: '999888777',
    nationality: 'Peruana',
    documentNumber: '70123456',
    items: [
      { courseId: 'a0000000-0000-0000-0000-000000000001', amount: 150 },
    ],
  };

  it('responde 401 sin token de sesión', async () => {
    const res = await request(buildApp()).post('/checkout').send(payload);

    expect(res.status).toBe(401);
  });

  it('responde 201 con inscripciones y pagos pendientes', async () => {
    const res = await request(buildApp())
      .post('/checkout')
      .set('Authorization', 'Bearer token-valido')
      .send(payload);

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      userId: 'mem-user-1',
      total: 150,
      enrollments: [
        {
          courseId: 'a0000000-0000-0000-0000-000000000001',
          status: 'pending_payment',
        },
      ],
      payments: [{ amount: 150, status: 'pending_approval' }],
    });
  });

  it('responde 400 si el carrito está vacío o falta el nombre', async () => {
    const app = buildApp();

    const empty = await request(app)
      .post('/checkout')
      .set('Authorization', 'Bearer token-valido')
      .send({ ...payload, items: [] });
    expect(empty.status).toBe(400);

    const noName = await request(app)
      .post('/checkout')
      .set('Authorization', 'Bearer token-valido')
      .send({ ...payload, fullName: '   ' });
    expect(noName.status).toBe(400);
  });

  it('responde 400 si un item no tiene courseId o amount', async () => {
    const res = await request(buildApp())
      .post('/checkout')
      .set('Authorization', 'Bearer token-valido')
      .send({ items: [{ courseId: 'x' }] });

    expect(res.status).toBe(400);
  });

  it('responde 400 si el curso ya está en verificación o aprobado', async () => {
    const app = buildApp();
    const auth = { Authorization: 'Bearer token-valido' };

    const first = await request(app)
      .post('/checkout')
      .set(auth)
      .send(payload);
    expect(first.status).toBe(201);

    // Sigue pending_payment → no debe poder pagarlo dos veces.
    const second = await request(app)
      .post('/checkout')
      .set(auth)
      .send(payload);
    expect(second.status).toBe(400);
    expect(second.body.error).toContain('verificación');

    // Aprueba el pago (en memoria cualquier token es admin).
    const paymentId = (first.body.payments as Array<{ id: string }>)[0]!.id;
    const approved = await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set(auth)
      .send({ action: 'approve' });
    expect(approved.status).toBe(200);

    // Ya aprobado → tampoco puede volver a comprarlo (perdería acceso).
    const third = await request(app)
      .post('/checkout')
      .set(auth)
      .send(payload);
    expect(third.status).toBe(400);
    expect(third.body.error).toContain('inscrito');
  });
});

describe('Panel administrativo', () => {
  it('GET /admin/stats responde 200 con los KPIs', async () => {
    const res = await request(buildApp())
      .get('/admin/stats')
      .set('Authorization', 'Bearer token-valido');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      students: expect.any(Number),
      courses: expect.any(Number),
      enrollments: expect.any(Number),
      pendingPayments: expect.any(Number),
      revenue: expect.any(Number),
    });
  });

  it('GET /admin/students responde 200 con la lista', async () => {
    const res = await request(buildApp())
      .get('/admin/students')
      .set('Authorization', 'Bearer token-valido');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('GET /admin/users responde 200 con usuarios y sus roles', async () => {
    const res = await request(buildApp())
      .get('/admin/users')
      .set('Authorization', 'Bearer token-valido');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toMatchObject({
      email: expect.any(String),
      roles: expect.any(Array),
    });
  });

  it('POST /admin/upload-image valida sesión, archivo y devuelve URL', async () => {
    const app = buildApp();

    const sinToken = await request(app).post('/admin/upload-image');
    expect(sinToken.status).toBe(401);

    const sinArchivo = await request(app)
      .post('/admin/upload-image')
      .set('Authorization', 'Bearer token-valido');
    expect(sinArchivo.status).toBe(400);

    const ok = await request(app)
      .post('/admin/upload-image')
      .set('Authorization', 'Bearer token-valido')
      .attach('image', Buffer.from([0x89, 0x50, 0x4e, 0x47]), {
        filename: 'portada.png',
        contentType: 'image/png',
      });
    expect(ok.status).toBe(201);
    expect(ok.body).toMatchObject({
      path: expect.stringContaining('portada'),
      publicUrl: expect.stringContaining('http'),
    });
  });

  it('POST /admin/categories valida el nombre y crea la categoría', async () => {
    const app = buildApp();

    const bad = await request(app)
      .post('/admin/categories')
      .set('Authorization', 'Bearer token-valido')
      .send({});
    expect(bad.status).toBe(400);

    const ok = await request(app)
      .post('/admin/categories')
      .set('Authorization', 'Bearer token-valido')
      .send({ name: 'VDC' });
    expect(ok.status).toBe(201);
    expect(ok.body).toMatchObject({ name: 'VDC', slug: 'vdc' });
  });

  it('POST /admin/users valida email, contraseña y nombre', async () => {
    const app = buildApp();

    const badPassword = await request(app)
      .post('/admin/users')
      .set('Authorization', 'Bearer token-valido')
      .send({ email: 'a@b.com', password: '123', fullName: 'Ana' });
    expect(badPassword.status).toBe(400);

    const ok = await request(app)
      .post('/admin/users')
      .set('Authorization', 'Bearer token-valido')
      .send({
        email: 'ana@ejemplo.com',
        password: 'secreto123',
        fullName: 'Ana Torres',
        role: 'student',
      });
    expect(ok.status).toBe(201);
    expect(ok.body).toMatchObject({ email: 'ana@ejemplo.com' });
  });
});

describe('CARRITO — GET /cart y PUT /cart', () => {
  const auth = 'Bearer token-valido';
  // Curso sembrado en el catálogo en memoria (price: 150).
  const courseId = 'a0000000-0000-0000-0000-000000000001';

  it('GET /cart responde 401 sin token', async () => {
    const res = await request(buildApp()).get('/cart');

    expect(res.status).toBe(401);
  });

  it('GET /cart responde 200 con [] si el usuario no tiene carrito', async () => {
    const res = await request(buildApp())
      .get('/cart')
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('PUT /cart guarda los cursos y GET /cart los devuelve con datos del catálogo', async () => {
    const app = buildApp();

    const put = await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({ items: [{ courseId }] });
    expect(put.status).toBe(200);
    expect(put.body).toEqual({ count: 1 });

    const get = await request(app).get('/cart').set('Authorization', auth);
    expect(get.status).toBe(200);
    expect(get.body).toHaveLength(1);
    expect(get.body[0]).toMatchObject({
      courseId,
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      price: 150,
    });
    expect(typeof get.body[0].addedAt).toBe('string');
  });

  it('PUT /cart reemplaza el carrito completo (no acumula)', async () => {
    const app = buildApp();
    await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({ items: [{ courseId }] });

    const replace = await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({ items: [] });
    expect(replace.status).toBe(200);
    expect(replace.body).toEqual({ count: 0 });

    const get = await request(app).get('/cart').set('Authorization', auth);
    expect(get.body).toEqual([]);
  });

  it('PUT /cart responde 401 sin token', async () => {
    const res = await request(buildApp())
      .put('/cart')
      .send({ items: [{ courseId }] });

    expect(res.status).toBe(401);
  });

  it('PUT /cart valida el body (items, courseId vacío y máximo 25)', async () => {
    const app = buildApp();

    const sinItems = await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({});
    expect(sinItems.status).toBe(400);

    const courseIdVacio = await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({ items: [{ courseId: '   ' }] });
    expect(courseIdVacio.status).toBe(400);

    const demasiados = await request(app)
      .put('/cart')
      .set('Authorization', auth)
      .send({
        items: Array.from({ length: 26 }, () => ({ courseId })),
      });
    expect(demasiados.status).toBe(400);
  });

  it('PUT /cart responde 400 si un curso no existe', async () => {
    const res = await request(buildApp())
      .put('/cart')
      .set('Authorization', auth)
      .send({ items: [{ courseId: 'no-existe' }] });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('Curso no encontrado');
  });
});

describe('PANEL — GET /admin/carts y GET /admin/payments', () => {
  const auth = 'Bearer token-valido';

  it('GET /admin/carts lista los carritos abandonados (addedAt desc)', async () => {
    const res = await request(buildApp())
      .get('/admin/carts')
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
    // Los más recientes primero (Ana 2026-10-23 antes que Luis 2026-10-22).
    expect(res.body[0]).toMatchObject({
      email: 'ana@ejemplo.com',
      fullName: 'Ana Torres',
      price: 150,
    });
    expect(res.body[1]).toMatchObject({ email: 'luis@ejemplo.com' });
  });

  it('GET /admin/payments filtra por status (por defecto pending_approval)', async () => {
    const app = buildApp();

    const pendientes = await request(app)
      .get('/admin/payments')
      .set('Authorization', auth);
    expect(pendientes.status).toBe(200);
    expect(pendientes.body).toHaveLength(2);
    for (const payment of pendientes.body) {
      expect(payment.status).toBe('pending_approval');
    }

    const aprobados = await request(app)
      .get('/admin/payments?status=approved')
      .set('Authorization', auth);
    expect(aprobados.status).toBe(200);
    expect(aprobados.body).toHaveLength(1);
    expect(aprobados.body[0]).toMatchObject({
      status: 'approved',
      email: 'dev@kontec.pe',
      courseTitle: 'Diseño Avanzado de Estructuras de Concreto Armado',
    });
  });

  it('GET /admin/payments rechaza un status no permitido', async () => {
    const res = await request(buildApp())
      .get('/admin/payments?status=inventado')
      .set('Authorization', auth);

    expect(res.status).toBe(400);
  });
});

describe('MIS CURSOS — GET /my/courses', () => {
  const auth = 'Bearer token-valido';
  // Curso sembrado en el catálogo en memoria.
  const courseId = 'a0000000-0000-0000-0000-000000000001';

  it('GET /my/courses responde 401 sin token', async () => {
    const res = await request(buildApp()).get('/my/courses');

    expect(res.status).toBe(401);
  });

  it('devuelve los cursos inscritos con su estado y datos del catálogo', async () => {
    const app = buildApp();

    // El estudiante solicita el curso (el checkout crea la inscripción).
    const checkout = await request(app)
      .post('/checkout')
      .set('Authorization', auth)
      .send({ fullName: 'Dev Kontec', items: [{ courseId, amount: 150 }] });
    expect(checkout.status).toBe(201);

    const res = await request(app)
      .get('/my/courses')
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({
      courseId,
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      // Aún sin pago aprobado → el front muestra "pago en revisión".
      status: 'pending_payment',
    });
    expect(typeof res.body[0].enrolledAt).toBe('string');
  });

  it('responde [] si el estudiante no tiene inscripciones', async () => {
    const res = await request(buildApp())
      .get('/my/courses')
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('incluye el avance (X de Y lecciones) con pago aprobado', async () => {
    const app = buildApp();

    // Solicitud → aprobación del admin → pago 'approved'.
    const checkout = await request(app)
      .post('/checkout')
      .set('Authorization', auth)
      .send({ fullName: 'Dev Kontec', items: [{ courseId, amount: 150 }] });
    expect(checkout.status).toBe(201);
    const paymentId = (checkout.body.payments as Array<{ id: string }>)[0]!.id;
    await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set('Authorization', auth)
      .send({ action: 'approve' });

    // Sin marcar nada → 0 del total del temario sembrado.
    const vacio = await request(app)
      .get('/my/courses')
      .set('Authorization', auth);
    expect(vacio.body[0]).toMatchObject({
      courseId,
      status: 'approved',
      completedLessons: 0,
    });
    expect(vacio.body[0].totalLessons).toBeGreaterThan(0);

    // Marcamos una lección → el avance sube a 1.
    await request(app)
      .patch('/lessons/mem-lesson-1/progress')
      .set('Authorization', auth)
      .send({ completed: true });

    const res = await request(app)
      .get('/my/courses')
      .set('Authorization', auth);
    expect(res.status).toBe(200);
    expect(res.body[0]).toMatchObject({
      courseId,
      status: 'approved',
      completedLessons: 1,
    });
  });

  it('sin pago aprobado el avance queda en 0/0', async () => {
    const app = buildApp();

    await request(app)
      .post('/checkout')
      .set('Authorization', auth)
      .send({ fullName: 'Dev Kontec', items: [{ courseId, amount: 150 }] });

    const res = await request(app)
      .get('/my/courses')
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body[0]).toMatchObject({
      status: 'pending_payment',
      totalLessons: 0,
      completedLessons: 0,
    });
  });
});

describe('PANEL — PATCH /admin/payments/:id (aprobar / rechazar)', () => {
  const auth = 'Bearer token-valido';

  it('aprueba un pago pendiente y sale de la cola de pendientes', async () => {
    const app = buildApp();

    const ok = await request(app)
      .patch('/admin/payments/mem-payment-1')
      .set('Authorization', auth)
      .send({ action: 'approve' });
    expect(ok.status).toBe(200);
    expect(ok.body).toEqual({ id: 'mem-payment-1', status: 'approved' });

    const pendientes = await request(app)
      .get('/admin/payments')
      .set('Authorization', auth);
    expect(
      (pendientes.body as Array<{ id: string }>).map((p) => p.id),
    ).not.toContain('mem-payment-1');

    const aprobados = await request(app)
      .get('/admin/payments?status=approved')
      .set('Authorization', auth);
    expect(
      (aprobados.body as Array<{ id: string }>).map((p) => p.id),
    ).toContain('mem-payment-1');
  });

  it('rechaza un pago pendiente', async () => {
    const res = await request(buildApp())
      .patch('/admin/payments/mem-payment-2')
      .set('Authorization', auth)
      .send({ action: 'reject' });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ id: 'mem-payment-2', status: 'rejected' });
  });

  it('responde 404 si el pago no existe', async () => {
    const res = await request(buildApp())
      .patch('/admin/payments/no-existe')
      .set('Authorization', auth)
      .send({ action: 'approve' });

    expect(res.status).toBe(404);
  });

  it('responde 400 si la acción no es válida', async () => {
    const res = await request(buildApp())
      .patch('/admin/payments/mem-payment-1')
      .set('Authorization', auth)
      .send({ action: 'dime que si' });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('action');
  });

  it('responde 401 sin token', async () => {
    const res = await request(buildApp())
      .patch('/admin/payments/mem-payment-1')
      .send({ action: 'approve' });

    expect(res.status).toBe(401);
  });
});

describe('AULA — GET /courses/:id/curriculum y PATCH /lessons/:id/progress', () => {
  const auth = 'Bearer token-valido';
  // Curso sembrado en el catálogo Y con temario sembrado en el
  // currículum en memoria (2 módulos, 3 lecciones).
  const courseId = 'a0000000-0000-0000-0000-000000000001';

  /** Sembra una inscripción del estudiante vía checkout. */
  async function solicitarCurso(app: ReturnType<typeof buildApp>) {
    const res = await request(app)
      .post('/checkout')
      .set('Authorization', auth)
      .send({ fullName: 'Dev Kontec', items: [{ courseId, amount: 150 }] });
    expect(res.status).toBe(201);
    return res.body.payments[0].id as string;
  }

  it('sin sesión devuelve el temario PÚBLICO y sin contenido', async () => {
    const res = await request(buildApp()).get(`/courses/${courseId}/curriculum`);

    expect(res.status).toBe(200);
    expect(res.body.access).toBe('none');
    expect(res.body.totalLessons).toBe(4);
    expect(res.body.completedLessons).toBe(0);

    const lessons = (res.body.modules as Array<{ lessons: unknown[] }>).flatMap(
      (module) => module.lessons,
    ) as Array<{
      contentUrl: string | null;
      contentText: string | null;
      attachmentUrl: string | null;
      isCompleted: boolean;
    }>;
    expect(lessons).toHaveLength(4);
    for (const lesson of lessons) {
      expect(lesson.contentUrl).toBeNull(); // el contenido está gated
      expect(lesson.contentText).toBeNull();
      expect(lesson.attachmentUrl).toBeNull();
      expect(lesson.isCompleted).toBe(false);
    }
  });

  it('con pago PENDIENTE el temario se ve pero el contenido sigue gated', async () => {
    const app = buildApp();
    await solicitarCurso(app);

    const res = await request(app)
      .get(`/courses/${courseId}/curriculum`)
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body.access).toBe('pending');

    const lessons = (res.body.modules as Array<{ lessons: unknown[] }>).flatMap(
      (module) => module.lessons,
    ) as Array<{ contentUrl: string | null }>;
    for (const lesson of lessons) expect(lesson.contentUrl).toBeNull();
  });

  it('tras aprobar el pago el estudiante recibe el contenido', async () => {
    const app = buildApp();
    const paymentId = await solicitarCurso(app);

    const decision = await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set('Authorization', auth)
      .send({ action: 'approve' });
    expect(decision.status).toBe(200);

    const res = await request(app)
      .get(`/courses/${courseId}/curriculum`)
      .set('Authorization', auth);

    expect(res.status).toBe(200);
    expect(res.body.access).toBe('full');

    const lessons = (res.body.modules as Array<{ lessons: unknown[] }>).flatMap(
      (module) => module.lessons,
    ) as Array<{ contentUrl: string | null; contentText: string | null }>;
    // Lección de bienvenida (tipo text): viaja su texto.
    expect(lessons[0]?.contentText).toContain('Bienvenido');
    // El contenido del aula ya viaja (video_url de la BD).
    expect(lessons[1]?.contentUrl).toContain('https://');
  });

  it('el progreso avanza solo con pago aprobado (403 sin aprobar)', async () => {
    const app = buildApp();
    await solicitarCurso(app); // pago quedan PENDIENTE

    const res = await request(app)
      .patch('/lessons/mem-lesson-1/progress')
      .set('Authorization', auth)
      .send({ completed: true });

    expect(res.status).toBe(403);
    expect(res.body.error).toContain('pago');
  });

  it('marca y desmarca lecciones con acceso aprobado', async () => {
    const app = buildApp();
    const paymentId = await solicitarCurso(app);
    await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set('Authorization', auth)
      .send({ action: 'approve' });

    const ok = await request(app)
      .patch('/lessons/mem-lesson-1/progress')
      .set('Authorization', auth)
      .send({ completed: true });
    expect(ok.status).toBe(200);
    expect(ok.body).toEqual({ lessonId: 'mem-lesson-1', isCompleted: true });

    // El currículum refleja el progreso (1 de 3).
    const conProgreso = await request(app)
      .get(`/courses/${courseId}/curriculum`)
      .set('Authorization', auth);
    expect(conProgreso.body.completedLessons).toBe(1);

    const undo = await request(app)
      .patch('/lessons/mem-lesson-1/progress')
      .set('Authorization', auth)
      .send({ completed: false });
    expect(undo.body).toEqual({ lessonId: 'mem-lesson-1', isCompleted: false });

    const sinProgreso = await request(app)
      .get(`/courses/${courseId}/curriculum`)
      .set('Authorization', auth);
    expect(sinProgreso.body.completedLessons).toBe(0);
  });

  it('PATCH /lessons/:id/progress responde 401 sin token', async () => {
    const res = await request(buildApp())
      .patch('/lessons/mem-lesson-1/progress')
      .send({ completed: true });

    expect(res.status).toBe(401);
  });

  it('responde 400 si "completed" no es booleano', async () => {
    const res = await request(buildApp())
      .patch('/lessons/mem-lesson-1/progress')
      .set('Authorization', auth)
      .send({ completed: 'claro que si' });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('completed');
  });

  it('responde 404 si la lección no existe', async () => {
    const res = await request(buildApp())
      .patch('/lessons/no-existe/progress')
      .set('Authorization', auth)
      .send({ completed: true });

    expect(res.status).toBe(404);
  });

  it('responde 404 si el curso no existe', async () => {
    const res = await request(buildApp()).get(
      '/courses/no-existe/curriculum',
    );

    expect(res.status).toBe(404);
  });
});

describe('PANEL — TEMARIO (módulos y lecciones)', () => {
  const auth = { Authorization: 'Bearer token-valido' };
  const courseId = 'a0000000-0000-0000-0000-000000000001';

  /** Temario del panel para el curso demo. */
  const panelCurriculum = (app: ReturnType<typeof buildApp>) =>
    request(app)
      .get(`/admin/courses/${courseId}/curriculum`)
      .set(auth);

  it('devuelve el temario del curso con todas las URLs', async () => {
    const res = await panelCurriculum(buildApp());

    expect(res.status).toBe(200);
    expect(res.body.courseId).toBe(courseId);
    expect(res.body.modules).toHaveLength(2);
    expect(res.body.modules[0]).toMatchObject({
      orderIndex: 1,
      lessons: expect.any(Array),
    });
    // El panel ve el contenido crudo (el aula del alumno lo gatea).
    expect(res.body.modules[0].lessons[0]).toMatchObject({
      videoUrl: expect.stringContaining('https://'),
      zoomUrl: null,
      driveUrl: null,
    });
  });

  it('responde 401 sin token y 404 si el curso no existe', async () => {
    const app = buildApp();

    expect(
      (await request(app).get(`/admin/courses/${courseId}/curriculum`)).status,
    ).toBe(401);
    expect(
      (
        await request(app)
          .get('/admin/courses/no-existe/curriculum')
          .set(auth)
      ).status,
    ).toBe(404);
  });

  it('responde 403 si el usuario no tiene el permiso de la ruta', async () => {
    const res = await request(appWithPermissions(['dashboard:view']))
      .get(`/admin/courses/${courseId}/curriculum`)
      .set(auth);

    expect(res.status).toBe(403);
    expect(res.body.error).toContain('courses:view');
  });

  it('crea módulos con orden consecutivo y valida el título', async () => {
    const app = buildApp();

    const bad = await request(app)
      .post(`/admin/courses/${courseId}/modules`)
      .set(auth)
      .send({ title: '   ' });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toContain('title');

    const created = await request(app)
      .post(`/admin/courses/${courseId}/modules`)
      .set(auth)
      .send({ title: 'Módulo 3: Puentes' });
    expect(created.status).toBe(201);
    // Los 2 sembrados ocupan 1 y 2 → el nuevo va el 3.
    expect(created.body).toMatchObject({ title: 'Módulo 3: Puentes', orderIndex: 3 });

    const again = await request(app)
      .post(`/admin/courses/${courseId}/modules`)
      .set(auth)
      .send({ title: 'Módulo 4: Puertos' });
    expect(again.body.orderIndex).toBe(4);
  });

  it('mueve un módulo con orderIndex y renumera el resto', async () => {
    const app = buildApp();
    const before = (await panelCurriculum(app)).body.modules as Array<{
      id: string;
      orderIndex: number;
    }>;
    const last = before[before.length - 1]!;

    const res = await request(app)
      .patch(`/admin/modules/${last.id}`)
      .set(auth)
      .send({ orderIndex: 1 });

    expect(res.status).toBe(200);

    const after = (await panelCurriculum(app)).body.modules as Array<{
      id: string;
      orderIndex: number;
    }>;
    expect(after[0]!.id).toBe(last.id);
    expect(after.map((module) => module.orderIndex)).toEqual([1, 2]);
  });

  it('crea y edita lecciones validando contentType', async () => {
    const app = buildApp();
    const moduleId = (await panelCurriculum(app)).body.modules[0].id as string;

    const bad = await request(app)
      .post(`/admin/modules/${moduleId}/lessons`)
      .set(auth)
      .send({ title: 'Clase', contentType: 'telepatía' });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toContain('contentType');

    const created = await request(app)
      .post(`/admin/modules/${moduleId}/lessons`)
      .set(auth)
      .send({
        title: 'Clase en vivo',
        contentType: 'live',
        zoomUrl: 'https://zoom.us/j/123',
      });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({
      title: 'Clase en vivo',
      contentType: 'live',
      zoomUrl: 'https://zoom.us/j/123',
      orderIndex: 3,
    });

    // Borrar una URL enviando null.
    const updated = await request(app)
      .patch(`/admin/lessons/${created.body.id}`)
      .set(auth)
      .send({ zoomUrl: null });
    expect(updated.status).toBe(200);
    expect(updated.body.zoomUrl).toBeNull();

    // Mover al principio.
    const moved = await request(app)
      .patch(`/admin/lessons/${created.body.id}`)
      .set(auth)
      .send({ orderIndex: 1 });
    expect(moved.body.orderIndex).toBe(1);
  });

  it('borra una lección y desaparece del temario', async () => {
    const app = buildApp();
    const moduleId = (await panelCurriculum(app)).body.modules[0].id as string;
    const created = await request(app)
      .post(`/admin/modules/${moduleId}/lessons`)
      .set(auth)
      .send({ title: 'Lección desechable', contentType: 'recorded' });

    // El aula del alumno en memoria tiene su propio seed (en producción
    // las dos vistas leen las MISMAS tablas), así que la cascada se
    // verifica contra el temario del panel.
    const before = ((await panelCurriculum(app)).body.modules[0].lessons as unknown[]).length;

    const res = await request(app)
      .delete(`/admin/lessons/${created.body.id}`)
      .set(auth);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ deleted: true });

    const after = await panelCurriculum(app);
    expect((after.body.modules[0].lessons as unknown[]).length).toBe(before - 1);
    expect(
      (after.body.modules[0].lessons as Array<{ id: string }>).some(
        (lesson) => lesson.id === created.body.id,
      ),
    ).toBe(false);
  });

  it('borra un módulo en cascada con sus lecciones', async () => {
    const app = buildApp();
    const moduleId = (await panelCurriculum(app)).body.modules[0].id as string;
    await request(app)
      .post(`/admin/modules/${moduleId}/lessons`)
      .set(auth)
      .send({ title: 'Lección que debe caer', contentType: 'recorded' });

    const before = (await panelCurriculum(app)).body.modules as Array<{
      id: string;
      lessons: Array<{ id: string }>;
    }>;
    const deletedModule = before[0]!;
    const deletedLessonIds = deletedModule.lessons.map((lesson) => lesson.id);
    expect(before).toHaveLength(2);
    expect(deletedLessonIds).toHaveLength(3);

    const res = await request(app)
      .delete(`/admin/modules/${deletedModule.id}`)
      .set(auth);
    expect(res.status).toBe(200);

    const after = (await panelCurriculum(app)).body.modules as Array<{
      id: string;
      lessons: Array<{ id: string }>;
    }>;
    // Ni el módulo ni ninguna de sus lecciones siguen en el temario.
    expect(after).toHaveLength(1);
    expect(after.some((module) => module.id === deletedModule.id)).toBe(false);
    const survivors = after.flatMap((module) => module.lessons.map((l) => l.id));
    for (const lessonId of deletedLessonIds) {
      expect(survivors).not.toContain(lessonId);
    }
  });

  it('responde 404 al editar o borrar lo que no existe', async () => {
    const app = buildApp();

    expect(
      (
        await request(app)
          .patch('/admin/modules/no-existe')
          .set(auth)
          .send({ title: 'X' })
      ).status,
    ).toBe(404);
    expect(
      (await request(app).delete('/admin/modules/no-existe').set(auth)).status,
    ).toBe(404);
    expect(
      (
        await request(app)
          .patch('/admin/lessons/no-existe')
          .set(auth)
          .send({ title: 'X' })
      ).status,
    ).toBe(404);
    expect(
      (await request(app).delete('/admin/lessons/no-existe').set(auth)).status,
    ).toBe(404);
  });
});

describe('PANEL — participantes, perfil del estudiante y acceso', () => {
  const auth = { Authorization: 'Bearer token-valido' };
  const courseId = 'a0000000-0000-0000-0000-000000000001';
  const studentId = 'mem-user-1';

  /** Sembra una inscripción (pending_payment) vía checkout. */
  async function inscribir(app: ReturnType<typeof buildApp>) {
    const res = await request(app)
      .post('/checkout')
      .set(auth)
      .send({
        fullName: 'Carla Quispe',
        email: 'carla@ejemplo.com',
        phone: '999888777',
        nationality: 'Peruana',
        items: [{ courseId, amount: 150 }],
      });
    expect(res.status).toBe(201);
  }

  // ── GET /admin/courses/:id/participants ──────────────────────

  it('participantes responde 401 sin token', async () => {
    const res = await request(buildApp()).get(
      `/admin/courses/${courseId}/participants`,
    );

    expect(res.status).toBe(401);
  });

  it('participantes lista nombre, correo, estado y fecha de inscripción', async () => {
    const app = buildApp();
    await inscribir(app);

    const res = await request(app)
      .get(`/admin/courses/${courseId}/participants`)
      .set(auth);

    expect(res.status).toBe(200);
    expect(res.body.courseId).toBe(courseId);
    expect(res.body.courseTitle).toBe(
      'Diseño Avanzado de Estructuras de Concreto Armado',
    );
    expect(res.body.participants).toHaveLength(1);
    expect(res.body.participants[0]).toMatchObject({
      userId: studentId,
      fullName: 'Carla Quispe',
      email: 'carla@ejemplo.com',
      status: 'pending_payment',
    });
    expect(typeof res.body.participants[0].enrolledAt).toBe('string');
  });

  it('participantes responde 404 si el curso no existe', async () => {
    const res = await request(buildApp())
      .get('/admin/courses/no-existe/participants')
      .set(auth);

    expect(res.status).toBe(404);
  });

  // ── GET /admin/students/:id ──────────────────────────────────

  it('perfil responde 401 sin token', async () => {
    const res = await request(buildApp()).get(
      `/admin/students/${studentId}`,
    );

    expect(res.status).toBe(401);
  });

  it('perfil devuelve datos del estudiante + sus inscripciones', async () => {
    const app = buildApp();
    await inscribir(app);

    const res = await request(app)
      .get(`/admin/students/${studentId}`)
      .set(auth);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      id: studentId,
      fullName: 'Carla Quispe',
      email: 'carla@ejemplo.com',
      nationality: 'Peruana',
      isActive: true,
    });
    expect(res.body.enrollments).toHaveLength(1);
    expect(res.body.enrollments[0]).toMatchObject({
      courseId,
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      status: 'pending_payment',
    });
  });

  it('perfil responde 404 si el estudiante no existe', async () => {
    const res = await request(buildApp())
      .get('/admin/students/no-existe')
      .set(auth);

    expect(res.status).toBe(404);
  });

  // ── PATCH /admin/students/:studentId/enrollments/:courseId ───

  it('acceso responde 401 sin token', async () => {
    const res = await request(buildApp())
      .patch(`/admin/students/${studentId}/enrollments/${courseId}`)
      .send({ action: 'revoke' });

    expect(res.status).toBe(401);
  });

  it('acceso responde 400 si la acción no es válida', async () => {
    const res = await request(buildApp())
      .patch(`/admin/students/${studentId}/enrollments/${courseId}`)
      .set(auth)
      .send({ action: 'borrar' });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('action');
  });

  it('acceso responde 404 si el estudiante no está inscrito', async () => {
    const res = await request(buildApp())
      .patch(`/admin/students/${studentId}/enrollments/no-existe`)
      .set(auth)
      .send({ action: 'revoke' });

    expect(res.status).toBe(404);
  });

  it('quitar acceso deja la inscripción en revoked y restaurar en approved', async () => {
    const app = buildApp();
    await inscribir(app);

    // Quitar acceso → 'revoked' (sin acceso al aula).
    const revoke = await request(app)
      .patch(`/admin/students/${studentId}/enrollments/${courseId}`)
      .set(auth)
      .send({ action: 'revoke' });
    expect(revoke.status).toBe(200);
    expect(revoke.body).toEqual({
      userId: studentId,
      courseId,
      status: 'revoked',
    });

    // El perfil refleja el nuevo estado.
    const perfil = await request(app)
      .get(`/admin/students/${studentId}`)
      .set(auth);
    expect(perfil.body.enrollments[0].status).toBe('revoked');

    // El aula del estudiante queda SIN contenido (solo approved/finished
    // dan acceso).
    const aula = await request(app)
      .get(`/courses/${courseId}/curriculum`)
      .set(auth);
    expect(aula.body.access).toBe('none');

    // Restaurar → 'approved' (vuelve a tener acceso).
    const restore = await request(app)
      .patch(`/admin/students/${studentId}/enrollments/${courseId}`)
      .set(auth)
      .send({ action: 'restore' });
    expect(restore.status).toBe(200);
    expect(restore.body.status).toBe('approved');
  });
});

describe('CUENTA — GET /me/profile (perfil propio)', () => {
  const auth = { Authorization: 'Bearer token-valido' };
  const courseId = 'a0000000-0000-0000-0000-000000000001';

  it('responde 401 sin token', async () => {
    const res = await request(buildApp()).get('/me/profile');
    expect(res.status).toBe(401);
  });

  it('con fila en public.users devuelve datos + inscripciones', async () => {
    const app = buildApp();
    // El checkout crea la fila del usuario (public.users) y la
    // inscripción, igual que en producción.
    await request(app)
      .post('/checkout')
      .set(auth)
      .send({
        fullName: 'Carla Quispe',
        email: 'carla@ejemplo.com',
        nationality: 'Peruana',
        items: [{ courseId, amount: 150 }],
      });

    const res = await request(app).get('/me/profile').set(auth);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      id: 'mem-user-1',
      fullName: 'Carla Quispe',
      email: 'carla@ejemplo.com',
      nationality: 'Peruana',
    });
    expect(res.body.enrollments).toHaveLength(1);
    expect(res.body.enrollments[0]).toMatchObject({ courseId });
  });

  it('registro directo (sin compra) devuelve perfil mínimo con el email', async () => {
    const res = await request(buildApp()).get('/me/profile').set(auth);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      id: 'mem-user-1',
      email: 'dev@kontec.pe',
      fullName: '',
      isActive: true,
    });
    expect(res.body.enrollments).toEqual([]);
  });
});

describe('RBAC — requirePermission por ruta', () => {
  const auth = { Authorization: 'Bearer token-valido' };

  it('GET /admin/payments exige payments:view', async () => {
    const denied = await request(appWithPermissions([]))
      .get('/admin/payments')
      .set(auth);
    expect(denied.status).toBe(403);
    expect(denied.body.error).toContain('payments:view');

    const allowed = await request(appWithPermissions(['payments:view']))
      .get('/admin/payments')
      .set(auth);
    expect(allowed.status).toBe(200);
  });

  it('GET /admin/stats exige dashboard:view', async () => {
    expect(
      (await request(appWithPermissions(['payments:view'])).get('/admin/stats').set(auth))
        .status,
    ).toBe(403);

    expect(
      (await request(appWithPermissions(['dashboard:view'])).get('/admin/stats').set(auth))
        .status,
    ).toBe(200);
  });

  it('GET /admin/users exige users:view', async () => {
    expect(
      (await request(appWithPermissions(['dashboard:view'])).get('/admin/users').set(auth))
        .status,
    ).toBe(403);

    expect(
      (await request(appWithPermissions(['users:view'])).get('/admin/users').set(auth))
        .status,
    ).toBe(200);
  });

  it('PATCH /admin/payments/:id exige payments:approve (ver no es decidir)', async () => {
    const readOnly = await request(appWithPermissions(['payments:view']))
      .patch('/admin/payments/pago-inexistente')
      .set(auth)
      .send({ action: 'approve' });
    expect(readOnly.status).toBe(403);
    expect(readOnly.body.error).toContain('payments:approve');

    // Con el permiso pasa el guard: el 404 es del pago, no del guard.
    const withApprove = await request(appWithPermissions(['payments:approve']))
      .patch('/admin/payments/pago-inexistente')
      .set(auth)
      .send({ action: 'approve' });
    expect(withApprove.status).toBe(404);
  });
});

describe('ADMIN/ROLES — matriz de permisos', () => {
  const auth = { Authorization: 'Bearer token-valido' };

  /** Lee la matriz con la app en memoria (siempre admin). */
  async function loadMatrix(app = buildApp()) {
    const res = await request(app).get('/admin/roles').set(auth);
    expect(res.status).toBe(200);
    return { app, body: res.body as RolesMatrixBody };
  }

  it('401 sin sesión y 403 sin el permiso roles:manage', async () => {
    expect((await request(buildApp()).get('/admin/roles')).status).toBe(401);

    const denied = await request(appWithPermissions(['users:view']))
      .get('/admin/roles')
      .set(auth);
    expect(denied.status).toBe(403);
    expect(denied.body.error).toContain('roles:manage');
  });

  it('devuelve roles, permisos y grants (admin siempre completo)', async () => {
    const { body } = await loadMatrix();

    expect(body.roles.map((role) => role.name)).toEqual(
      expect.arrayContaining(['admin', 'teacher', 'student']),
    );
    expect(body.permissions.length).toBeGreaterThanOrEqual(12);
    expect(body.grants.admin).toEqual(
      body.permissions.map((permission) => permission.code),
    );
    expect(body.grants.teacher).toEqual(
      expect.arrayContaining(['courses:view']),
    );

    const teacher = body.roles.find((role) => role.name === 'teacher');
    expect(teacher?.system).toBe(true);
  });

  it('PUT reemplaza los grants y rechaza códigos desconocidos', async () => {
    const { app, body } = await loadMatrix();
    const teacher = body.roles.find((role) => role.name === 'teacher');
    expect(teacher).toBeDefined();

    const bad = await request(app)
      .put(`/admin/roles/${teacher!.id}/permissions`)
      .set(auth)
      .send({ codes: ['no:existe'] });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toContain('no:existe');

    const ok = await request(app)
      .put(`/admin/roles/${teacher!.id}/permissions`)
      .set(auth)
      .send({ codes: ['payments:view', 'students:view'] });
    expect(ok.status).toBe(200);
    expect(ok.body).toEqual({ updated: true });

    const after = await request(app).get('/admin/roles').set(auth);
    expect(after.body.grants.teacher).toEqual([
      'payments:view',
      'students:view',
    ]);
  });

  it('el rol admin es inmutable (no se puede vaciar)', async () => {
    const { app, body } = await loadMatrix();
    const admin = body.roles.find((role) => role.name === 'admin');

    const res = await request(app)
      .put(`/admin/roles/${admin!.id}/permissions`)
      .set(auth)
      .send({ codes: [] });
    expect(res.status).toBe(400);
    expect(res.body.error).toContain('admin');
  });

  it('POST crea roles y valida formato y duplicados', async () => {
    const { app } = await loadMatrix();

    const invalid = await request(app)
      .post('/admin/roles')
      .set(auth)
      .send({ name: 'Nombre Malo' });
    expect(invalid.status).toBe(400);

    const created = await request(app)
      .post('/admin/roles')
      .set(auth)
      .send({ name: 'Coordinador', description: 'Coordina cursos' });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({
      name: 'coordinador',
      description: 'Coordina cursos',
      system: false,
      userCount: 0,
    });

    const duplicated = await request(app)
      .post('/admin/roles')
      .set(auth)
      .send({ name: 'coordinador' });
    expect(duplicated.status).toBe(400);
    expect(duplicated.body.error).toContain('ya existe');
  });

  it('DELETE protege los roles base y borra los creados', async () => {
    const { app, body } = await loadMatrix();
    const teacher = body.roles.find((role) => role.name === 'teacher');

    const base = await request(app)
      .delete(`/admin/roles/${teacher!.id}`)
      .set(auth);
    expect(base.status).toBe(400);

    const missing = await request(app)
      .delete('/admin/roles/rol-inexistente')
      .set(auth);
    expect(missing.status).toBe(404);

    const created = await request(app)
      .post('/admin/roles')
      .set(auth)
      .send({ name: 'temporal' });
    const deleted = await request(app)
      .delete(`/admin/roles/${created.body.id}`)
      .set(auth);
    expect(deleted.status).toBe(200);
    expect(deleted.body).toEqual({ deleted: true });

    const after = await request(app).get('/admin/roles').set(auth);
    const names = (after.body as RolesMatrixBody).roles.map(
      (role) => role.name,
    );
    expect(names).not.toContain('temporal');
  });
});

/** Shape de GET /admin/roles (para no tipar supertest a mano). */
interface RolesMatrixBody {
  roles: Array<{
    id: string;
    name: string;
    description: string;
    userCount: number;
    system: boolean;
  }>;
  permissions: Array<{ code: string; description: string }>;
  grants: Record<string, string[]>;
}
