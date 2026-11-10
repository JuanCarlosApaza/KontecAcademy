import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/entities/learning_path.dart';
import '../../landing_injector.dart';

/// STATE: todo lo que la pantalla /rutas necesita para pintarse.
class RutasState {
  const RutasState({
    this.paths = const [],
    this.isLoading = false,
    this.error,
  });

  final List<LearningPath> paths;
  final bool isLoading;
  final Failure? error;

  RutasState copyWith({
    List<LearningPath>? paths,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) => RutasState(
    paths: paths ?? this.paths,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// ViewModel (MVVM) de la pantalla de Rutas de Entrenamiento.
class RutasViewModel extends Notifier<RutasState> {
  @override
  RutasState build() {
    // Reacciona a login/logout: sin este watch, si la primera carga
    // falló (p. ej. red caída) la pantalla quedaría congelada en error
    // aunque el usuario inicie sesión después. authUserProvider emite
    // en cada cambio de sesión (más seguro que el token: no toca
    // Supabase directamente).
    ref.watch(authUserProvider);
    Future.microtask(loadPaths);
    return const RutasState(isLoading: true);
  }

  /// Carga las rutas publicadas desde la API real.
  Future<void> loadPaths() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final (paths, failure) = await ref.read(getLearningPathsProvider)(
      NoParams(),
    );
    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }

    state = state.copyWith(isLoading: false, paths: paths);
  }
}

final rutasViewModelProvider =
    NotifierProvider<RutasViewModel, RutasState>(RutasViewModel.new);

/// Detalle de una ruta (/rutas/:slug): null = no existe (404),
/// [Failure] = error real. Se invalida al volver a la lista.
final rutaDetailProvider = FutureProvider.autoDispose
    .family<LearningPath?, String>((ref, slug) async {
      final (path, failure) = await ref.watch(
        getLearningPathBySlugProvider,
      )(slug);
      if (failure != null) throw failure;
      return path;
    });
