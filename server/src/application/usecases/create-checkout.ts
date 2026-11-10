import type {
  AuthenticatedUser,
  CheckoutRepository,
} from '../../domain/checkout.js';
import type { MembershipRepository } from '../../domain/membership.js';
import { ValidationError } from '../errors.js';
import type { CreateCheckoutDTO } from '../dtos/checkout_dto.js';

/**
 * Caso de uso: registrar la inscripción (usuarios + enrollments +
 * payments pendientes de aprobación de ticket) o la membresía.
 */
export class CreateCheckout {
  constructor(
    private readonly checkout: Pick<
      CheckoutRepository,
      'createCheckout' | 'getEnrollmentStatus' | 'getPathCourseIds'
    >,
    private readonly memberships: Pick<
      MembershipRepository,
      'findActive' | 'findLatestOpen' | 'planById'
    >,
  ) {}

  async execute(user: AuthenticatedUser, dto: CreateCheckoutDTO) {
    // VALIDACIÓN de duplicados: el upsert de enrollments pondría el
    // curso "pending_payment" aunque ya estuviera APROBADO (perdería el
    // acceso) y generaría un segundo pago en cola.
    // Un ítem tipo 'path' se EXPANDE: se valida cada curso del combo.
    for (const item of dto.items) {
      // Membresía: no se puede comprar una si ya hay una abierta.
      if (item.type === 'membership') {
        const plan = await this.memberships.planById(item.courseId);
        if (!plan) {
          throw new ValidationError('El plan de membresía no existe.');
        }
        const open = await this.memberships.findLatestOpen(user.id);
        if (open?.status === 'pending_payment') {
          throw new ValidationError(
            'Ya tienes una membresía en verificación. Espera la aprobación '
            + 'antes de comprar otra.',
          );
        }
        if (open?.status === 'active' && (open.endDate ?? '') > new Date().toISOString()) {
          throw new ValidationError(
            `Ya tienes una membresía activa hasta ${open.endDate?.slice(0, 10)}.`,
          );
        }
        continue;
      }

      // Cursos y rutas: con membresía ACTIVA el acceso ya es total.
      const active = await this.memberships.findActive(user.id);
      if (active && (active.endDate ?? '') > new Date().toISOString()) {
        throw new ValidationError(
          'Ya tienes acceso por tu membresía activa: no necesitas '
          + 'comprar este curso.',
        );
      }

      let targetIds = [item.courseId];

      if (item.type === 'path') {
        const pathCourseIds = await this.checkout.getPathCourseIds(
          item.courseId,
        );
        if (pathCourseIds === null) {
          throw new ValidationError('La ruta seleccionada no existe.');
        }
        if (pathCourseIds.length === 0) {
          throw new ValidationError(
            'La ruta seleccionada todavía no tiene cursos.',
          );
        }
        targetIds = pathCourseIds;
      }

      for (const courseId of targetIds) {
        const status = await this.checkout.getEnrollmentStatus(
          user.id,
          courseId,
        );

        if (status === 'approved') {
          throw new ValidationError(
            'Ya tienes uno de estos cursos inscrito con pago aprobado. '
            + 'Encuéntralo en "Mis cursos".',
          );
        }
        if (status === 'pending_payment') {
          throw new ValidationError(
            'Uno de estos cursos ya tiene un pago en verificación. '
            + 'Espera la aprobación antes de pagar de nuevo.',
          );
        }
        // 'rejected' u otros estados → puede volver a solicitarlo.
      }
    }

    return this.checkout.createCheckout({
      userId: user.id,
      email: dto.email,
      fullName: dto.fullName,
      phone: dto.phone,
      nationality: dto.nationality,
      documentNumber: dto.documentNumber,
      items: dto.items,
    });
  }
}
