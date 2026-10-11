import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/anime.dart';
import '../models/anime_model.dart';

/// Única clase que conoce las rutas HTTP de animes/géneros.
class AnimeRemoteDataSource {
  const AnimeRemoteDataSource(this._api);
  final ApiClient _api;

  Future<ApiResponse<List<AnimeModel>>> fetchAnimes(AnimeQuery q, {required int skip, required int limit}) =>
      _api.get(
        '/animes',
        query: {
          'skip': skip,
          'limit': limit,
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.genreId != null) 'genre_id': q.genreId,
          'sort_by': q.sortBy,
          'order': q.order,
        },
        parser: AnimeModel.listFromJson,
      );

  Future<ApiResponse<List<GenreModel>>> fetchGenres() =>
      _api.get('/genres', parser: GenreModel.listFromJson);

  Future<ApiResponse<List<AnimeModel>>> fetchTopRated(int limit) =>
      _api.get('/stats/top-rated', query: {'limit': limit}, parser: AnimeModel.listFromJson);
}
