import '../../../../core/error/guard.dart';
import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';
import '../datasources/anime_remote_datasource.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  const AnimeRepositoryImpl(this._remote);
  final AnimeRemoteDataSource _remote;

  @override
  Future<PagedResult<Anime>> getAnimes(AnimeQuery query, {required int skip, required int limit}) =>
      guardFailure(() async {
        final res = await _remote.fetchAnimes(query, skip: skip, limit: limit);
        return PagedResult<Anime>(items: res.data, total: res.totalCount ?? res.data.length);
      });

  @override
  Future<List<Genre>> getGenres() => guardFailure(() async => (await _remote.fetchGenres()).data);

  @override
  Future<List<Anime>> getTopRated({int limit = 10}) =>
      guardFailure(() async => (await _remote.fetchTopRated(limit)).data);
}
