import '../entities/dashboard_entities.dart';

abstract interface class DashboardRepository {
  Future<StatsSummary> getSummary();
  Future<List<GenreStat>> getByGenre();
  Future<List<RatingBucket>> getRatingDistribution();

  /// Hasta [limit] animes (máx. 200 por la API) en forma ligera, para scatter y tendencia.
  Future<List<CatalogPoint>> getCatalogPoints({int limit = 200});

  /// Una medición de latencia contra `/health`.
  Future<LatencySample> ping();
}
