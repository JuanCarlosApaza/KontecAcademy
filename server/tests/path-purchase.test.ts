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

/** Token que el repo en memoria acepta (mismo que app.test.ts). */
const AUTH = { Authorization: 'Bearer token-valido' };

/** Curso sembrado en InMemoryCatalogRepository. */
const COURSE_ID = 'a0000000-0000-0000-0000-000000000001';

function buildApp() {
  const todos = new InMemoryTodoRepository();
  const catalog = new InMemoryCatalogRepository();
  const paths = new InMemoryLearningPathRepository(catalog);
  const memberships = new InMemoryMembershipRepository();
  const checkout = new InMemoryCheckoutRepository(catalog, paths, memberships);
  const admin = new InMemoryAdminRepository(checkout, catalog);
  const cart = new InMemoryCartRepository(catalog, paths, memberships);
  const curriculum = new InMemoryCurriculumRepository(catalog, checkout, memberships);
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

describe('compra de RUTA (combo) de punta a punta', () => {
  it('carrito tipado → checkout expande la ruta → aprobación masiva', async () => {
    const app = buildApp();

    // 1) Segundo curso para que la ruta tenga2 (el catálogo siembra1).
    const curso2 = await request(app)
      .post('/courses')
      .set(AUTH)
      .send({
        title: 'Curso extra del combo',
        description: null,
        imageUrl: null,
        categoryId: null,
        modality: 'asynchronous',
        totalHours: 20,
        totalWeeks: null,
        price: 80,
        compareAtPrice: null,
        status: 'active',
        professorBio: null,
        teachingMethod: null,
        targetAudience: null,
        certificateInfo: null,
        careerOpportunities: null,
      });
    expect(curso2.status).toBe(201);
    const course2Id = curso2.body.id as string;

    // 2) Ruta con -20% y los2 cursos (total efectivo150 +80 =230).
    const ruta = await request(app)
      .post('/admin/paths')
      .set(AUTH)
      .send({ title: 'Combo total', discountPercent: 20 });
    expect(ruta.status).toBe(201);
    const pathId = ruta.body.id as string;

    const setCursos = await request(app)
      .put(`/admin/paths/${pathId}/courses`)
      .set(AUTH)
      .send({
        courses: [
          { courseId: COURSE_ID, level: 'Introductorio' },
          { courseId: course2Id, level: 'Intermedio' },
        ],
      });
    expect(setCursos.status).toBe(200);
    expect(setCursos.body.totalCoursesPrice).toBe(230);
    expect(setCursos.body.price).toBe(184); //230 −20%

    // 3) Carrito con la ruta como UN ítem tipado.
    const putCart = await request(app)
      .put('/cart')
      .set(AUTH)
      .send({ items: [{ courseId: pathId, type: 'path' }] });
    expect(putCart.status).toBe(200);
    expect(putCart.body.count).toBe(1);

    const cart = await request(app).get('/cart').set(AUTH);
    expect(cart.status).toBe(200);
    expect(cart.body).toHaveLength(1);
    expect(cart.body[0]).toMatchObject({
      courseId: pathId,
      itemType: 'path',
      title: 'Combo total',
      price: 184, // precio del combo ya con la rebaja, resuelto en el server
    });

    // 4) Checkout del combo: N enrollments + UN pago por184.
    const checkout = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Estudiante Combo',
        items: [{ courseId: pathId, amount:184, type: 'path' }],
      });
    expect(checkout.status, JSON.stringify(checkout.body)).toBeLessThan(300);
    expect(checkout.body.enrollments).toHaveLength(2);
    expect(checkout.body.payments).toHaveLength(1);
    expect(checkout.body.total).toBe(184);

    const paymentId = checkout.body.payments[0].id as string;

    //5) Estado negativo: con el pago pendiente no se puede volver a comprar.
    const duplicado = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Estudiante Combo',
        items: [{ courseId: pathId, amount:184, type: 'path' }],
      });
    expect(duplicado.status).toBe(400);
    expect(duplicado.body.error).toContain('pago en verificación');

    //6) El admin aprueba UN ticket → los N cursos quedan 'approved'.
    const decision = await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set(AUTH)
      .send({ action: 'approve' });
    expect(decision.status).toBe(200);

    const misCursos = await request(app).get('/my/courses').set(AUTH);
    expect(misCursos.status).toBe(200);
    expect(misCursos.body).toHaveLength(2);
    for (const course of misCursos.body) {
      expect(course.status).toBe('approved');
    }

    //7) Con todo aprobado, el checkout del combo queda bloqueado.
    const yaInscrito = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Estudiante Combo',
        items: [{ courseId: pathId, amount:184, type: 'path' }],
      });
    expect(yaInscrito.status).toBe(400);
    expect(yaInscrito.body.error).toContain('aprobado');
  });
});
