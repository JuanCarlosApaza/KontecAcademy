/**
 * Limpieza puntual: borra de Supabase el curso de prueba creado por la
 * prueba de humo del POST /courses (uso manual, no forma parte de la API).
 *
 *   npx tsx tool/delete-course.ts <courseId>
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const courseId = process.argv[2];

if (!courseId) {
  console.error('Uso: npx tsx tool/delete-course.ts <courseId>');
  process.exit(1);
}

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error('Faltan SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY en server/.env');
  process.exit(1);
}

const client = createClient(url, key, { auth: { persistSession: false } });

const { data, error } = await client
  .from('courses')
  .delete()
  .eq('id', courseId)
  .select('id, title');

if (error) {
  console.error('Error al borrar:', error.message);
  process.exit(1);
}

console.log(data?.length ? `Borrado: ${data[0].title}` : 'No había curso con ese id.');
