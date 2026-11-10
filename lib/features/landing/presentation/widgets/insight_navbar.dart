import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/viewmodels/admin_providers.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';

/// Item del menú de navegación. Si tiene [children], se despliega
/// como menú (desktop) o como sección expandible (móvil).
class NavItem {
  const NavItem({
    required this.label,
    this.route = '/',
    this.children = const [],
    this.icon,
  });

  final String label;
  final String route;
  final List<NavItem> children;
  final IconData? icon;
}

/// Menú principal (plantilla: fondo negro, etiquetas en mayúsculas).
const kMainMenu = <NavItem>[
  NavItem(label: 'HOME', route: '/'),
  NavItem(
    label: 'CAPACITACIONES',
    children: [
      NavItem(label: 'ESPECIALIZACIONES', route: '/capacitaciones'),
      NavItem(label: 'CURSOS ASINCRÓNICOS', route: '/capacitaciones'),
    ],
  ),
  NavItem(label: 'RUTAS', route: '/rutas'),
  NavItem(label: 'MEMBRESÍAS', route: '/membresias'),
  NavItem(label: 'CONSULTORIAS', route: '/consultorias'),
  NavItem(label: 'CONTACTANOS', route: '/contactanos'),
  NavItem(label: 'OFERTAS', route: '/ofertas'),
  // "MI CUENTA" NO vive aquí: se dibuja con [_AuthAction] para
  // cambiar según haya sesión (login / mis cursos + cerrar sesión).
];

/// Redes sociales del navbar (se abren en pestaña nueva).
/// TODO(back): sustituir por los perfiles reales de Kontec.
const kSocialLinks = <String, String>{
  'Instagram': 'https://www.instagram.com/',
  'Facebook': 'https://www.facebook.com/',
  'YouTube': 'https://www.youtube.com/',
};

/// Barra de navegación superior responsive.
///
///  * >= 1200px: menú horizontal completo.
///  * < 1200px: botón de menú (Drawer) con las mismas opciones.
class InsightNavbar extends ConsumerWidget implements PreferredSizeWidget {
  const InsightNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    // El menú completo (7 items) necesita ~820 px. Con el logo a la
    // izquierda, mostramos menú solo a partir de 1200 px; debajo, Drawer.
    final isDesktop = width >= 1200;

    return Material(
      color: AppColors.black,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width < 600 ? 12 : 24),
            child: Row(
              children: [
                Flexible(child: BrandLogo(dark: true)),
                const SizedBox(width: 16),
                if (isDesktop)
                  // FittedBox: si por cualquier motivo (zoom de fuente,
                  // tipografía distinta) el menú no cabe, se escala en vez
                  // de desbordar.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _DesktopMenu(),
                    ),
                  )
                else ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo "Kontec Academy" + sello Autodesk.
/// Se adapta al ancho: en pantallas estrechas oculta "Academy"/el sello.
/// TODO(back): sustituir por las imágenes reales del logo en /assets.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.dark = false});

  /// true → versión para fondo oscuro (drawer/footer).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // El sello Autodesk solo cabe en pantallas realmente anchas.
    final showAcademy = width >= 430;
    final showAutodeskSeal = width >= 1250;
    final nameColor = dark ? Colors.white : AppColors.textDark;

    // FittedBox: el logo se ESCALA si no cabe en el espacio disponible
    // (nunca desborda el Row de la navbar).
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Kontec',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: nameColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (showAcademy)
                  TextSpan(
                    text: ' Academy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
              ],
            ),
          ),
          if (showAutodeskSeal) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 1,
              height: 28,
              child: ColoredBox(
                color: dark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '▲ AUTODESK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Authorized Training Center',
                  style: TextStyle(
                    fontSize: 8,
                    color: dark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Menú horizontal para pantallas grandes.
class _DesktopMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Admin" solo aparece con el rol de administrador (guard del panel).
    final isAdmin = ref.watch(isAdminProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final item in kMainMenu) _DesktopMenuItem(item: item),
        if (isAdmin)
          const _DesktopMenuItem(
            item: NavItem(
              label: 'ADMIN',
              route: '/admin',
              icon: Icons.admin_panel_settings,
            ),
          ),
        const SizedBox(width: 4),
        const _CartButton(),
        const SizedBox(width: 4),
        const _AuthAction(),
        const SizedBox(width: 8),
        const _SocialLinks(),
      ],
    );
  }
}

class _DesktopMenuItem extends StatelessWidget {
  const _DesktopMenuItem({required this.item});

  final NavItem item;

  @override
  Widget build(BuildContext context) {
    // Solo los items sin submenú pueden marcar activo (los que tienen
    // submenú usan '/' por defecto y se pintarían siempre igual).
    final isActive =
        item.children.isEmpty &&
        GoRouterState.of(context).uri.path == item.route;
    // Sobre negro: inactivo blanco, activo naranja de marca.
    final color = isActive ? AppColors.primary : Colors.white;

    if (item.children.isEmpty) {
      return TextButton(
        onPressed: () => context.go(item.route),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 17, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Con hijos: desplegable naranja (Capacitaciones).
    return PopupMenuButton<String>(
      tooltip: item.label,
      onSelected: (route) => context.go(route),
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (context) => [
        for (final child in item.children)
          PopupMenuItem(
            value: child.route,
            child: Text(
              child.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: Colors.white,
              ),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: color,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive ? AppColors.primary : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer de navegación para móvil/tablet.
class InsightDrawer extends ConsumerWidget {
  const InsightDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.black),
            child: Align(
              alignment: Alignment.centerLeft,
              child: BrandLogo(dark: true),
            ),
          ),
          for (final item in kMainMenu)
            if (item.children.isEmpty)
              ListTile(
                leading: item.icon != null
                    ? Icon(item.icon, color: AppColors.primary)
                    : null,
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.route);
                },
              )
            else
              ExpansionTile(
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                children: [
                  for (final child in item.children)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 40),
                      title: Text(child.label),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(child.route);
                      },
                    ),
                ],
              ),
          if (ref.watch(authUserProvider).value != null)
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              title: const Text(
                'Mi perfil',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/perfil');
              },
            ),
          if (ref.watch(authUserProvider).value != null)
            ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Mis cursos',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/mis-cursos');
              },
            ),
          if (ref.watch(isAdminProvider))
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: AppColors.primary,
              ),
              title: const Text(
                'Admin',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
          const Divider(),
          ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                ),
                const _CartBadge(),
              ],
            ),
            title: const Text(
              'Mi carrito',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/carrito');
            },
          ),
          const _AuthListTile(),
        ],
      ),
    );
  }
}

/// Ícono de carrito con contador (navbar de escritorio).
class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Mi carrito',
      onPressed: () => context.go('/carrito'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          const _CartBadge(),
        ],
      ),
    );
  }
}

/// Contadito naranja con la cantidad de cursos del carrito.
class _CartBadge extends ConsumerWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      cartViewModelProvider.select((items) => items.length),
    );
    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      top: -4,
      right: -6,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 9,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Acción de sesión (escritorio): "MI CUENTA" → login o menú del usuario.
class _AuthAction extends ConsumerWidget {
  const _AuthAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (user == null) {
      return TextButton(
        onPressed: () => context.go('/login'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: const Text(
          'MI CUENTA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: user.displayName,
      onSelected: (action) => _onAction(context, ref, action),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            user.email,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: AppColors.textDark),
              SizedBox(width: 8),
              Text('Mi perfil', style: TextStyle(color: AppColors.textDark)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'courses',
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: AppColors.textDark),
              SizedBox(width: 8),
              Text('Mis cursos', style: TextStyle(color: AppColors.textDark)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MI CUENTA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: Colors.white,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'profile') {
      context.go('/perfil');
      return;
    }
    if (action == 'courses') {
      context.go('/mis-cursos');
      return;
    }
    if (action != 'logout') return;
    await ref.read(authViewModelProvider.notifier).signOut();
    if (context.mounted) context.go('/');
  }
}

/// Iconos de redes sociales del navbar (se abren en pestaña nueva).
class _SocialLinks extends StatelessWidget {
  const _SocialLinks();

  static const _icons = <String, IconData>{
    'Instagram': Icons.camera_alt_outlined,
    'Facebook': Icons.facebook,
    'YouTube': Icons.smart_display_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in kSocialLinks.entries)
          IconButton(
            tooltip: entry.key,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            iconSize: 17,
            color: Colors.white,
            icon: Icon(_icons[entry.key] ?? Icons.link),
            onPressed: () async {
              final uri = Uri.parse(entry.value);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
      ],
    );
  }
}

/// Versión en lista (drawer) del control de sesión.
class _AuthListTile extends ConsumerWidget {
  const _AuthListTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;

    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.login, color: AppColors.primary),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go('/login');
        },
      );
    }

    return ListTile(
      leading: const Icon(Icons.logout, color: AppColors.primary),
      title: Text(
        'Cerrar sesión (${user.displayName})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () async {
        Navigator.pop(context);
        await ref.read(authViewModelProvider.notifier).signOut();
        if (context.mounted) context.go('/');
      },
    );
  }
}
