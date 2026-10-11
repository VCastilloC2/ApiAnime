import 'package:equatable/equatable.dart';

class Anime extends Equatable {
  final int id;
  final String title;
  final int episodes;
  final double rating;
  final int? genreId;
  final String? genreName;
  final DateTime? createdAt;

  const Anime({
    required this.id,
    required this.title,
    required this.episodes,
    required this.rating,
    this.genreId,
    this.genreName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, episodes, rating, genreId, genreName, createdAt];
}

class Genre extends Equatable {
  final int id;
  final String name;
  const Genre({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Criterios de búsqueda. Coincide 1:1 con los query params de `GET /animes`.
class AnimeQuery extends Equatable {
  final String search;
  final int? genreId;
  final String sortBy; // id | title | rating | episodes | created_at
  final String order; // asc | desc

  const AnimeQuery({
    this.search = '',
    this.genreId,
    this.sortBy = 'id',
    this.order = 'asc',
  });

  /// `clearGenre: true` permite volver a "Todos" (null no se distingue de "no cambiar").
  AnimeQuery copyWith({String? search, int? genreId, bool clearGenre = false, String? sortBy, String? order}) =>
      AnimeQuery(
        search: search ?? this.search,
        genreId: clearGenre ? null : (genreId ?? this.genreId),
        sortBy: sortBy ?? this.sortBy,
        order: order ?? this.order,
      );

  @override
  List<Object?> get props => [search, genreId, sortBy, order];
}

/// Página de resultados + total global (cabecera `X-Total-Count`).
class PagedResult<T> {
  final List<T> items;
  final int total;
  const PagedResult({required this.items, required this.total});
}
