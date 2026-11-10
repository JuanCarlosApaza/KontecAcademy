import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import 'router/app_router.dart';

/// Raíz de la UI. Sin lógica de negocio: solo tema + router.
class KontecApp extends ConsumerWidget {
  const KontecApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El router es un provider para que el guard de auth (redirect)
    // pueda leer la sesión de Supabase.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kontec',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      // El sitio está diseñado en tema claro; con ThemeMode.system en
      // Windows oscuro todas las páginas salían con fondo negro.
      themeMode: ThemeMode.light,
      // Delegados del editor rico (toolbar Quill en el admin y visor en el aula).
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
    );
  }
}
