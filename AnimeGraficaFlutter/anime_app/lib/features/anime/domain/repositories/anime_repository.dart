import '../entities/anime.dart';

/// Contrato de dominio. La UI y los casos de uso solo conocen esta interfaz;
/// la implementación (Dio, caché, mocks...) vive en la capa data.
abstract interface class AnimeRepository {
  Future<PagedResult<Anime>> getAnimes(AnimeQuery query, {required int skip, required int limit});
  Future<List<Genre>> getGenres();
  Future<List<Anime>> getTopRated({int limit = 10});
}
