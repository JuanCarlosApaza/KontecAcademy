import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/viewmodels/session_context_provider.dart';
import '../../cart_injector.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/save_cart.dart';

/// Estado del carrito: la lista de cursos agregados.
///
/// El carrito es POR USUARIO: al cambiar de cuenta (login, logout o
/// cambio de sesión) el estado se resetea y se carga SOLO el carrito
/// del usuario nuevo; nunca se mezclan los cursos de dos cuentas.
class CartViewModel extends Notifier<List<CartItem>> {
  /// Descarta cargas viejas: si la sesión cambia mientras se carga un
  /// carrito, el resultado de la cuenta anterior se ignora.
  int _loadSeq = 0;

  /// Propietario del estado actual ('guest' sin sesión).
  String _owner = 'guest';

  @override
  List<CartItem> build() {
    // watch: al cambiar la sesión, build() se re-ejecuta → el estado
    // vuelve a [] y se carga el carrito del usuario que llega.
    final user = ref.watch(authUserProvider).value;
    _owner = user?.id ?? 'guest';
    Future.microtask(() => _load(_owner));
    return const [];
  }

  Future<void> _load(String owner) async {
    final seq = ++_loadSeq;
    try {
      final items = await ref.read(loadCartProvider)(owner);
      if (seq != _loadSeq) return; // respuesta de otra cuenta: se ignora
      state = items;
    } catch (_) {
      // Sin almacenamiento disponible (tests / modo privado): carrito vacío.
    }
  }

  Future<void> _persist() async {
    try {
      await ref.read(saveCartProvider)(
        SaveCartParams(ownerId: _owner, items: state),
      );
    } catch (_) {
      // Preferencias no disponibles: el carrito queda solo en memoria.
    }
  }

  /// true si el curso ya está en el carrito.
  bool contains(String courseId) =>
      state.any((item) => item.courseId == courseId);

  /// Agrega el curso (sin duplicar). Devuelve false si ya estaba.
  Future<bool> addItem(CartItem item) async {
    if (contains(item.courseId)) return false;
    state = [...state, item];
    await _persist();

    // Contexto global de sesión: saber qué agregó el estudiante.
    ref
        .read(sessionContextProvider.notifier)
        .record('add_to_cart', detail: item.title);
    return true;
  }

  Future<void> removeItem(String courseId) async {
    state = [
      for (final item in state)
        if (item.courseId != courseId) item,
    ];
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }

  /// Suma de los precios del carrito (regla única en el dominio).
  double get total => state.totalPrice;
}

final cartViewModelProvider = NotifierProvider<CartViewModel, List<CartItem>>(
  CartViewModel.new,
);
