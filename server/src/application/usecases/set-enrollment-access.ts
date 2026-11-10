import type { CheckoutRepository } from '../../domain/checkout.js';
import {
  STATUS_OF_ACCESS_ACTION,
  type EnrollmentAccessAction,
} from '../dtos/enrollment_access_dto.js';

/** Resultado de quitar/restaurar el acceso a un curso. */
export interface EnrollmentAccessResult {
  userId: string;
  courseId: string;
  /** Estado final de la inscripción ('revoked' | 'approved'). */
  status: string;
}

/**
 * Caso de uso: quitar o restaurar el ACCESO de un estudiante a un
 * curso cambiando el estado de su inscripción. Solo 'approved'/'finished'
 * dan acceso al aula, así que 'revoked' lo retira de inmediato.
 *
 * No toca el registro de pago: la decisión financiera se maneja aparte
 * en "Pagos".
 */
export class SetEnrollmentAccess {
  constructor(
    private readonly checkout: Pick<
      CheckoutRepository,
      'getEnrollmentStatus' | 'setEnrollmentStatus'
    >,
  ) {}

  /** null = el estudiante no está inscrito en ese curso (→ 404). */
  async execute(
    studentId: string,
    courseId: string,
    action: EnrollmentAccessAction,
  ): Promise<EnrollmentAccessResult | null> {
    const existing = await this.checkout.getEnrollmentStatus(
      studentId,
      courseId,
    );
    if (existing === null) return null;

    const status = STATUS_OF_ACCESS_ACTION[action];
    await this.checkout.setEnrollmentStatus(studentId, courseId, status);

    return { userId: studentId, courseId, status };
  }
}
