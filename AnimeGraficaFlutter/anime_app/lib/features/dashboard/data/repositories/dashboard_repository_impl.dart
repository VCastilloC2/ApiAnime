import '../../../../core/error/guard.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);
  final DashboardRemoteDataSource _remote;

  @override
  Future<StatsSummary> getSummary() => guardFailure(() async => (await _remote.fetchSummary()).data);

  @override
  Future<List<GenreStat>> getByGenre() => guardFailure(() async => (await _remote.fetchByGenre()).data);

  @override
  Future<List<RatingBucket>> getRatingDistribution() =>
      guardFailure(() async => (await _remote.fetchRatingDistribution()).data);

  @override
  Future<List<CatalogPoint>> getCatalogPoints({int limit = 200}) =>
      guardFailure(() async => (await _remote.fetchCatalog(limit)).data);

  @override
  Future<LatencySample> ping() => guardFailure(() async {
        final res = await _remote.ping();
        return LatencySample(
          at: DateTime.now(),
          serverMs: res.serverTimeMs ?? 0,
          roundTripMs: res.roundTripMs,
        );
      });
}
