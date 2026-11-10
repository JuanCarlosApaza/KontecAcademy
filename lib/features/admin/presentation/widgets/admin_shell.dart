import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_providers.dart';

/// Entrada del menú lateral del panel admin.
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.permission,
  });

  final String label;
  final String route;
  final IconData icon;

  /// Permiso (`users:view`, ...) necesario para ver la entrada.
  final String permission;
}

const kAdminMenu = <AdminNavItem>[
  AdminNavItem(
    label: 'Resumen',
    route: '/admin',
    icon: Icons.grid_view,
    permission: 'dashboard:view',
  ),
  AdminNavItem(
    label: 'Estudiantes',
    route: '/admin/estudiantes',
    icon: Icons.people_outline,
    permission: 'students:view',
  ),
  AdminNavItem(
    label: 'Pagos y carritos',
    route: '/admin/pagos',
    icon: Icons.receipt_long_outlined,
    permission: 'payments:view',
  ),
  AdminNavItem(
    label: 'Cursos',
    route: '/admin/cursos',
    icon: Icons.menu_book_outlined,
    permission: 'courses:view',
  ),
  AdminNavItem(
    label: 'Rutas',
    route: '/admin/rutas',
    icon: Icons.signpost_outlined,
    permission: 'courses:view',
  ),
  AdminNavItem(
    label: 'Membresías',
    route: '/admin/membresias',
    icon: Icons.workspace_premium_outlined,
    permission: 'courses:view',
  ),
  AdminNavItem(
    label: 'Categorías',
    route: '/admin/categorias',
    icon: Icons.category_outlined,
    permission: 'categories:edit',
  ),
  AdminNavItem(
    label: 'Usuarios',
    route: '/admin/usuarios',
    icon: Icons.person_add_alt_1_outlined,
    permission: 'users:view',
  ),
  AdminNavItem(
    label: 'Roles',
    route: '/admin/roles',
    icon: Icons.admin_panel_settings_outlined,
    permission: 'roles:manage',
  ),
];

/// SHELL del panel administrativo (estilo dashboard Rixom):
/// sidebar oscuro + área de contenido clara con su header.
///
/// También hace de GUARD: sin sesión → /login; sin ningún permiso →
/// aviso. El menú se filtra por permiso, así cada rol solo ve las
/// secciones que le corresponden.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // Guard 1: ¿sesión?
    final user = ref.watch(authUserProvider).value;
    if (user == null) {
      return const AdminAccessDenied(
        message: 'Inicia sesión para entrar al panel administrativo.',
        buttonLabel: 'Ir a iniciar sesión',
      );
    }

    // Guard 2: ¿algún permiso del panel? (carga de /me)
    final accessAsync = ref.watch(sessionAccessProvider);
    // Solo espera en la PRIMERA carga: si se está refrescando (p. ej.
    // tras guardar nuevos permisos) se conserva el valor anterior y
    // la pantalla no parpadea.
    if (accessAsync.isLoading && accessAsync.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final canEnter = ref.watch(canEnterAdminPanelProvider);
    if (!canEnter) {
      return AdminAccessDenied(
        message: 'Tu cuenta (${user.email}) no tiene permisos para el panel.',
        buttonLabel: 'Volver al sitio',
        destination: '/',
      );
    }

    final sidebar = _AdminSidebar(isWide: isWide);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      drawer: isWide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isWide) sidebar,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminHeader(isWide: isWide, userEmail: user.email),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar oscuro con la marca y las secciones del panel.
class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;

    // Solo las secciones con el permiso correspondiente (el admin los
    // tiene todos; un docente, p. ej., no ve "Usuarios" ni "Roles").
    final visibleItems = kAdminMenu
        .where((item) => ref.watch(permissionProvider(item.permission)))
        .toList(growable: false);

    // Material (no Container colorado): los ListTile de abajo pintan sus
    // ink splashes sobre el Material más cercano; si el fondo fuera un
    // ColoredBox, Flutter lanza "ListTile background color or ink
    // splashes may be invisible" en cada rebuild.
    return Material(
      color: AppColors.black,
      child: SizedBox(
        width: 248,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kontec',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: ' Admin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),
              for (final item in visibleItems)
                _SidebarTile(
                  item: item,
                  // Resalta también las sub-rutas (p. ej. el detalle de
                  // un estudiante o los participantes de un curso).
                  selected:
                      currentPath == item.route ||
                      currentPath.startsWith('${item.route}/'),
                  onTap: () {
                    if (!isWide) Navigator.of(context).pop();
                    context.go(item.route);
                  },
                ),
              const Spacer(),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.white70),
                title: const Text(
                  'Ver sitio',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => context.go('/'),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  await ref.read(authViewModelProvider.notifier).signOut();
                  if (context.mounted) context.go('/');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? AppColors.black : Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? AppColors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header superior: título de la página + usuario + salir.
class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.isWide, required this.userEmail});

  final bool isWide;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (!isWide) const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Panel de administración',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.black,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'Administrador',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Página del panel: header propio + contenido con padding.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // En móvil el padding de 24 por lado deja solo ~232 px de
    // contenido en pantallas de 320: se reduce para ganar ancho.
    final compact = MediaQuery.sizeOf(context).width < 480;
    return ListView(
      padding: EdgeInsets.all(compact ? 12 : 24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 20),
        child,
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Acceso denegado (sin sesión, sin permisos o sin el permiso de la
/// sección). Se reexporta para que pantallas sueltas (/admin/roles
/// entrando directo) lo reutilicen.
class AdminAccessDenied extends StatelessWidget {
  const AdminAccessDenied({
    super.key,
    required this.message,
    required this.buttonLabel,
    this.destination = '/login',
  });

  final String message;
  final String buttonLabel;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso restringido',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(destination),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
