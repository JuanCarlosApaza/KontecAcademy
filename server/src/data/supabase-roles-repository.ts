import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import {
  SYSTEM_ROLES,
  type DeleteRoleResult,
  type PermissionDef,
  type RoleRecord,
  type RolesMatrix,
  type RolesRepository,
} from '../domain/roles.js';
import { asRows } from './postgrest-rows.js';
import { permissionCodesOf, type RolePermissionRow } from './role-rows.js';

/** Fila de `roles` con el recuento de usuarios embebido. */
interface RoleRow {
  id: string;
  name: string;
  description: string | null;
  user_roles: Array<{ count: number }> | null;
}

/** Fila de `role_permissions` con el permiso embebido. */
interface GrantRow extends RolePermissionRow {
  role_id: string;
}

/** Postgres: `invalid input syntax for type uuid: "texto"`. */
function isInvalidUuid(message: string): boolean {
  return /invalid input syntax for type uuid/i.test(message);
}

/**
 * 🔌 DATOS — roles y permisos con Supabase.
 *
 * Usa la Service Role Key SOLO en el servidor (el front solo manda su
 * JWT). Las FK de `role_permissions` y `user_roles` tienen ON DELETE
 * CASCADE, así que borrar el rol limpia sus grants y asignaciones.
 */
export class SupabaseRolesRepository implements RolesRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async listMatrix(): Promise<RolesMatrix> {
    const [roles, permissions, grants] = await Promise.all([
      this.fetchRoles(),
      this.fetchPermissions(),
      this.fetchGrants(),
    ]);

    // grants por NOMBRE de rol (es lo que consume la pantalla).
    const byName: Record<string, string[]> = {};
    for (const role of roles) {
      byName[role.name] = grants.get(role.id) ?? [];
    }

    return { roles, permissions, grants: byName };
  }

  async createRole(
    name: string,
    description: string,
  ): Promise<RoleRecord | null> {
    const { data, error } = await this.client
      .from('roles')
      .insert({ name, description })
      .select('id, name, description, user_roles(count)')
      .single();

    if (error) {
      // 23505 = unique_violation (roles.name ya existe).
      if (error.code === '23505') return null;
      throw new Error(`Supabase createRole: ${error.message}`);
    }

    return this.toRoleRecord(data as unknown as RoleRow);
  }

  async setRolePermissions(
    roleId: string,
    codes: string[],
  ): Promise<boolean> {
    const { data: role, error: roleError } = await this.client
      .from('roles')
      .select('id')
      .eq('id', roleId)
      .maybeSingle();

    if (roleError) {
      throw new Error(`Supabase setRolePermissions: ${roleError.message}`);
    }
    if (!role) return false;

    const { data: permRows, error: permError } = await this.client
      .from('permissions')
      .select('id, code')
      .in('code', codes);

    if (permError) {
      throw new Error(`Supabase setRolePermissions: ${permError.message}`);
    }

    const permissionIds = asRows<{ id: string }>(permRows).map((row) => row.id);

    // Reemplazo total: primero se limpian los grants del rol.
    const { error: deleteError } = await this.client
      .from('role_permissions')
      .delete()
      .eq('role_id', roleId);

    if (deleteError) {
      throw new Error(`Supabase setRolePermissions: ${deleteError.message}`);
    }

    if (permissionIds.length > 0) {
      const { error: insertError } = await this.client
        .from('role_permissions')
        .insert(
          permissionIds.map((permissionId) => ({
            role_id: roleId,
            permission_id: permissionId,
          })),
        );

      if (insertError) {
        throw new Error(`Supabase setRolePermissions: ${insertError.message}`);
      }
    }

    return true;
  }

  async deleteRole(roleId: string): Promise<DeleteRoleResult> {
    const { data: role, error: roleError } = await this.client
      .from('roles')
      .select('id, name')
      .eq('id', roleId)
      .maybeSingle();

    if (roleError) {
      // Un :id que no es uuid (p. ej. "no-existe") hace fallar el CAST
      // de Postgres: para el API es lo mismo que "rol no existe".
      if (isInvalidUuid(roleError.message)) return 'not_found';
      throw new Error(`Supabase deleteRole: ${roleError.message}`);
    }
    if (!role) return 'not_found';

    const name = (role as { name: string }).name;
    if (SYSTEM_ROLES.includes(name)) return 'system';

    const { count, error: countError } = await this.client
      .from('user_roles')
      .select('id', { count: 'exact', head: true })
      .eq('role_id', roleId);

    if (countError) {
      throw new Error(`Supabase deleteRole: ${countError.message}`);
    }
    if ((count ?? 0) > 0) return 'in_use';

    const { error: deleteError } = await this.client
      .from('roles')
      .delete()
      .eq('id', roleId);

    if (deleteError) {
      throw new Error(`Supabase deleteRole: ${deleteError.message}`);
    }
    return 'deleted';
  }

  // ── Consultas internas ──────────────────────────────────────────

  private async fetchRoles(): Promise<RoleRecord[]> {
    const { data, error } = await this.client
      .from('roles')
      .select('id, name, description, user_roles(count)')
      .order('name');

    if (error) {
      throw new Error(`Supabase listMatrix (roles): ${error.message}`);
    }

    return asRows<RoleRow>(data).map((row) => this.toRoleRecord(row));
  }

  private async fetchPermissions(): Promise<PermissionDef[]> {
    const { data, error } = await this.client
      .from('permissions')
      .select('code, description')
      .order('code');

    if (error) {
      throw new Error(`Supabase listMatrix (permissions): ${error.message}`);
    }

    return asRows<PermissionDef>(data);
  }

  private async fetchGrants(): Promise<Map<string, string[]>> {
    const { data, error } = await this.client
      .from('role_permissions')
      .select('role_id, permissions(code)');

    if (error) {
      throw new Error(`Supabase listMatrix (grants): ${error.message}`);
    }

    const grants = new Map<string, string[]>();
    for (const row of asRows<GrantRow>(data)) {
      const codes = grants.get(row.role_id) ?? [];
      codes.push(...permissionCodesOf(row));
      grants.set(row.role_id, codes);
    }
    return grants;
  }

  private toRoleRecord(row: RoleRow): RoleRecord {
    const countEmbed = row.user_roles;
    const count = Array.isArray(countEmbed)
      ? (countEmbed[0]?.count ?? 0)
      : 0;

    return {
      id: row.id,
      name: row.name,
      description: row.description ?? '',
      userCount: count,
      system: SYSTEM_ROLES.includes(row.name),
    };
  }
}
