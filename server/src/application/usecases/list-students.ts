import type {
  AdminRepository,
  StudentRecord,
} from '../../domain/admin.js';

/** Caso de uso: listar estudiantes (usuarios) + cursos inscritos. */
export class ListStudents {
  constructor(
    private readonly admin: Pick<AdminRepository, 'findStudents'>,
  ) {}

  execute(): Promise<StudentRecord[]> {
    return this.admin.findStudents();
  }
}
