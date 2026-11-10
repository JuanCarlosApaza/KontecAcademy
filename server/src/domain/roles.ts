/**
 * 🧠 DOMINIO — roles y permisos (RBAC del panel administrativo).
 * Sin dependencias de Express, ni base de datos, ni frameworks.
 *
 * Convención de los códigos: `modulo:accion` (users:view, courses:create…),
 * la misma que ya usaba la tabla `permissions` sembrada a mano.
 */

/**
 * Catálogo de permisos que conoce la aplicación. Es el seed del repositorio
 * en memoria y la referencia de los tests; en producción la fuente real es
 * la tabla `permissions` (la migración 007 la mantiene al día).
 */
export const ALL_PERMISSION_CODES: readonly string[] = [
  'dashboard:view',
  'students:view',
  'students:manage',
  'payments:view',
  'payments:approve',
  'courses:view',
  'courses:create',
  'categories:edit',
  'users:view',
  'users:create',
  'users:edit',
  'roles:manage',
  'questions:answer',
];

/** Roles base: no se pueden borrar (y el `admin` no pierde grants). */
export const SYSTEM_ROLES: readonly string[] = ['admin', 'teacher', 'student'];

/** Fila del catálogo `permissions`. */
export interface PermissionDef {
  code: string;
  description: string;
}

/** Rol del panel con el nº de usuarios que lo tienen asignado. */
export interface RoleRecord {
  id: string;
  name: string;
  description: string;
  /** Usuarios con este rol (user_roles). 0 = libre para borrar. */
  userCount: number;
  /** Rol base del sistema: no se puede eliminar. */
  system: boolean;
}

/** Matriz rol × permiso que consume la pantalla /admin/roles. */
export interface RolesMatrix {
  roles: RoleRecord[];
  permissions: PermissionDef[];
  /** roleName → códigos concedidos. El rol admin siempre sale completo. */
  grants: Record<string, string[]>;
}

/** Resultado de DELETE /admin/roles/:id. */
export type DeleteRoleResult = 'deleted' | 'not_found' | 'in_use' | 'system';

/**
 * Contrato del agregado de roles. Lo implementa Supabase (producción)
 * y una versión en memoria (tests / desarrollo sin credenciales).
 */
export interface RolesRepository {
  /** Roles + catálogo de permisos + grants actuales. */
  listMatrix(): Promise<RolesMatrix>;

  /** Alta de rol; null si el nombre ya está en uso. */
  createRole(name: string, description: string): Promise<RoleRecord | null>;

  /** Reemplaza TODOS los grants de un rol. false si el rol no existe. */
  setRolePermissions(roleId: string, codes: string[]): Promise<boolean>;

  /** Borra el rol (grants y asignaciones en cascada). */
  deleteRole(roleId: string): Promise<DeleteRoleResult>;
}
