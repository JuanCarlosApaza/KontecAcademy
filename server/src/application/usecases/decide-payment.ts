import type { AdminRepository, PaymentDecision } from '../../domain/admin.js';
import type { AuthenticatedUser } from '../../domain/checkout.js';
import {
  STATUS_OF_ACTION,
  type PaymentAction,
} from '../dtos/payment_action_dto.js';

/**
 * Caso de uso: decisión MANUAL del admin sobre un pago (aprobar o
 * rechazar tras verificar el comprobante por su cuenta). Al aprobar,
 * la inscripción pasa a 'approved' y el estudiante gana ACCESO al
 * curso; al rechazar, pierde el acceso.
 */
export class DecidePayment {
  constructor(
    private readonly admin: Pick<AdminRepository, 'decidePayment'>,
  ) {}

  execute(
    user: AuthenticatedUser,
    paymentId: string,
    action: PaymentAction,
  ): Promise<PaymentDecision | null> {
    return this.admin.decidePayment(
      paymentId,
      STATUS_OF_ACTION[action],
      user.id,
    );
  }
}
