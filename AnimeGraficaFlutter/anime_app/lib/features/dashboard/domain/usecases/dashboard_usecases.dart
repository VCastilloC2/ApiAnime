import '../entities/dashboard_entities.dart';
import '../repositories/dashboard_repository.dart';

class GetStatsSummary {
  const GetStatsSummary(this._repo);
  final DashboardRepository _repo;
  Future<StatsSummary> call() => _repo.getSummary();
}

class GetGenreStats {
  const GetGenreStats(this._repo);
  final DashboardRepository _repo;
  Future<List<GenreStat>> call() => _repo.getByGenre();
}

class GetRatingDistribution {
  const GetRatingDistribution(this._repo);
  final DashboardRepository _repo;
  Future<List<RatingBucket>> call() => _repo.getRatingDistribution();
}

class GetCatalogPoints {
  const GetCatalogPoints(this._repo);
  final DashboardRepository _repo;
  Future<List<CatalogPoint>> call() => _repo.getCatalogPoints();
}

class PingApi {
  const PingApi(this._repo);
  final DashboardRepository _repo;
  Future<LatencySample> call() => _repo.ping();
}

/// Regresión lineal por mínimos cuadrados: rating ≈ a + b · episodios.
/// Lógica pura (sin Flutter ni red) -> trivial de testear.
class ComputeLinearRegression {
  const ComputeLinearRegression();

  RegressionResult? call(List<CatalogPoint> points) {
    final n = points.length;
    if (n < 2) return null;

    final mx = points.fold<double>(0, (s, p) => s + p.episodes) / n;
    final my = points.fold<double>(0, (s, p) => s + p.rating) / n;

    var sxx = 0.0, sxy = 0.0, syy = 0.0;
    for (final p in points) {
      final dx = p.episodes - mx;
      final dy = p.rating - my;
      sxx += dx * dx;
      sxy += dx * dy;
      syy += dy * dy;
    }
    if (sxx == 0) return null; // todos con los mismos episodios: no hay pendiente

    final slope = sxy / sxx;
    final r2 = syy == 0 ? 0.0 : (sxy * sxy) / (sxx * syy);
    return RegressionResult(slope: slope, intercept: my - slope * mx, r2: r2);
  }
}

/// Agrupa las altas (`created_at`) por mes y calcula el acumulado.
/// Si todas las altas caen en un único mes, agrupa por día para que la tendencia
/// siga siendo visible (en ese caso `TrendPoint.month` trae el día exacto).
class BuildRegistrationTrend {
  const BuildRegistrationTrend();

  List<TrendPoint> call(List<CatalogPoint> points) {
    final monthly = _group(points, (d) => DateTime(d.year, d.month));
    if (monthly.length >= 2) return monthly;
    return _group(points, (d) => DateTime(d.year, d.month, d.day));
  }

  List<TrendPoint> _group(List<CatalogPoint> points, DateTime Function(DateTime) keyOf) {
    final perKey = <DateTime, int>{};
    for (final p in points) {
      final d = p.createdAt;
      if (d == null) continue;
      final key = keyOf(d);
      perKey[key] = (perKey[key] ?? 0) + 1;
    }
    final keys = perKey.keys.toList()..sort();
    var acc = 0;
    return [
      for (final k in keys) TrendPoint(month: k, added: perKey[k]!, cumulative: acc += perKey[k]!),
    ];
  }
}
