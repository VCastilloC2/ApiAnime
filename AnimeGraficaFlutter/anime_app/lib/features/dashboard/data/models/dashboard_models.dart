import '../../domain/entities/dashboard_entities.dart';

class StatsSummaryModel extends StatsSummary {
  const StatsSummaryModel({
    required super.totalAnimes,
    required super.totalGenres,
    required super.animesWithoutGenre,
    required super.avgRating,
    required super.totalEpisodes,
  });

  factory StatsSummaryModel.fromJson(dynamic json) {
    final j = json as Map<String, dynamic>;
    return StatsSummaryModel(
      totalAnimes: j['total_animes'] as int,
      totalGenres: j['total_genres'] as int,
      animesWithoutGenre: j['animes_without_genre'] as int,
      avgRating: (j['avg_rating'] as num).toDouble(),
      totalEpisodes: j['total_episodes'] as int,
    );
  }
}

class GenreStatModel extends GenreStat {
  const GenreStatModel({
    required super.genre,
    required super.totalAnimes,
    required super.avgRating,
    required super.totalEpisodes,
  });

  factory GenreStatModel.fromJson(Map<String, dynamic> j) => GenreStatModel(
        genre: j['genre'] as String,
        totalAnimes: j['total_animes'] as int,
        avgRating: (j['avg_rating'] as num).toDouble(),
        totalEpisodes: j['total_episodes'] as int,
      );

  static List<GenreStatModel> listFromJson(dynamic json) =>
      (json as List).map((e) => GenreStatModel.fromJson(e as Map<String, dynamic>)).toList();
}

class RatingBucketModel extends RatingBucket {
  const RatingBucketModel({required super.label, required super.total});

  factory RatingBucketModel.fromJson(Map<String, dynamic> j) =>
      RatingBucketModel(label: j['label'] as String, total: j['total'] as int);

  static List<RatingBucketModel> listFromJson(dynamic json) =>
      (json as List).map((e) => RatingBucketModel.fromJson(e as Map<String, dynamic>)).toList();
}

class CatalogPointModel extends CatalogPoint {
  const CatalogPointModel({required super.episodes, required super.rating, super.createdAt});

  factory CatalogPointModel.fromJson(Map<String, dynamic> j) => CatalogPointModel(
        episodes: j['episodes'] as int,
        rating: (j['rating'] as num).toDouble(),
        createdAt: j['created_at'] == null ? null : DateTime.tryParse(j['created_at'] as String),
      );

  static List<CatalogPointModel> listFromJson(dynamic json) =>
      (json as List).map((e) => CatalogPointModel.fromJson(e as Map<String, dynamic>)).toList();
}
