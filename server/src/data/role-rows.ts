/**
 * Fila del join `user_roles → roles(name)` y su mapper.
 * Supabase puede devolver el rol como objeto (muchos-a-uno) o como
 * array según el planificador de la consulta; `roleNamesOf` tolera
 * ambos formatos sin casts crudos.
 */
export interface UserRoleRow {
  roles: { name: string } | Array<{ name: string }> | null;
}

/** Nombres de rol de una fila (vacío si no tiene roles). */
export function roleNamesOf(row: UserRoleRow): string[] {
  const roles = row.roles;
  if (!roles) return [];

  const list = Array.isArray(roles) ? roles : [roles];
  return list
    .map((role) => role.name)
    .filter((name): name is string => Boolean(name));
}

/** Fila del join `role_permissions → permissions(code)`. */
export interface RolePermissionRow {
  permissions: { code: string } | Array<{ code: string }> | null;
}

/** Códigos de permiso de una fila (vacío si el embed vino nulo). */
export function permissionCodesOf(row: RolePermissionRow): string[] {
  const permissions = row.permissions;
  if (!permissions) return [];

  const list = Array.isArray(permissions) ? permissions : [permissions];
  return list
    .map((permission) => permission.code)
    .filter((code): code is string => Boolean(code));
}
