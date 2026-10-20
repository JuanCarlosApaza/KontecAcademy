import { createApp } from './app.js';
import { InMemoryTodoRepository } from './data/in-memory-todo-repository.js';

const port = Number(process.env.PORT ?? 3000);

// Ensamblado (composition root): aquí se decide qué implementación usa la API.
const repository = new InMemoryTodoRepository();
const app = createApp(repository);

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`🚀 Kontec API escuchando en http://localhost:${port}`);
});
