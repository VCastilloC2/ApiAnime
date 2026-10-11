import 'package:equatable/equatable.dart';

class Anime extends Equatable {
  final int id;
  final String title;
  final int episodes;
  final double rating;
  final int? genreId;
  final String? genreName;

  const Anime({
    required this.id,
    required this.title,
    required this.episodes,
    required this.rating,
    this.genreId,
    this.genreName,
  });

  @override
  List<Object?> get props => [id, title, episodes, rating, genreId, genreName];
}

class Genre extends Equatable {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

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
