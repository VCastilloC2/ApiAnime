import 'package:anime_pulse/core/error/failures.dart';
import 'package:anime_pulse/core/network/interceptors/error_interceptor.dart';
import 'package:anime_pulse/features/anime/data/models/anime_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _bad(int status, dynamic body) {
  final opts = RequestOptions(path: '/animes');
  return DioException(
    requestOptions: opts,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: opts, statusCode: status, data: body),
  );
}

void main() {
  test('AnimeModel.fromJson mapea la respuesta de FastAPI', () {
    final a = AnimeModel.fromJson({
      'id': 1,
      'title': 'Hellsing Ultimate',
      'episodes': 10,
      'rating': 8, // FastAPI puede mandar int
      'genre_id': 2,
      'genre_name': 'Acción',
      'created_at': '2026-09-01T10:00:00',
    });
    expect(a.rating, 8.0);
    expect(a.genreName, 'Acción');
    expect(a.createdAt, DateTime(2026, 9, 1, 10));
  });

  test('AnimeModel.fromJson tolera genre y fecha nulos', () {
    final a = AnimeModel.fromJson({'id': 1, 'title': 'X', 'episodes': 1, 'rating': 5.5});
    expect(a.genreId, isNull);
    expect(a.createdAt, isNull);
  });

  group('ErrorInterceptor.map', () {
    final i = ErrorInterceptor();

    test('404 con detail string -> NotFoundFailure', () {
      final f = i.map(_bad(404, {'detail': 'Anime no encontrado'}));
      expect(f, isA<NotFoundFailure>());
      expect(f.message, 'Anime no encontrado');
    });

    test('422 de Pydantic -> ValidationFailure con campos', () {
      final f = i.map(_bad(422, {
        'detail': [
          {'loc': ['body', 'title'], 'msg': 'Field required', 'type': 'missing'},
        ],
      })) as ValidationFailure;
      expect(f.fieldErrors['title'], 'Field required');
    });

    test('503 -> ServerFailure con statusCode', () {
      final f = i.map(_bad(503, {'detail': 'No se pudo comunicar con la base de datos.'})) as ServerFailure;
      expect(f.statusCode, 503);
    });

    test('timeout y conexión', () {
      final opts = RequestOptions(path: '/');
      expect(i.map(DioException(requestOptions: opts, type: DioExceptionType.receiveTimeout)), isA<TimeoutFailure>());
      expect(i.map(DioException(requestOptions: opts, type: DioExceptionType.connectionError)), isA<NetworkFailure>());
    });
  });
}
