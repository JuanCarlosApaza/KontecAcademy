import {
  ALL_PERMISSION_CODES,
  SYSTEM_ROLES,
  type DeleteRoleResult,
  type PermissionDef,
  type RoleRecord,
  type RolesMatrix,
  type RolesRepository,
} from '../domain/roles.js';

/** Descripciones del catálogo (paridad con la migración 007). */
const PERMISSION_DESCRIPTIONS: Record<string, string> = {
  'dashboard:view': 'Ver el resumen (KPIs) del panel',
  'students:view': 'Ver estudiantes y sus perfiles',
  'students:manage':
    'Quitar o restaurar el acceso de un estudiante a un curso',
  'payments:view': 'Ver pagos y carritos abandonados',
  'payments:approve': 'Aprobar o rechazar pagos',
  'courses:view': 'Ver temario y participantes de un curso',
  'courses:create': 'Crear y editar cursos, temario e imágenes',
  'categories:edit': 'Crear y renombrar categorías',
  'users:view': 'Ver usuarios y sus roles',
  'users:create': 'Crear usuarios',
  'users:edit': 'Editar usuarios (nombre, rol, estado)',
  'roles:manage': 'Gestionar roles y su matriz de permisos',
  'questions:answer': 'Responder preguntas de los estudiantes',
};

/** Grants por defecto (paridad con el seed de la BD). */
const DEFAULT_GRANTS: Record<string, string[]> = {
  admin: [],
  teacher: ['dashboard:view', 'courses:view', 'courses:create', 'questions:answer'],
  student: ['courses:view'],
};

/**
 * 🔌 DATOS — roles y permisos en memoria (tests y desarrollo sin Supabase).
 * Los grants son mutables, así que un test puede cambiar la matriz y
 * verificar el efecto en la siguiente lectura.
 */
export class InMemoryRolesRepository implements RolesRepository {
  private readonly permissions: PermissionDef[] = ALL_PERMISSION_CODES.map(
    (code) => ({
      code,
      description: PERMISSION_DESCRIPTIONS[code] ?? code,
    }),
  );

  private readonly roles: RoleRecord[] = SYSTEM_ROLES.map((name) => ({
    id: `mem-role-${name}`,
    name,
    description:
      name === 'admin'
        ? 'Administrador del panel'
        : name === 'teacher'
          ? 'Docente encargado de dictar cursos y responder preguntas'
          : 'Estudiante / cliente',
    userCount: name === 'admin' ? 1 : 0,
    system: true,
  }));

  private readonly grants = new Map<string, Set<string>>(
    SYSTEM_ROLES.map((name) => [
      name,
      new Set(DEFAULT_GRANTS[name] ?? []),
    ]),
  );

  private counter = 0;

  async listMatrix(): Promise<RolesMatrix> {
    const grants: Record<string, string[]> = {};
    for (const role of this.roles) {
      grants[role.name] = [...(this.grants.get(role.name) ?? [])].sort();
    }

    return {
      roles: this.roles.map((role) => ({ ...role })),
      permissions: this.permissions.map((permission) => ({ ...permission })),
      grants,
    };
  }

  async createRole(
    name: string,
    description: string,
  ): Promise<RoleRecord | null> {
    if (this.roles.some((role) => role.name === name)) return null;

    const role: RoleRecord = {
      id: `mem-role-custom-${++this.counter}`,
      name,
      description,
      userCount: 0,
      system: false,
    };
    this.roles.push(role);
    this.grants.set(name, new Set());

    return { ...role };
  }

  async setRolePermissions(
    roleId: string,
    codes: string[],
  ): Promise<boolean> {
    const role = this.roles.find((candidate) => candidate.id === roleId);
    if (!role) return false;

    this.grants.set(role.name, new Set(codes));
    return true;
  }

  async deleteRole(roleId: string): Promise<DeleteRoleResult> {
    const index = this.roles.findIndex((role) => role.id === roleId);
    if (index < 0) return 'not_found';

    const role = this.roles[index];
    if (!role) return 'not_found';
    if (SYSTEM_ROLES.includes(role.name)) return 'system';
    if (role.userCount > 0) return 'in_use';

    this.roles.splice(index, 1);
    this.grants.delete(role.name);
    return 'deleted';
  }
}
