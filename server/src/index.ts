import 'dotenv/config';

import { createApp } from './app.js';
import { createUseCases } from './application/compose.js';
import { InMemoryAdminRepository } from './data/in-memory-admin-repository.js';
import { InMemoryCartRepository } from './data/in-memory-cart-repository.js';
import { InMemoryCatalogRepository } from './data/in-memory-catalog-repository.js';
import { InMemoryCheckoutRepository } from './data/in-memory-checkout-repository.js';
import { InMemoryCurriculumRepository } from './data/in-memory-curriculum-repository.js';
import { InMemoryLearningPathRepository } from './data/in-memory-learning-path-repository.js';
import { InMemoryRolesRepository } from './data/in-memory-roles-repository.js';
import { InMemoryTodoRepository } from './data/in-memory-todo-repository.js';
import { SupabaseAdminRepository } from './data/supabase-admin-repository.js';
import { SupabaseCartRepository } from './data/supabase-cart-repository.js';
import { SupabaseCatalogRepository } from './data/supabase-catalog-repository.js';
import { SupabaseCheckoutRepository } from './data/supabase-checkout-repository.js';
import { SupabaseCurriculumRepository } from './data/supabase-curriculum-repository.js';
import { SupabaseLearningPathRepository } from './data/supabase-learning-path-repository.js';
import { SupabaseMembershipRepository } from './data/supabase-membership-repository.js';
import { SupabaseRolesRepository } from './data/supabase-roles-repository.js';
import { InMemoryMembershipRepository } from './data/in-memory-membership-repository.js';

const port = Number(process.env.PORT ?? 3000);

// Ensamblado (composition root): aquí se decide qué implementación usa la API.
// Con SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY → catálogo desde Supabase.
// Nota: /todos (demo de Clean Architecture) queda en memoria porque el
// esquema real NO incluye la tabla `todos`; para persistirla, ejecuta
// server/sql/001_create_todos.sql y usa SupabaseTodoRepository.
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const useSupabase = Boolean(supabaseUrl && supabaseKey);

const todos = new InMemoryTodoRepository();
const catalog = useSupabase
  ? new SupabaseCatalogRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryCatalogRepository();
// Rutas de entrenamiento (públicas + CRUD del panel). Se crea ANTES
// del carrito y el checkout: en memoria, ambos resuelven precios y
// cursos de los ítems tipo 'path'.
const paths = useSupabase
  ? new SupabaseLearningPathRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryLearningPathRepository(catalog);
// Membresías (3 planes + acceso total): en memoria, la de cart,
// checkout y currículum consultan activas/planes.
const memberships = useSupabase
  ? new SupabaseMembershipRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryMembershipRepository();
const checkout = useSupabase
  ? new SupabaseCheckoutRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryCheckoutRepository(catalog, paths, memberships);
const admin = useSupabase
  ? new SupabaseAdminRepository(supabaseUrl!, supabaseKey!)
  // En memoria, el admin comparte el checkout para que aprobar un
  // pago actualice la inscripción (como en la BD real). El cast es
  // seguro: en la rama !useSupabase, checkout SIEMPRE es el repo en
  // memoria (que implementa el seam InMemoryEnrollmentStore). El
  // catálogo le sirve para validar la existencia del curso al editar
  // su temario.
  : new InMemoryAdminRepository(
      checkout as InMemoryCheckoutRepository,
      catalog as InMemoryCatalogRepository,
    );
// Rutas de entrenamiento: ver `paths` más arriba (antes que el carrito).
// El carrito en memoria reutiliza el catálogo para resolver título/precio,
// las rutas para los ítems tipo 'path' y los planes para 'membership'.
const cart = useSupabase
  ? new SupabaseCartRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryCartRepository(catalog, paths, memberships);
// El "Aula" (temario + progreso) necesita el catálogo (existencia del
// curso), las inscripciones (gate de contenido por pago aprobado) y la
// membresía activa (acceso total).
const curriculum = useSupabase
  ? new SupabaseCurriculumRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryCurriculumRepository(catalog, checkout, memberships);
// Roles y permisos del panel (matriz rol × permiso).
const roles = useSupabase
  ? new SupabaseRolesRepository(supabaseUrl!, supabaseKey!)
  : new InMemoryRolesRepository();

if (!useSupabase) {
  // eslint-disable-next-line no-console
  console.warn(
    '⚠️  SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY no definidas → usando repositorios en memoria.',
  );
}

// La API recibe casos de uso (una acción = una clase execute()), no
// repositorios crudos: aquí se ensamblan las capas (composition root).
const app = createApp({
  // `auth` es solo para los middlewares de sesión (JWT + roles).
  auth: checkout,
  ...createUseCases({
    todos,
    catalog,
    checkout,
    admin,
    cart,
    curriculum,
    roles,
    paths,
    memberships,
  }),
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(
    `🚀 Kontec API escuchando en http://localhost:${port} (${
      useSupabase ? 'Supabase' : 'en memoria'
    })`,
  );
});
