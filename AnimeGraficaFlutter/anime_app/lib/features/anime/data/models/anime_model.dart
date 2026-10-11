import '../../domain/entities/anime.dart';

/// Modelo de datos = entidad + (de)serialización. Mapea `AnimeResponse` de FastAPI.
class AnimeModel extends Anime {
  const AnimeModel({
    required super.id,
    required super.title,
    required super.episodes,
    required super.rating,
    super.genreId,
    super.genreName,
    super.createdAt,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) => AnimeModel(
        id: json['id'] as int,
        title: json['title'] as String,
        episodes: json['episodes'] as int,
        rating: (json['rating'] as num).toDouble(),
        genreId: json['genre_id'] as int?,
        genreName: json['genre_name'] as String?,
        createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'] as String),
      );

  static List<AnimeModel> listFromJson(dynamic json) =>
      (json as List).map((e) => AnimeModel.fromJson(e as Map<String, dynamic>)).toList();
}

class GenreModel extends Genre {
  const GenreModel({required super.id, required super.name});

  factory GenreModel.fromJson(Map<String, dynamic> json) =>
      GenreModel(id: json['id'] as int, name: json['name'] as String);

  static List<GenreModel> listFromJson(dynamic json) =>
      (json as List).map((e) => GenreModel.fromJson(e as Map<String, dynamic>)).toList();
}
