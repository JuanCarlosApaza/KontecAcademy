import 'dotenv/config';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Verifica contra la BD de Supabase que el esquema publicado coincida
 * con el SQL definido en supabase/schema.sql (tablas y columnas).
 */

const EXPECTED: Record<string, string[]> = {
  users: [
    'id', 'full_name', 'email', 'phone', 'nationality',
    'avatar_url', 'is_active', 'created_at', 'updated_at',
  ],
  roles: ['id', 'name', 'description', 'created_at'],
  permissions: ['id', 'code', 'description', 'created_at'],
  role_permissions: ['id', 'role_id', 'permission_id', 'created_at'],
  user_roles: ['id', 'user_id', 'role_id', 'created_at'],
  categories: ['id', 'name', 'slug', 'created_at'],
  courses: [
    'id', 'title', 'description', 'image_url', 'category_id', 'teacher_id',
    'modality', 'total_hours', 'total_weeks', 'start_date', 'price',
    'compare_at_price', 'status', 'professor_bio', 'teaching_method',
    'target_audience', 'certificate_info', 'career_opportunities',
    'created_at', 'updated_at',
  ],
  modules: ['id', 'course_id', 'title', 'order_index', 'created_at', 'updated_at'],
  lessons: [
    'id', 'module_id', 'title', 'content_type', 'video_url', 'zoom_url',
    'drive_url', 'content_text', 'attachment_url', 'attachment_name',
    'live_date', 'order_index', 'created_at', 'updated_at',
  ],
  enrollments: ['id', 'user_id', 'course_id', 'status', 'enrolled_at', 'updated_at'],
  payments: [
    'id', 'enrollment_id', 'payment_type', 'amount', 'ticket_code',
    'comprobant_url', 'status', 'approved_by', 'paid_at', 'created_at', 'updated_at',
    // Rutas (010) y membresías (011):
    'path_id', 'membership_id',
  ],
  carts: ['user_id', 'course_id', 'item_type', 'added_at'],
  lesson_progress: ['id', 'user_id', 'lesson_id', 'is_completed', 'updated_at'],
  questions: [
    'id', 'lesson_id', 'user_id', 'question_text', 'answer_text',
    'teacher_id', 'is_answered', 'created_at', 'updated_at',
  ],
  // Rutas de entrenamiento (008/009):
  learning_paths: [
    'id', 'slug', 'title', 'description', 'cover_url', 'modality',
    'duration_hours', 'access_months', 'discount_percent', 'sort_order',
    'is_published', 'created_at', 'updated_at',
  ],
  path_courses: ['path_id', 'course_id', 'sort_order', 'level'],
  // Membresías (011):
  membership_plans: [
    'id', 'slug', 'name', 'months', 'price', 'is_active',
    'sort_order', 'created_at', 'updated_at',
  ],
  memberships: [
    'id', 'user_id', 'plan_id', 'status', 'start_date', 'end_date',
    'payment_id', 'created_at', 'updated_at',
  ],
};

function fail(msg: string): never {
  console.error(`❌ ${msg}`);
  process.exit(1);
}

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) fail('Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env');

const supabase: SupabaseClient = createClient(url, key, {
  auth: { persistSession: false },
});

let tablesOk = 0;
let tablesMissing = 0;
let tablesWithColErrors = 0;

for (const [table, cols] of Object.entries(EXPECTED)) {
  // 1) ¿Existe la tabla? (count exact sin traer filas)
  const { count, error: countErr } = await supabase
    .from(table)
    .select('*', { count: 'exact', head: true });

  if (countErr) {
    console.log(`❌ ${table} — NO EXISTE (${countErr.message})`);
    tablesMissing++;
    continue;
  }

  // 2) ¿Tiene todas las columnas esperadas? (PostgREST valida contra el schema cache)
  const { error: colErr } = await supabase
    .from(table)
    .select(cols.join(','))
    .limit(1);

  if (colErr) {
    console.log(`⚠️  ${table} — existe pero error de columnas: ${colErr.message}`);
    tablesWithColErrors++;
    continue;
  }

  console.log(`✅ ${table} — OK (${count} filas, ${cols.length} columnas)`);
  tablesOk++;
}

console.log('');
console.log('───── RESUMEN ─────');
console.log(`Tablas correctas:        ${tablesOk}/${Object.keys(EXPECTED).length}`);
console.log(`Tablas inexistentes:     ${tablesMissing}`);
console.log(`Con errores de columnas: ${tablesWithColErrors}`);
