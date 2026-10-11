import '../../domain/entities/anime.dart';

class AnimeResponse extends Anime {
  const AnimeResponse({
    required super.id,
    required super.title,
    required super.episodes,
    required super.rating,
    super.genreId,
    super.genreName,
  });

  factory AnimeResponse.fromJson(Map<String, dynamic> json) => AnimeResponse(
        id: json['id'] as int,
        title: json['title'] as String,
        episodes: json['episodes'] as int,
        rating: (json['rating'] as num).toDouble(),
        genreId: json['genre_id'] as int?,
        genreName: json['genre_name'] as String?,
      );
}

class GenreResponse extends Genre {
  const GenreResponse({required super.id, required super.name});

  factory GenreResponse.fromJson(Map<String, dynamic> json) =>
      GenreResponse(id: json['id'] as int, name: json['name'] as String);
}

class GenreStatResponse extends GenreStat {
  const GenreStatResponse({
    required super.genre,
    required super.totalAnimes,
    required super.avgRating,
    required super.totalEpisodes,
  });

  factory GenreStatResponse.fromJson(Map<String, dynamic> json) =>
      GenreStatResponse(
        genre: json['genre'] as String,
        totalAnimes: json['total_animes'] as int,
        avgRating: (json['avg_rating'] as num).toDouble(),
        totalEpisodes: json['total_episodes'] as int,
      );
}
