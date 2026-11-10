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
import { InMemoryRolesRepository } from '../src/data/in-memory-roles-repository.js';
import { InMemoryTodoRepository } from '../src/data/in-memory-todo-repository.js';

/** Token que el repo en memoria acepta (mismo que app.test.ts). */
const AUTH = { Authorization: 'Bearer token-valido' };

/** Curso sembrado en InMemoryCatalogRepository (para setCourses). */
const COURSE_ID = 'a0000000-0000-0000-0000-000000000001';

function buildApp(codes: string[] | null = null) {
  const todos = new InMemoryTodoRepository();
  const catalog = new InMemoryCatalogRepository();
  const checkout = new InMemoryCheckoutRepository(catalog);
  const admin = new InMemoryAdminRepository(checkout, catalog);
  const cart = new InMemoryCartRepository(catalog);
  const curriculum = new InMemoryCurriculumRepository(catalog, checkout);
  const roles = new InMemoryRolesRepository();
  const paths = new InMemoryLearningPathRepository(catalog);

  // codes = null → auth real (en memoria hace bypass de admin);
  // codes = lista → auth mockeado con EXACTAMENTE esos permisos
  // (necesario para probar los guards 403).
  const auth =
    codes === null
      ? checkout
      : {
          verifyToken: async () => ({ id: 'u1', email: 'editor@ejemplo.com' }),
          getRoles: async () => ['teacher'],
          getPermissions: async () => codes,
        };

  return createApp({
    auth,
    ...createUseCases({
      todos,
      catalog,
      checkout,
      admin,
      cart,
      curriculum,
      roles,
      paths,
    }),
  });
}

describe('GET /paths', () => {
  it('responde 200 con la lista (vacía al inicio)', async () => {
    const res = await request(buildApp()).get('/paths');

    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it('solo muestra rutas publicadas', async () => {
    const app = buildApp();
    await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta borrador', isPublished: false });
    await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta pública', isPublished: true });

    const publicas = await request(app).get('/paths');
    const admin = await request(app).get('/admin/paths').set(AUTH);

    expect(publicas.body).toHaveLength(1);
    expect(publicas.body[0].title).toBe('Ruta pública');
    expect(admin.body).toHaveLength(2);
  });
});

describe('POST /admin/paths', () => {
  it('crea 201 con slug derivado del título', async () => {
    const res = await request(buildApp())
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Estructuras y diseño' });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      title: 'Estructuras y diseño',
      slug: 'estructuras-y-diseno',
      isPublished: true,
      accessMonths: 12,
      courses: [],
    });
  });

  it('rechaza 400 sin título', async () => {
    const res = await request(buildApp())
      .post('/admin/paths')
      .set(AUTH)
      .send({});

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('title');
  });

  it('rechaza 403 sin el permiso courses:create', async () => {
    const res = await request(buildApp(['dashboard:view']))
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'No autorizada' });

    expect(res.status).toBe(403);
    expect(res.body.error).toContain('courses:create');
  });
});

describe('GET /paths/:slug', () => {
  it('devuelve la ruta publicada por slug', async () => {
    const app = buildApp();
    await request(app).post('/admin/paths').set(AUTH).send({ title: 'Ruta BIM' });

    const res = await request(app).get('/paths/ruta-bim');

    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Ruta BIM');
  });

  it('responde 404 para slug inexistente', async () => {
    const res = await request(buildApp()).get('/paths/no-existe');

    expect(res.status).toBe(404);
  });
});

describe('PATCH /admin/paths/:id', () => {
  it('edita la cabecera y devuelve 404 si no existe', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Original' });

    const ok = await request(app)
      .patch(`/admin/paths/${creada.body.id}`)
      .set(AUTH)
      .send({ title: 'Renombrada', isPublished: false });

    expect(ok.status).toBe(200);
    expect(ok.body.title).toBe('Renombrada');
    expect(ok.body.isPublished).toBe(false);

    const missing = await request(app)
      .patch('/admin/paths/00000000-0000-0000-0000-000000000000')
      .set(AUTH)
      .send({ title: 'X' });
    expect(missing.status).toBe(404);
  });
});

describe('PUT /admin/paths/:id/courses', () => {
  it('reemplaza los cursos con orden y nivel (duración derivada)', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta con cursos' });

    const res = await request(app)
      .put(`/admin/paths/${creada.body.id}/courses`)
      .set(AUTH)
      .send({
        courses: [{ courseId: COURSE_ID, level: 'Introductorio' }],
      });

    expect(res.status).toBe(200);
    expect(res.body.courses).toHaveLength(1);
    expect(res.body.courses[0]).toMatchObject({
      courseId: COURSE_ID,
      level: 'Introductorio',
      sortOrder: 0,
      title: 'Diseño Avanzado de Estructuras de Concreto Armado',
      // El sembrado tiene price150 / compareAtPrice200 → sin oferta
      // válida (200 >150) el precio efectivo es150.
      price: 150,
    });
    // El curso sembrado tiene40h → la duración de la ruta se deriva.
    expect(res.body.durationHours).toBe(40);
    // Sin % de rebaja el precio final es el total de referencia.
    expect(res.body.discountPercent).toBe(0);
    expect(res.body.totalCoursesPrice).toBe(150);
    expect(res.body.price).toBe(150);
  });

  it('aplica el % de rebaja sobre el total de precios efectivos', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta con rebaja', discountPercent: 20 });

    expect(creada.status).toBe(201);
    expect(creada.body.discountPercent).toBe(20);

    const res = await request(app)
      .put(`/admin/paths/${creada.body.id}/courses`)
      .set(AUTH)
      .send({ courses: [{ courseId: COURSE_ID, level: 'Intermedio' }] });

    expect(res.status).toBe(200);
    // Total =150 (efectivo) → con -20% →120.
    expect(res.body.totalCoursesPrice).toBe(150);
    expect(res.body.price).toBe(120);
  });

  it('rechaza400 con discountPercent fuera de rango', async () => {
    const res = await request(buildApp())
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Rebaja loca', discountPercent: 150 });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('discountPercent');
  });

  it('acepta lista vacía (ruta sin cursos)', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta vacía' });

    const res = await request(app)
      .put(`/admin/paths/${creada.body.id}/courses`)
      .set(AUTH)
      .send({ courses: [] });

    expect(res.status).toBe(200);
    expect(res.body.courses).toEqual([]);
    expect(res.body.durationHours).toBe(0);
  });

  it('responde 400 con nivel inválido o curso inexistente', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Ruta validada' });

    const malNivel = await request(app)
      .put(`/admin/paths/${creada.body.id}/courses`)
      .set(AUTH)
      .send({ courses: [{ courseId: COURSE_ID, level: 'Experto' }] });
    expect(malNivel.status).toBe(400);

    const cursoRaro = await request(app)
      .put(`/admin/paths/${creada.body.id}/courses`)
      .set(AUTH)
      .send({ courses: [{ courseId: 'ffffffff-0000-0000-0000-000000000000' }] });
    expect(cursoRaro.status).toBe(400);
    expect(cursoRaro.body.error).toContain('no existe en el catálogo');
  });

  it('responde 404 si la ruta no existe', async () => {
    const res = await request(buildApp())
      .put('/admin/paths/00000000-0000-0000-0000-000000000000/courses')
      .set(AUTH)
      .send({ courses: [] });

    expect(res.status).toBe(404);
  });
});

describe('DELETE /admin/paths/:id', () => {
  it('borra la ruta y después da 404 al buscarla', async () => {
    const app = buildApp();
    const creada = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Para borrar' });

    const del = await request(app)
      .delete(`/admin/paths/${creada.body.id}`)
      .set(AUTH);
    expect(del.status).toBe(200);
    expect(del.body).toEqual({ deleted: true });

    const trasBorrar = await request(app).get('/paths/para-borrar');
    expect(trasBorrar.status).toBe(404);

    const otraVez = await request(app)
      .delete(`/admin/paths/${creada.body.id}`)
      .set(AUTH);
    expect(otraVez.status).toBe(404);
  });

  it('rechaza 403 sin el permiso courses:create', async () => {
    const res = await request(buildApp(['courses:view']))
      .delete('/admin/paths/00000000-0000-0000-0000-000000000000')
      .set(AUTH);

    expect(res.status).toBe(403);
  });
});
