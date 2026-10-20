import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app.js';
import { InMemoryTodoRepository } from '../src/data/in-memory-todo-repository.js';

function buildApp() {
  return createApp(new InMemoryTodoRepository());
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
