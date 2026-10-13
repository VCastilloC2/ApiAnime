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

class CreateAnime {
  const CreateAnime(this._repo);
  final AnimeRepository _repo;
  Future<Anime> call(AnimeInput input) => _repo.createAnime(input);
}

class UpdateAnime {
  const UpdateAnime(this._repo);
  final AnimeRepository _repo;
  Future<Anime> call(int id, AnimeInput input) => _repo.updateAnime(id, input);
}

class DeleteAnime {
  const DeleteAnime(this._repo);
  final AnimeRepository _repo;
  Future<void> call(int id) => _repo.deleteAnime(id);
}

class CreateGenre {
  const CreateGenre(this._repo);
  final AnimeRepository _repo;
  Future<Genre> call(String name) => _repo.createGenre(name);
}

class RenameGenre {
  const RenameGenre(this._repo);
  final AnimeRepository _repo;
  Future<Genre> call(int id, String name) => _repo.renameGenre(id, name);
}

class DeleteGenre {
  const DeleteGenre(this._repo);
  final AnimeRepository _repo;
  Future<void> call(int id) => _repo.deleteGenre(id);
}
