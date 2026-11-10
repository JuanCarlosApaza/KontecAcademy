import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

console.log('URL cargada:', url ? `${url.slice(0, 30)}…` : 'FALTA');
console.log('Key cargada:', key ? `${key.slice(0, 12)}…` : 'FALTA');

if (!url || !key) process.exit(1);

const supabase = createClient(url, key, { auth: { persistSession: false } });

const { data, error } = await supabase.from('categories').select('*');

if (error) {
  console.log('ERROR:', error.message, '|', error.code, '|', error.details);
} else {
  console.log('OK, filas:', data?.length, JSON.stringify(data?.[0] ?? null));
}
