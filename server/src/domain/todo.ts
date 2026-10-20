/**
 * 🧠 DOMINIO — lenguaje del negocio.
 * Sin dependencias de Express, ni base de datos, ni frameworks.
 * (Equivalente a lib/features/tasks/domain/entities/task.dart del front)
 */
export interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

/**
 * Contrato de acceso a datos. Los route handlers solo ven esta interfaz:
 * cambiar a MySQL/Postgres obliga a implementar esta interfaz, no a tocar rutas.
 * (Equivalente a domain/repositories/task_repository.dart del front)
 */
export interface TodoRepository {
  findAll(): Todo[];
  findById(id: number): Todo | undefined;
  create(title: string): Todo;
}
