// Prueba E2E: login con la cuenta admin → GET /me contra el backend local.
// Uso: npx tsx scripts/test-admin-login.mjs <email> <password>
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const email = process.argv[2] ?? 'carlosapaza6@gmail.com';
const password = process.argv[3] ?? 'Qwerty123@';

// Cliente con la clave PUBLICA (igual que hace el front).
const anon = createClient(
  process.env.SUPABASE_URL,
  'sb_publishable_-SPIlwqaYPZm8qiC1uv6Zg_f_a_hYuI',
  { auth: { persistSession: false } },
);

const { data: session, error } = await anon.auth.signInWithPassword({
  email,
  password,
});
if (error || !session.session) {
  console.error('✗ Login falló:', error?.message);
  process.exit(1);
}
console.log('✓ Login OK, user id:', session.user.id);

const res = await fetch(`${process.env.BASE_URL ?? 'http://localhost:3000'}/me`, {
  headers: { Authorization: `Bearer ${session.session.access_token}` },
});
console.log('GET /me →', res.status);
console.log(JSON.stringify(await res.json(), null, 1));

const stats = await fetch(
  `${process.env.BASE_URL ?? 'http://localhost:3000'}/admin/stats`,
  {
    headers: { Authorization: `Bearer ${session.session.access_token}` },
  },
);
console.log('GET /admin/stats →', stats.status);
console.log(JSON.stringify(await stats.json(), null, 1));
