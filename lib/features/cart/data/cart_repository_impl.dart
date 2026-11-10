import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_injector.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/entities/cart_item.dart';
import '../domain/repositories/cart_repository.dart';
import 'datasources/cart_remote_datasource.dart';
import 'models/cart_item_model.dart';

/// 🔌 DATOS — carrito guardado en el dispositivo (localStorage en web,
/// SharedPreferences en Android/iOS), CON LA CLAVE POR USUARIO:
/// `kontec_cart_v1::<ownerId>`. Así dos cuentas en el mismo navegador
/// o dispositivo nunca comparten carrito.
class LocalCartRepository {
  static String _storageKey(String ownerId) => 'kontec_cart_v1::$ownerId';

  Future<List<CartItem>> load(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(ownerId));
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) =>
                CartItemModel.fromJson(item as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } catch (_) {
      // JSON corrupto → carrito vacío (nunca rompe la app).
      return const [];
    }
  }

  Future<void> save(String ownerId, List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode([
      for (final item in items) CartItemModel.fromEntity(item).toJson(),
    ]);
    await prefs.setString(_storageKey(ownerId), raw);
  }

  /// Vacía el carrito de un owner (usado para limpiar 'guest' tras
  /// migrar sus ítems al servidor en el primer login).
  Future<void> clear(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(ownerId), '[]');
  }
}

/// Repositorio del carrito: LOCAL como estado inmediato y caché (sirve
/// sin conexión), SERVIDOR como fuente de verdad cuando hay sesión.
///
///  * load(): con sesión intenta `GET /cart`; si el servidor no responde
///    se usa lo local (modo offline). Sin sesión solo lo local.
///  * save(): escribe siempre en local y, con sesión, empuja el carrito
///    completo al servidor (`PUT /cart`). Un fallo del servidor no
///    rompe la UI: lo local ya quedó guardado.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local, this._remote, this._auth);

  final LocalCartRepository _local;
  final CartRemoteDataSource _remote;
  final AuthRepository _auth;

  /// 'guest' = sin sesión (el servidor no guarda carritos anónimos).
  bool _isGuest(String ownerId) => ownerId == 'guest';

  bool get _hasSession => _auth.accessToken != null;

  @override
  Future<List<CartItem>> load(String ownerId) async {
    if (_isGuest(ownerId) || !_hasSession) {
      return _local.load(ownerId);
    }

    try {
      final models = await _remote.fetchCart();
      var items = [for (final model in models) model.toEntity()];

      // MIGRACIÓN del carrito de invitado: lo que se agregó SIN sesión
      // (clave 'guest') se empuja al servidor en el primer login, para
      // que los ítems —como las rutas agregadas— no desaparezcan al
      // cambiar de cuenta.
      final guestItems = await _local.load('guest');
      if (guestItems.isNotEmpty) {
        final known = {for (final item in items) item.courseId};
        final extra = [
          for (final item in guestItems)
            if (!known.contains(item.courseId)) item,
        ];
        if (extra.isNotEmpty) {
          items = [...items, ...extra];
          try {
            await _remote.replaceCart(items);
            await _local.clear('guest'); // ya migrado: no se repite
          } catch (_) {
            // Sin red: la próxima carga reintenta la migración.
          }
        }
      }

      await _local.save(ownerId, items);
      return items;
    } catch (_) {
      // Sin conexión al servidor: el carrito local sigue siendo válido.
      return _local.load(ownerId);
    }
  }

  @override
  Future<void> save(String ownerId, List<CartItem> items) async {
    await _local.save(ownerId, items);

    if (_isGuest(ownerId) || !_hasSession) return;

    try {
      await _remote.replaceCart(items);
    } catch (_) {
      // El servidor no respondió: lo local ya está guardado y el
      // siguiente guardado reintentará el empuje completo.
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final remote = ref.watch(cartRemoteDataSourceProvider);
  return CartRepositoryImpl(
    LocalCartRepository(),
    remote,
    ref.watch(authRepositoryProvider),
  );
});
