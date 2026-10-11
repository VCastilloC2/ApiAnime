import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Busca portadas por título en la API pública de AniList (GraphQL, sin API key,
/// con CORS habilitado para Flutter Web). Si no hay resultado devuelve `null`
/// y la UI muestra un degradado.
class CoverService {
  CoverService(this._dio);

  final Dio _dio;

  static const _query = r'''
query ($search: String) {
  Media(search: $search, type: ANIME, sort: SEARCH_MATCH) {
    coverImage { extraLarge large }
  }
}''';

  final _cache = <String, Future<String?>>{};

  // AniList permite ~90 peticiones/min: se espacian y se serializan.
  Future<void> _tail = Future.value();
  static const _gap = Duration(milliseconds: 700);

  Future<String?> coverFor(String title) {
    final key = title.trim().toLowerCase();
    if (key.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(key, () => _enqueue(title.trim()));
  }

  Future<String?> _enqueue(String title) {
    final completer = Completer<String?>();
    _tail = _tail.then((_) async {
      completer.complete(await _fetch(title));
      await Future<void>.delayed(_gap);
    });
    return completer.future;
  }

  Future<String?> _fetch(String title, {int attempt = 0}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        'https://graphql.anilist.co',
        data: {'query': _query, 'variables': {'search': title}},
        options: Options(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}),
      );
      final cover = (res.data?['data']?['Media']?['coverImage']) as Map?;
      return (cover?['extraLarge'] ?? cover?['large']) as String?;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429 && attempt < 2) {
        final wait = int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 20;
        await Future<void>.delayed(Duration(seconds: wait.clamp(1, 60)));
        return _fetch(title, attempt: attempt + 1);
      }
      return null; // 404 = sin portada; otros errores: degradado.
    } catch (_) {
      return null;
    }
  }
}

final coverServiceProvider = Provider<CoverService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  ref.onDispose(dio.close);
  return CoverService(dio);
});

/// URL de la portada para un título (null = usar degradado). Se cachea por título.
final coverUrlProvider = FutureProvider.family<String?, String>(
  (ref, title) => ref.watch(coverServiceProvider).coverFor(title),
);
