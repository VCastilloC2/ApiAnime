import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../models/anime_response.dart';

class AnimeApiClient {
  final http.Client _client;

  AnimeApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  // FastAPI no manda charset: se decodifica explícitamente como UTF-8
  // para no romper tildes y ñ.
  dynamic _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<List<AnimeResponse>> getAnimes({
    String? search,
    int? genreId,
    int limit = 100,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (genreId != null) query['genre_id'] = '$genreId';
    final res = await _client.get(_uri('/animes', query));
    final data = _decode(res) as List;
    return data
        .map((e) => AnimeResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GenreResponse>> getGenres() async {
    final res = await _client.get(_uri('/genres'));
    final data = _decode(res) as List;
    return data
        .map((e) => GenreResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnimeResponse> createAnime({
    required String title,
    required int episodes,
    required double rating,
    int? genreId,
  }) async {
    final res = await _client.post(
      _uri('/animes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'episodes': episodes,
        'rating': rating,
        'genre_id': genreId,
      }),
    );
    return AnimeResponse.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteAnime(int id) async {
    final res = await _client.delete(_uri('/animes/$id'));
    if (res.statusCode != 204) _decode(res);
  }

  Future<List<GenreStatResponse>> getStatsByGenre() async {
    final res = await _client.get(_uri('/stats/by-genre'));
    final data = _decode(res) as List;
    return data
        .map((e) => GenreStatResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
