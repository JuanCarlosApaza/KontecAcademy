import cors from 'cors';
import express, {
  type NextFunction,
  type Request,
  type Response,
} from 'express';
import type { TodoRepository } from './domain/todo.js';

/**
 * 🎨 Composición de la API: CORS, JSON, rutas y manejo de errores.
 * No contiene lógica de negocio: solo ensambla.
 */
export function createApp(repository: TodoRepository): express.Express {
  const app = express();

  // CORS: permite al frontend (otro origen/puerto) llamar a la API.
  // En producción, restringe al dominio real:
  //   app.use(cors({ origin: ['https://tudominio.com'] }));
  app.use(cors());
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
  app.get('/todos', (_req, res) => {
    res.json(repository.findAll());
  });

  // POST /todos — crea una tarea  {"title": "..."}
  app.post('/todos', (req, res) => {
    const body = req.body as { title?: unknown };
    const title = typeof body?.title === 'string' ? body.title.trim() : '';

    if (title.length === 0) {
      res.status(400).json({ error: 'El campo "title" es obligatorio' });
      return;
    }

    res.status(201).json(repository.create(title));
  });

  // 404 — ruta desconocida
  app.use((_req, res) => {
    res.status(404).json({ error: 'Ruta no encontrada' });
  });

  // Errores: JSON inválido u otros → respuesta JSON controlada
  app.use(
    (err: unknown, _req: Request, res: Response, next: NextFunction) => {
      if (res.headersSent) {
        next(err);
        return;
      }
      const status =
        typeof err === 'object' && err !== null && 'status' in err
          ? Number((err as { status: unknown }).status)
          : 500;
      const isBadRequest = status >= 400 && status < 500;
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
