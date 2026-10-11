import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/dashboard_models.dart';

/// Rutas de estadísticas de FastAPI (`/stats/*`) + `/health` y `/animes`.
class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._api);
  final ApiClient _api;

  Future<ApiResponse<StatsSummaryModel>> fetchSummary() =>
      _api.get('/stats/summary', parser: StatsSummaryModel.fromJson);

  Future<ApiResponse<List<GenreStatModel>>> fetchByGenre() =>
      _api.get('/stats/by-genre', parser: GenreStatModel.listFromJson);

  Future<ApiResponse<List<RatingBucketModel>>> fetchRatingDistribution() =>
      _api.get('/stats/rating-distribution', parser: RatingBucketModel.listFromJson);

  Future<ApiResponse<List<CatalogPointModel>>> fetchCatalog(int limit) =>
      _api.get('/animes', query: {'limit': limit, 'sort_by': 'created_at', 'order': 'asc'},
          parser: CatalogPointModel.listFromJson);

  /// El cuerpo no importa; interesan las cabeceras y el tiempo medido.
  Future<ApiResponse<Object?>> ping() => _api.get('/health', parser: (json) => json);
}
