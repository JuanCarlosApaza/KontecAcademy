import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/checkout_repository_impl.dart';
import 'domain/usecases/create_enrollment.dart';

/// Composition root del feature `checkout`.
export 'data/repositories/checkout_repository_impl.dart'
    show checkoutRepositoryProvider;
export 'domain/entities/checkout_data.dart' show CheckoutData;
export 'domain/entities/checkout_result.dart' show CheckoutResult;
export 'domain/usecases/create_enrollment.dart'
    show CreateEnrollment, CreateEnrollmentParams;

final createEnrollmentProvider = Provider<CreateEnrollment>(
  (ref) => CreateEnrollment(ref.watch(checkoutRepositoryProvider)),
);
