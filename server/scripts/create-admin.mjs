// Crea (o repara) una cuenta de administrador del panel /admin.
//
// Uso (desde server/):
//   npx tsx scripts/create-admin.mjs tu-email@dominio.com 'TuClave123'
//
// Qué hace (en orden):
//   1. Crea el usuario en Supabase Auth (confirmado) o reutiliza uno
//      existente (y le actualiza la contraseña si la pasas).
//   2. Sembrá los roles base (admin, student) si faltan.
//   3. Crea/actualiza el perfil en public.users.
//   4. Asigna el rol "admin" en public.user_roles (sin duplicar).
//
// Usa SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY de server/.env
// (la clave secreta NUNCA sale de este equipo).
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const email = process.argv[2]?.trim();
const password = process.argv[3];

if (!email || !password) {
  console.error(
    "Uso: npx tsx scripts/create-admin.mjs <email> <password>\n" +
    "Ej.: npx tsx scripts/create-admin.mjs carlosapaza6@gmail.com 'Qwerty123@'",
  );
  process.exit(1);
}

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('✗ Falta SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en server/.env');
  process.exit(1);
}

const admin = createClient(url, key, { auth: { persistSession: false } });

/** Busca un usuario auth por email (listUsers paginado). */
async function findUserByEmail(target) {
  for (let page = 1; page <= 50; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 100 });
    if (error) throw new Error(error.message);
    const hit = data.users.find(
      (u) => (u.email ?? '').toLowerCase() === target.toLowerCase(),
    );
    if (hit) return hit;
    if (data.users.length === 0 || page >= (data.totalPages ?? 1)) return null;
  }
  return null;
}

/** Inserta/upsert tolerando columnas que aún no existan en la BD:
 *  si el error menciona una columna faltante, la quita y reintenta. */
async function upsertTolerant(table, payload, onConflict) {
  const body = { ...payload };
  for (let attempt = 0; attempt < 8; attempt++) {
    const { error } = await admin.from(table).upsert(body, onConflict);
    if (!error) return { data: body, error: null };

    // PostgREST: "Could not find the 'x' column of 'users' in the schema cache"
    // Postgres:  'column "x" ... does not exist'
    const match =
      error.message.match(/column "([a-z_]+)"/i) ??
      error.message.match(/'([a-z_]+)' column/i);
    if (match && match[1] in body && match[1] !== 'id') {
      console.warn(`  ⚠ columna "${match[1]}" no existe en ${table} → se omite`);
      delete body[match[1]];
      continue;
    }
    return { data: null, error };
  }
  return { data: null, error: new Error('demasiados reintentos por columnas faltantes') };
}

// ── 1. Usuario en Supabase Auth ────────────────────────────────────
let userId;
const { data: created, error: createErr } = await admin.auth.admin.createUser({
  email,
  password,
  email_confirm: true, // la cuenta la creó el admin: ya confirmada
});

if (created?.user) {
  userId = created.user.id;
  console.log(`✓ Usuario auth creado: ${userId}`);
} else {
  let found;
  try {
    found = await findUserByEmail(email);
  } catch (findErr) {
    console.error('  buscar:', findErr.message);
    process.exit(1);
  }
  if (!found) {
    console.error('✗ No se pudo crear ni encontrar el usuario:');
    console.error('  crear:', createErr?.message);
    process.exit(1);
  }
  userId = found.id;

  const { error: updErr } = await admin.auth.admin.updateUserById(userId, { password });
  if (updErr) {
    console.warn('  ⚠ No se pudo actualizar la contraseña:', updErr.message);
  }
  console.log(`✓ Usuario ya existía: ${userId} (clave actualizada si fue posible)`);
}

// ── 2. Roles base ──────────────────────────────────────────────────
const { error: rolesErr } = await admin
  .from('roles')
  .upsert(
    [
      { name: 'admin', description: 'Administrador del panel' },
      { name: 'student', description: 'Estudiante / cliente' },
    ],
    { onConflict: 'name' },
  );
if (rolesErr) {
  console.error('✗ No se pudieron sembrar los roles:', rolesErr.message);
  process.exit(1);
}
console.log('✓ Roles "admin" y "student" listos');

// ── 3. Perfil en public.users ──────────────────────────────────────
const fullName =
  (email.split('@')[0] ?? 'Administrador').replace(/[._]+/g, ' ').trim();
const profile = await upsertTolerant(
  'users',
  {
    id: userId,
    email,
    full_name: fullName,
    is_active: true,
  },
  { onConflict: 'id' },
);
if (profile.error) {
  console.error('✗ No se pudo crear el perfil en public.users:', profile.error.message);
  process.exit(1);
}
console.log(`✓ Perfil en public.users (full_name: ${fullName})`);

// ── 4. Rol admin ───────────────────────────────────────────────────
const { data: role, error: roleErr } = await admin
  .from('roles')
  .select('id')
  .eq('name', 'admin')
  .maybeSingle();

if (roleErr || !role) {
  console.error('✗ No existe el rol "admin":', roleErr?.message ?? 'sin fila');
  process.exit(1);
}

const { count, error: countErr } = await admin
  .from('user_roles')
  .select('*', { count: 'exact', head: true })
  .eq('user_id', userId)
  .eq('role_id', role.id);

if (countErr) {
  console.error('✗ No se pudo consultar user_roles:', countErr.message);
  process.exit(1);
}

if ((count ?? 0) > 0) {
  console.log('✓ El rol "admin" ya estaba asignado');
} else {
  const { error: assignErr } = await admin
    .from('user_roles')
    .insert({ user_id: userId, role_id: role.id });
  if (assignErr) {
    console.error('✗ No se pudo asignar el rol admin:', assignErr.message);
    console.error('  (Si user_roles.user_id apunta a otra tabla, ejecuta el SQL de README)');
    process.exit(1);
  }
  console.log('✓ Rol "admin" asignado');
}

console.log('\n🎉 Listo. Entra a la app con:');
console.log(`   email: ${email}`);
console.log('   clave: (la que pasaste por parámetro)');
console.log('   → http://localhost:8080/admin  (con el backend Node corriendo)');
