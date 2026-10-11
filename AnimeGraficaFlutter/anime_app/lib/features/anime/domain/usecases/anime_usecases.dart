import '../entities/anime.dart';
import '../repositories/anime_repository.dart';

/// Un caso de uso = una intención de negocio, invocable como función.
class GetAnimes {
  const GetAnimes(this._repo);
  final AnimeRepository _repo;

  Future<PagedResult<Anime>> call(AnimeQuery query, {required int skip, int limit = 24}) =>
      _repo.getAnimes(query, skip: skip, limit: limit);
}

class GetGenres {
  const GetGenres(this._repo);
  final AnimeRepository _repo;
  Future<List<Genre>> call() => _repo.getGenres();
}

class GetTopRated {
  const GetTopRated(this._repo);
  final AnimeRepository _repo;
  Future<List<Anime>> call({int limit = 10}) => _repo.getTopRated(limit: limit);
}
