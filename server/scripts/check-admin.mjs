// Diagnóstico rápido: ¿el rol admin está bien en la BD?
// Uso: npx tsx scripts/check-admin.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const c = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

const { data: users, error: usersErr } = await c
  .from('users')
  .select('id, email, full_name');
console.log('public.users:', JSON.stringify(users, null, 1), usersErr?.message);

const { data: roles } = await c.from('roles').select('*');
console.log('roles:', JSON.stringify(roles));

const { data: ur, error: urErr } = await c
  .from('user_roles')
  .select('user_id, role_id, roles(name)');
console.log('user_roles:', JSON.stringify(ur, null, 1), urErr?.message);
