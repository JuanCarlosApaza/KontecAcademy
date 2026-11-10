import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Footer negro compartido por TODAS las páginas.
/// Responsive: columnas en desktop (>= 800px), apilado en móvil.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    final brand = Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Kontec',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const TextSpan(
                text: ' Academy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          textAlign: isWide ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Autodesk Authorized Training Center',
          style: TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );

    final links = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ENLACES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _FooterLink(label: 'Capacitaciones', route: '/capacitaciones'),
        const SizedBox(height: 6),
        _FooterLink(label: 'Rutas de Entrenamiento', route: '/rutas'),
        const SizedBox(height: 6),
        _FooterLink(label: 'Insight Store', route: '/store'),
        const SizedBox(height: 6),
        _FooterLink(label: 'Membresías', route: '/membresias'),
      ],
    );

    const contact = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACTO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'hola@kontec-academy.com',
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 6),
        Text(
          'WhatsApp: +00 000 000 000',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );

    return ColoredBox(
      color: AppColors.black,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 40,
          horizontal: isWide ? 72 : 24,
        ),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: brand),
                  Expanded(flex: 2, child: links),
                  Expanded(flex: 2, child: contact),
                ],
              )
            : Column(
                children: [
                  brand,
                  const SizedBox(height: 28),
                  links,
                  const SizedBox(height: 28),
                  contact,
                ],
              ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}
