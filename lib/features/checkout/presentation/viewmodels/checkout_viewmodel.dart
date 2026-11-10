import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/format/currency.dart';
import '../../../auth/presentation/viewmodels/session_context_provider.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/viewmodels/cart_viewmodel.dart';
import '../../checkout_injector.dart';

/// STATE del formulario de pago.
class CheckoutState {
  const CheckoutState({this.isLoading = false, this.error, this.result});

  final bool isLoading;
  final Failure? error;

  /// No nulo cuando la inscripción se registró correctamente.
  final CheckoutResult? result;

  bool get isDone => result != null;

  CheckoutState copyWith({
    bool? isLoading,
    Failure? error,
    CheckoutResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      result: clearResult ? null : result ?? this.result,
    );
  }
}

/// ViewModel (MVVM) del paso de pago: envía los datos personales + el
/// carrito al backend y registra la inscripción pendiente de pago.
class CheckoutViewModel extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Confirma la inscripción. Devuelve true si se registró.
  Future<bool> submit({
    required String fullName,
    required String email,
    String? phone,
    String? nationality,
    String? documentNumber,
  }) async {
    final items = ref.read(cartViewModelProvider);
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearResult: true,
    );

    final (result, failure) = await ref.read(createEnrollmentProvider)(
      CreateEnrollmentParams(
        items: items,
        data: CheckoutData(
          fullName: fullName.trim(),
          email: email.trim(),
          phone: _emptyToNull(phone),
          nationality: _emptyToNull(nationality),
          documentNumber: _emptyToNull(documentNumber),
        ),
      ),
    );

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return false;
    }

    // El total real sale del carrito (precio congelado al agregar).
    state = state.copyWith(
      isLoading: false,
      result: CheckoutResult(
        enrollmentIds: result.enrollmentIds,
        paymentIds: result.paymentIds,
        total: items.totalPrice,
      ),
    );

    // Contexto global de sesión: registrar la compra del estudiante.
    ref
        .read(sessionContextProvider.notifier)
        .record(
          'purchase',
          detail: '${items.length} curso(s) — ${formatDollars(items.totalPrice)}',
        );

    // Inscripción registrada → el carrito ya cumplió su función.
    await ref.read(cartViewModelProvider.notifier).clear();
    return true;
  }

  /// Reinicia el formulario (ej: "seguir comprando").
  void reset() => state = const CheckoutState();

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
