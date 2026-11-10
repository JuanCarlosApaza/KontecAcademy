-- 001_seed.sql — GENERADO por tool/mysql-schema-dump.ts desde la BD
-- Supabase (xaratebbmgffxijfigio). Idempotente: INSERT IGNORE (re-ejecutar no duplica).
--
-- Solo seeds de configuración: roles, permisos, categorías, rutas y
-- planes de membresía. NO se migran usuarios, cursos ni pagos
-- (arranque limpio). path_courses queda vacía: depende de cursos que
-- aún no existen — se re-enlaza desde el panel admin (ver seed-source.json).

SET NAMES utf8mb4;

-- roles (4 filas)
INSERT IGNORE INTO `roles` (`id`, `name`, `description`, `created_at`) VALUES
  ('92ebdec9-8437-4ded-aeea-943dcb2a8af1', 'teacher', 'Docente encargado de dictar cursos y responder preguntas', '2026-10-21 12:59:11'),
  ('e22576e5-74a4-4ca4-a23d-bae8f31a8eba', 'admin', 'Administrador del panel', '2026-10-21 12:59:11'),
  ('6ec501e3-43bc-4ebb-90d1-72be6ad0762e', 'student', 'Estudiante / cliente', '2026-10-21 12:59:11'),
  ('4d930be7-56a5-4f49-b191-4c94b02d9343', 'coordinador', 'coordinador de cursos', '2026-11-04 14:58:44');

-- permissions (13 filas)
INSERT IGNORE INTO `permissions` (`id`, `code`, `description`, `created_at`) VALUES
  ('032e0a21-7d13-4de9-98c0-3689b4c07777', 'courses:create', 'Permite crear y editar cursos', '2026-10-21 12:59:11'),
  ('fa44ecab-bb2c-4f42-8850-4ce25388ce6b', 'courses:view', 'Permite visualizar contenidos del curso', '2026-10-21 12:59:11'),
  ('2432ddc1-a52b-439c-a0b3-a447e8a0498d', 'payments:approve', 'Permite aprobar o rechazar comprobantes de pago', '2026-10-21 12:59:11'),
  ('a933db71-0e23-4dfc-a67e-d8c1793235f2', 'questions:answer', 'Permite responder preguntas de los estudiantes', '2026-10-21 12:59:11'),
  ('e3f15e1c-2041-4baf-b73b-63a18e7297cb', 'dashboard:view', 'Ver el resumen (KPIs) del panel', '2026-11-03 19:18:24'),
  ('68ab3599-8a63-44ec-9011-f126ea2906bf', 'students:view', 'Ver estudiantes y sus perfiles', '2026-11-03 19:18:24'),
  ('317be225-5913-4921-b098-de2072835b47', 'students:manage', 'Quitar o restaurar el acceso de un estudiante a un curso', '2026-11-03 19:18:24'),
  ('0bd98e07-b0e1-4ae3-97e7-7a09406d1c98', 'payments:view', 'Ver pagos y carritos abandonados', '2026-11-03 19:18:24'),
  ('4574e98c-1dbc-4cab-9c43-eec1e70ca154', 'categories:edit', 'Crear y renombrar categorías', '2026-11-03 19:18:24'),
  ('2c9c8530-6de5-4861-8d71-59da3c5c1119', 'users:view', 'Ver usuarios y sus roles', '2026-11-03 19:18:24'),
  ('510ddf50-25bd-4d40-b14b-c479c2b675f3', 'users:create', 'Crear usuarios', '2026-11-03 19:18:24'),
  ('26d8a2d7-6523-4ecf-973a-e8002377593d', 'users:edit', 'Editar usuarios (nombre, rol, estado)', '2026-11-03 19:18:24'),
  ('147b4a5a-f982-4211-a251-d6441d568316', 'roles:manage', 'Gestionar roles y su matriz de permisos', '2026-11-03 19:18:24');

-- role_permissions (9 filas)
INSERT IGNORE INTO `role_permissions` (`id`, `role_id`, `permission_id`, `created_at`) VALUES
  ('acc67676-53ed-4379-8ec8-6dbbed4bce17', 'e22576e5-74a4-4ca4-a23d-bae8f31a8eba', '032e0a21-7d13-4de9-98c0-3689b4c07777', '2026-10-21 12:59:11'),
  ('6358fb3e-8d64-4943-96fb-2bf0ba01d252', 'e22576e5-74a4-4ca4-a23d-bae8f31a8eba', 'fa44ecab-bb2c-4f42-8850-4ce25388ce6b', '2026-10-21 12:59:11'),
  ('28590c08-f4a8-4561-a0ae-c110501a4768', 'e22576e5-74a4-4ca4-a23d-bae8f31a8eba', '2432ddc1-a52b-439c-a0b3-a447e8a0498d', '2026-10-21 12:59:11'),
  ('aa187d22-f446-43ff-bc1a-eb2fd6124db0', 'e22576e5-74a4-4ca4-a23d-bae8f31a8eba', 'a933db71-0e23-4dfc-a67e-d8c1793235f2', '2026-10-21 12:59:11'),
  ('cd97cb5e-bcf5-4924-bcb9-2d404848c711', '92ebdec9-8437-4ded-aeea-943dcb2a8af1', 'fa44ecab-bb2c-4f42-8850-4ce25388ce6b', '2026-10-21 12:59:11'),
  ('6bbf259f-561b-46d6-bc69-055634242133', '92ebdec9-8437-4ded-aeea-943dcb2a8af1', 'a933db71-0e23-4dfc-a67e-d8c1793235f2', '2026-10-21 12:59:11'),
  ('70178686-c265-4ae1-9243-bae65df63a37', '6ec501e3-43bc-4ebb-90d1-72be6ad0762e', 'fa44ecab-bb2c-4f42-8850-4ce25388ce6b', '2026-10-21 12:59:11'),
  ('024cf1f6-d68f-4c77-90f0-fb26a4599336', '92ebdec9-8437-4ded-aeea-943dcb2a8af1', '032e0a21-7d13-4de9-98c0-3689b4c07777', '2026-11-03 19:18:24'),
  ('403b2e9d-6e76-479e-bc3d-b16a81851dd1', '92ebdec9-8437-4ded-aeea-943dcb2a8af1', 'e3f15e1c-2041-4baf-b73b-63a18e7297cb', '2026-11-03 19:18:24');

-- categories (3 filas)
INSERT IGNORE INTO `categories` (`id`, `name`, `slug`, `created_at`) VALUES
  ('a8a5e7cb-3308-4f22-9e77-e68bac666372', 'Estructuras y Concreto', 'estructuras-y-concreto', '2026-10-21 12:59:11'),
  ('dc4a8936-411a-4695-9320-8eecc8ba7490', 'Software de Ingeniería', 'software-de-ingenieria', '2026-10-21 12:59:11'),
  ('24999c81-5dfd-4265-a8b8-237e077f0d2a', 'Geotecnia y Vías', 'geotecnia-y-vias', '2026-10-21 12:59:11');

-- learning_paths (3 filas)
INSERT IGNORE INTO `learning_paths` (`id`, `slug`, `title`, `description`, `cover_url`, `modality`, `duration_hours`, `access_months`, `sort_order`, `is_published`, `created_at`, `updated_at`, `discount_percent`) VALUES
  ('1b1c144c-c5db-476b-bb58-71a7f423a6b4', 'ruta-de-prueba-crud', 'Ruta de prueba CRUD', '', NULL, 'asynchronous', NULL, 12, 0, 1, '2026-11-05 14:33:10', '2026-11-05 14:33:10', 0),
  ('6fcc9519-6036-43a6-9a52-9301efd75be7', 'estructuras-y-diseno', 'Estructuras y diseño', 'Ruta de diseño estructural: desde concreto armado hasta detallado de conexiones metálicas.', NULL, 'asynchronous', NULL, 12, 1, 1, '2026-11-05 14:00:41', '2026-11-05 14:00:41', 20),
  ('920a1074-4b6c-4688-b5d3-cf931cb2ce50', 'fundamentos-bim', 'Fundamentos BIM', 'Da el primer paso en BIM: planificación y gestión4D/5D de proyectos con enfoque práctico.', NULL, 'asynchronous', 60, 12, 0, 1, '2026-11-05 14:00:41', '2026-11-05 18:31:43', 20);

-- membership_plans (3 filas)
INSERT IGNORE INTO `membership_plans` (`id`, `slug`, `name`, `months`, `price`, `is_active`, `sort_order`, `created_at`, `updated_at`, `image_url`) VALUES
  ('823c6fab-f119-4edf-be26-5e5c3b26c013', 'mensual', 'Mensual', 1, 100, 1, 0, '2026-11-07 15:27:26', '2026-11-09 15:49:19', 'https://xaratebbmgffxijfigio.supabase.co/storage/v1/object/public/courses/course-1794239354172-8vjh47.png'),
  ('b858185c-191b-4fd8-a403-a55a66d7b015', 'trimestral(3-meses)', 'Trimestral(3 meses)', 3, 300, 1, 1, '2026-11-07 15:27:26', '2026-11-09 15:49:51', 'https://xaratebbmgffxijfigio.supabase.co/storage/v1/object/public/courses/course-1794239375043-us3tb3.png'),
  ('83b2f126-a2cf-4a77-86cf-8507cb828999', 'anual', 'Anual', 12, 600, 1, 2, '2026-11-07 15:27:26', '2026-11-09 15:50:08', 'https://xaratebbmgffxijfigio.supabase.co/storage/v1/object/public/courses/course-1794239405096-1ojsaj.png');
