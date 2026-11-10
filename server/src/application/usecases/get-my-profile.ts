import type {
  AuthenticatedUser,
  CheckoutRepository,
} from '../../domain/checkout.js';

/** Perfil del usuario de la sesión (GET /me). */
export interface MyProfile {
  id: string;
  email: string;
  roles: string[];
  /** Códigos de permiso del panel ('users:view', ...). */
  permissions: string[];
}

/** Caso de uso: perfil + roles + permisos del usuario del JWT. */
export class GetMyProfile {
  constructor(
    private readonly checkout: Pick<CheckoutRepository, 'getRoles' | 'getPermissions'>,
  ) {}

  async execute(user: AuthenticatedUser): Promise<MyProfile> {
    const [roles, permissions] = await Promise.all([
      this.checkout.getRoles(user.id),
      this.checkout.getPermissions(user.id),
    ]);

    return { id: user.id, email: user.email, roles, permissions };
  }
}
