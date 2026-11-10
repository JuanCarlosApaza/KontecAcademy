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

/** Plan anual sembrado en InMemoryMembershipRepository. */
const ANNUAL_PLAN_ID = 'mem-plan-anual';

function buildApp() {
  const todos = new InMemoryTodoRepository();
  const catalog = new InMemoryCatalogRepository();
  const paths = new InMemoryLearningPathRepository(catalog);
  const memberships = new InMemoryMembershipRepository();
  const checkout = new InMemoryCheckoutRepository(catalog, paths, memberships);
  const admin = new InMemoryAdminRepository(checkout, catalog);
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

describe('planes de membresía (CRUD del panel)', () => {
  it('lista los3 planes activos, crea, edita y borra', async () => {
    const app = buildApp();

    // Público: solo activos (los sembrados).
    const publicPlans = await request(app).get('/membership-plans');
    expect(publicPlans.status).toBe(200);
    expect(publicPlans.body).toHaveLength(3);
    expect(publicPlans.body.map((p: { slug: string }) => p.slug)).toEqual([
      'mensual',
      'semestral',
      'anual',
    ]);

    // Alta con slug derivado del nombre.
    const created = await request(app)
      .post('/admin/membership-plans')
      .set(AUTH)
      .send({ name: 'Plan VIP', months: 3, price: 99 });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({
      slug: 'plan-vip',
      months: 3,
      price: 99,
      isActive: true,
    });

    // Edición.
    const updated = await request(app)
      .patch(`/admin/membership-plans/${created.body.id}`)
      .set(AUTH)
      .send({ name: 'Plan VIP', months: 3, price: 89, isActive: false });
    expect(updated.status).toBe(200);
    expect(updated.body.price).toBe(89);
    expect(updated.body.isActive).toBe(false);

    // El público ya no lo ve (inactivo) pero el panel sí.
    const publicAfter = await request(app).get('/membership-plans');
    expect(publicAfter.body).toHaveLength(3);
    const adminList = await request(app)
      .get('/admin/membership-plans')
      .set(AUTH);
    expect(adminList.body).toHaveLength(4);

    // Borrado.
    const deleted = await request(app)
      .delete(`/admin/membership-plans/${created.body.id}`)
      .set(AUTH);
    expect(deleted.status).toBe(200);
    const missing = await request(app)
      .delete(`/admin/membership-plans/${created.body.id}`)
      .set(AUTH);
    expect(missing.status).toBe(404);
  });
});

describe('compra de MEMBRESÍA de punta a punta', () => {
  it('carrito → checkout pendiente → aprobación activa → acceso total', async () => {
    const app = buildApp();

    // 1) Carrito con el plan como ítem tipado.
    const putCart = await request(app)
      .put('/cart')
      .set(AUTH)
      .send({ items: [{ courseId: ANNUAL_PLAN_ID, type: 'membership' }] });
    expect(putCart.status).toBe(200);

    const cart = await request(app).get('/cart').set(AUTH);
    expect(cart.status).toBe(200);
    expect(cart.body).toHaveLength(1);
    expect(cart.body[0]).toMatchObject({
      courseId: ANNUAL_PLAN_ID,
      itemType: 'membership',
      title: 'Anual',
      price: 249,
      modality: 'Membresía',
    });

    // 2) Checkout: memberships pending + UN pago, sin enrollments.
    const checkout = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Socio Anual',
        items: [{ courseId: ANNUAL_PLAN_ID, amount: 249, type: 'membership' }],
      });
    expect(checkout.status).toBeLessThan(300);
    expect(checkout.body.enrollments).toHaveLength(0);
    expect(checkout.body.payments).toHaveLength(1);
    expect(checkout.body.total).toBe(249);

    const paymentId = checkout.body.payments[0].id as string;

    // Sin aprobar: sin membresía activa y sin acceso.
    const myMembershipPending = await request(app)
      .get('/my/membership')
      .set(AUTH);
    expect(myMembershipPending.status).toBe(200);
    expect(myMembershipPending.body).toBeNull();

    const gated = await request(app)
      .get(`/courses/${COURSE_ID}/curriculum`)
      .set(AUTH);
    expect(gated.status).toBe(200);
    expect(gated.body.access).toBe('none');

    // Doble compra bloqueada (pendiente).
    const duplicate = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Socio Anual',
        items: [{ courseId: ANNUAL_PLAN_ID, amount: 249, type: 'membership' }],
      });
    expect(duplicate.status).toBe(400);
    expect(duplicate.body.error).toContain('verificación');

    // 3) El admin aprueba el ticket → membresía ACTIVA con fechas.
    const decision = await request(app)
      .patch(`/admin/payments/${paymentId}`)
      .set(AUTH)
      .send({ action: 'approve' });
    expect(decision.status).toBe(200);

    const myMembership = await request(app)
      .get('/my/membership')
      .set(AUTH);
    expect(myMembership.status).toBe(200);
    expect(myMembership.body).toMatchObject({
      planName: 'Anual',
      status: 'active',
      months: 12,
    });
    expect(myMembership.body.startDate).toBeTruthy();
    expect(myMembership.body.endDate).toBeTruthy();
    // Vigencia anual: fin > hoy y al menos ~11 meses de diferencia.
    const start = new Date(myMembership.body.startDate as string);
    const end = new Date(myMembership.body.endDate as string);
    const months =
      (end.getFullYear() - start.getFullYear()) * 12 +
      (end.getMonth() - start.getMonth());
    expect(months).toBeGreaterThanOrEqual(11);

    // 4) ACCESO TOTAL: el aula responde 'full' sin inscripción.
    const curriculum = await request(app)
      .get(`/courses/${COURSE_ID}/curriculum`)
      .set(AUTH);
    expect(curriculum.status).toBe(200);
    expect(curriculum.body.access).toBe('full');

    // "Mis cursos" = TODO el catálogo con status 'membership'.
    const myCourses = await request(app).get('/my/courses').set(AUTH);
    expect(myCourses.status).toBe(200);
    expect(myCourses.body.length).toBeGreaterThanOrEqual(1);
    expect(
      myCourses.body.every(
        (course: { status: string }) => course.status === 'membership',
      ),
    ).toBe(true);

    // Comprar un curso suelto con membresía activa → bloqueado.
    const buyCourse = await request(app)
      .post('/checkout')
      .set(AUTH)
      .send({
        fullName: 'Socio Anual',
        items: [{ courseId: COURSE_ID, amount: 150, type: 'course' }],
      });
    expect(buyCourse.status).toBe(400);
    expect(buyCourse.body.error).toContain('membresía activa');

    // 5) Revocar desde el panel → el acceso vuelve a 'none'.
    const memberships = await request(app)
      .get('/admin/memberships')
      .set(AUTH);
    expect(memberships.status).toBe(200);
    expect(memberships.body).toHaveLength(1);
    const membershipId = memberships.body[0].id as string;

    const revoke = await request(app)
      .patch(`/admin/memberships/${membershipId}`)
      .set(AUTH)
      .send({ status: 'revoked' });
    expect(revoke.status).toBe(200);
    expect(revoke.body.status).toBe('revoked');

    const afterRevoke = await request(app)
      .get(`/courses/${COURSE_ID}/curriculum`)
      .set(AUTH);
    expect(afterRevoke.body.access).toBe('none');
  });
});

describe('alta manual de membresía desde el panel', () => {
  it('otorga una activa calculando fechas desde hoy + meses del plan', async () => {
    const app = buildApp();

    const granted = await request(app)
      .post('/admin/memberships')
      .set(AUTH)
      .send({ userId: 'mem-user-9', planId: 'mem-plan-mensual' });
    expect(granted.status).toBe(201);
    expect(granted.body).toMatchObject({
      planName: 'Mensual',
      months: 1,
      status: 'active',
    });
    expect(granted.body.startDate).toBeTruthy();
    expect(granted.body.endDate).toBeTruthy();

    // Plan inexistente →400.
    const bad = await request(app)
      .post('/admin/memberships')
      .set(AUTH)
      .send({ userId: 'mem-user-9', planId: 'no-existe' });
    expect(bad.status).toBe(400);
  });
});
