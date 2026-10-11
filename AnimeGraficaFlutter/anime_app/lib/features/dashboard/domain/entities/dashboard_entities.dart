import 'package:equatable/equatable.dart';

/// `GET /stats/summary`
class StatsSummary extends Equatable {
  final int totalAnimes;
  final int totalGenres;
  final int animesWithoutGenre;
  final double avgRating;
  final int totalEpisodes;

  const StatsSummary({
    required this.totalAnimes,
    required this.totalGenres,
    required this.animesWithoutGenre,
    required this.avgRating,
    required this.totalEpisodes,
  });

  @override
  List<Object?> get props => [totalAnimes, totalGenres, animesWithoutGenre, avgRating, totalEpisodes];
}

/// `GET /stats/by-genre`
class GenreStat extends Equatable {
  final String genre;
  final int totalAnimes;
  final double avgRating;
  final int totalEpisodes;

  const GenreStat({
    required this.genre,
    required this.totalAnimes,
    required this.avgRating,
    required this.totalEpisodes,
  });

  @override
  List<Object?> get props => [genre, totalAnimes, avgRating, totalEpisodes];
}

/// `GET /stats/rating-distribution`
class RatingBucket extends Equatable {
  final String label;
  final int total;
  const RatingBucket({required this.label, required this.total});

  @override
  List<Object?> get props => [label, total];
}

/// Punto ligero del catálogo (episodios, rating, fecha de alta) para análisis en cliente.
class CatalogPoint extends Equatable {
  final int episodes;
  final double rating;
  final DateTime? createdAt;
  const CatalogPoint({required this.episodes, required this.rating, this.createdAt});

  @override
  List<Object?> get props => [episodes, rating, createdAt];
}

/// Una medición del monitor de latencia (`GET /health`).
class LatencySample extends Equatable {
  final DateTime at;

  /// Cabecera `X-Process-Time-ms`: lo que tardó FastAPI.
  final double serverMs;

  /// Ida y vuelta medido en el cliente (red + servidor).
  final int roundTripMs;

  const LatencySample({required this.at, required this.serverMs, required this.roundTripMs});

  @override
  List<Object?> get props => [at, serverMs, roundTripMs];
}

class RegressionResult extends Equatable {
  final double slope;
  final double intercept;
  final double r2;
  const RegressionResult({required this.slope, required this.intercept, required this.r2});

  double predict(double x) => intercept + slope * x;

  @override
  List<Object?> get props => [slope, intercept, r2];
}

/// Altas del catálogo agrupadas por mes.
class TrendPoint extends Equatable {
  final DateTime month; // día 1 del mes
  final int added;
  final int cumulative;
  const TrendPoint({required this.month, required this.added, required this.cumulative});

  @override
  List<Object?> get props => [month, added, cumulative];
}
