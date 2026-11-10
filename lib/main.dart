import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';

/// Punto de entrada: aquí solo se montan los "árboles" globales.
/// El ProviderScope es el contenedor de dependencias (DI) de Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Auth (email + Google). La clave publishable se pasa con
  // --dart-define=SUPABASE_ANON_KEY=... o se pega en
  // lib/core/config/supabase_config.dart
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: KontecApp()));
}
