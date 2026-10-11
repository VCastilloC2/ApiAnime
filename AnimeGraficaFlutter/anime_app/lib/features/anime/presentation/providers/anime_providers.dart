import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/anime_remote_datasource.dart';
import '../../data/repositories/anime_repository_impl.dart';
import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';
import '../../domain/usecases/anime_usecases.dart';

// ───────────── Inyección de dependencias (data -> domain) ─────────────
final animeRepositoryProvider = Provider<AnimeRepository>(
  (ref) => AnimeRepositoryImpl(AnimeRemoteDataSource(ref.watch(apiClientProvider))),
);

final getAnimesProvider = Provider((ref) => GetAnimes(ref.watch(animeRepositoryProvider)));
final getGenresProvider = Provider((ref) => GetGenres(ref.watch(animeRepositoryProvider)));
final getTopRatedProvider = Provider((ref) => GetTopRated(ref.watch(animeRepositoryProvider)));

// ───────────── Estado ─────────────
final genresProvider = FutureProvider<List<Genre>>((ref) => ref.watch(getGenresProvider)());

final topRatedProvider = FutureProvider<List<Anime>>((ref) => ref.watch(getTopRatedProvider)(limit: 20));

class AnimeListState {
  final List<Anime> items;
  final int total;
  final AnimeQuery query;
  final bool loadingMore;
  final bool hasLoadMoreError;

  const AnimeListState({
    required this.items,
    required this.total,
    required this.query,
    this.loadingMore = false,
    this.hasLoadMoreError = false,
  });

  bool get hasMore => items.length < total;

  AnimeListState copyWith({
    List<Anime>? items,
    int? total,
    bool? loadingMore,
    bool? hasLoadMoreError,
  }) =>
      AnimeListState(
        items: items ?? this.items,
        total: total ?? this.total,
        query: query,
        loadingMore: loadingMore ?? this.loadingMore,
        hasLoadMoreError: hasLoadMoreError ?? this.hasLoadMoreError,
      );
}

/// Fuente de verdad de los filtros. Al cambiar, [animeListProvider] se reconstruye solo
/// y vuelve a la página 1 (Riverpod conserva el dato previo mientras carga).
class AnimeQueryNotifier extends Notifier<AnimeQuery> {
  @override
  AnimeQuery build() => const AnimeQuery();

  void update(AnimeQuery Function(AnimeQuery current) change) => state = change(state);
}

final animeQueryProvider = NotifierProvider<AnimeQueryNotifier, AnimeQuery>(AnimeQueryNotifier.new);

/// Lista paginada (scroll infinito) con búsqueda y filtro por género.
class AnimeListNotifier extends AsyncNotifier<AnimeListState> {
  static const _pageSize = 24;

  @override
  Future<AnimeListState> build() async {
    final query = ref.watch(animeQueryProvider);
    final page = await ref.read(getAnimesProvider)(query, skip: 0, limit: _pageSize);
    return AnimeListState(items: page.items, total: page.total, query: query);
  }

  /// Pide la siguiente página; un fallo NO destruye la lista ya cargada.
  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading || current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(loadingMore: true, hasLoadMoreError: false));
    try {
      final page = await ref.read(getAnimesProvider)(
        current.query,
        skip: current.items.length,
        limit: _pageSize,
      );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...page.items],
        total: page.total,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false, hasLoadMoreError: true));
    }
  }
}

final animeListProvider =
    AsyncNotifierProvider<AnimeListNotifier, AnimeListState>(AnimeListNotifier.new);
