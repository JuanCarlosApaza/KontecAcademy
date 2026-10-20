import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Punto de entrada: aquí solo se montan los "árboles" globales.
/// El ProviderScope es el contenedor de dependencias (DI) de Riverpod.
void main() {
  runApp(
    const ProviderScope(
      child: KontecApp(),
    ),
  );
}
