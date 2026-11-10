import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error('❌ Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env');
  process.exit(1);
}

const supabase = createClient(url, key, { auth: { persistSession: false } });

// Verificar que las credenciales son válidas haciendo una query trivial.
// Aunque la tabla no exista, si el error es "relation does not exist"
// significa que la autenticación SÍ funcionó.
const { error } = await supabase.from('todos').select('id').limit(1);

if (error && !error.message.includes('does not exist') && !error.message.includes('schema cache')) {
  console.error('❌ Error de autenticación/conexión:', error.message);
  process.exit(1);
}

console.log('✅ Credenciales válidas — conexión a Supabase verificada');
console.log(`   URL: ${url}`);
