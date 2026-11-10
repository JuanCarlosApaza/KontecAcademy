import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/membership_plan.dart';
import '../../landing_injector.dart';

/// Planes de membresía activos (pantalla /membresias).
/// FutureProvider: se invalida para recargar; sin sesión (público).
final membershipPlansProvider = FutureProvider<List<MembershipPlan>>((
  ref,
) async {
  final (plans, failure) = await ref.watch(getMembershipPlansProvider)(
    NoParams(),
  );
  if (failure != null) throw failure;
  return plans;
});
