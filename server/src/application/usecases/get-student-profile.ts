import type {
  AdminRepository,
  StudentProfile,
} from '../../domain/admin.js';

/** Caso de uso: perfil de un estudiante + sus inscripciones. */
export class GetStudentProfile {
  constructor(
    private readonly admin: Pick<AdminRepository, 'getStudentProfile'>,
  ) {}

  /** null = el estudiante no existe (la ruta responde 404). */
  execute(studentId: string): Promise<StudentProfile | null> {
    return this.admin.getStudentProfile(studentId);
  }
}
