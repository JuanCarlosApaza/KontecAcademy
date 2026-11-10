/// Composition root del feature `cart`.
///
/// El carrito es UI-estado local (Riverpod) + persistencia:
///  * `cartViewModelProvider` (presentation) → estado del carrito.
///  * `cartRepositoryProvider` (data) → persistencia en el dispositivo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/cart_repository_impl.dart';
import 'domain/usecases/load_cart.dart';
import 'domain/usecases/save_cart.dart';

export 'data/cart_repository_impl.dart' show cartRepositoryProvider;
export 'domain/entities/cart_item.dart' show CartItem;

final loadCartProvider = Provider<LoadCart>(
  (ref) => LoadCart(ref.watch(cartRepositoryProvider)),
);

final saveCartProvider = Provider<SaveCart>(
  (ref) => SaveCart(ref.watch(cartRepositoryProvider)),
);
