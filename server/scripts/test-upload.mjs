// Prueba real de subida al bucket "courses" (1×1 px PNG) y limpieza.
// Uso: npx tsx scripts/test-upload.mjs
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const c = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } },
);

// PNG 1×1 px transparente.
const png = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);

const path = `prueba-${Date.now()}.png`;
const { data, error } = await c.storage
  .from('courses')
  .upload(path, png, { contentType: 'image/png', upsert: false });

if (error) {
  console.error('✗ upload falló:', error.message);
  process.exit(1);
}
console.log('✓ subido:', data.path);

const { data: pub } = c.storage.from('courses').getPublicUrl(data.path);
console.log('✓ URL pública:', pub.publicUrl);

// Verificar que la URL responde 200.
const res = await fetch(pub.publicUrl);
console.log('GET URL pública →', res.status);

// Limpieza del archivo de prueba.
const { error: rmErr } = await c.storage.from('courses').remove([data.path]);
console.log(rmErr ? `⚠ no se pudo borrar: ${rmErr.message}` : '✓ archivo de prueba borrado');
