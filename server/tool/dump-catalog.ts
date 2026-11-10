import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } },
);

const { data: cats } = await supabase.from('categories').select('*').order('name');
console.log('── CATEGORÍAS ──');
console.log(JSON.stringify(cats, null, 2));

const { data: courses } = await supabase
  .from('courses')
  .select('*, categories(id, name, slug)')
  .order('created_at');

console.log('── CURSOS ──');
console.log(JSON.stringify(courses, null, 2));
