import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/anime_api_client.dart';
import '../../domain/entities/anime.dart';

// ---------- Eventos ----------
abstract class AnimeEvent extends Equatable {
  const AnimeEvent();
  @override
  List<Object?> get props => [];
}

class AnimesLoaded extends AnimeEvent {
  final String search;
  const AnimesLoaded({this.search = ''});
  @override
  List<Object?> get props => [search];
}

class AnimeAdded extends AnimeEvent {
  final String title;
  final int episodes;
  final double rating;
  final int? genreId;
  const AnimeAdded({
    required this.title,
    required this.episodes,
    required this.rating,
    this.genreId,
  });
  @override
  List<Object?> get props => [title, episodes, rating, genreId];
}

class AnimeDeleted extends AnimeEvent {
  final int id;
  const AnimeDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

// ---------- Estado ----------
enum AnimeStatus { initial, loading, success, failure }

class AnimeState extends Equatable {
  final AnimeStatus status;
  final List<Anime> animes;
  final String search;
  final String? error;

  const AnimeState({
    this.status = AnimeStatus.initial,
    this.animes = const [],
    this.search = '',
    this.error,
  });

  AnimeState copyWith({
    AnimeStatus? status,
    List<Anime>? animes,
    String? search,
    String? error,
  }) =>
      AnimeState(
        status: status ?? this.status,
        animes: animes ?? this.animes,
        search: search ?? this.search,
        error: error,
      );

  @override
  List<Object?> get props => [status, animes, search, error];
}

// ---------- Bloc ----------
class AnimeBloc extends Bloc<AnimeEvent, AnimeState> {
  final AnimeApiClient _api;

  AnimeBloc(this._api) : super(const AnimeState()) {
    on<AnimesLoaded>((e, emit) => _load(emit, e.search));
    on<AnimeAdded>(_onAdded);
    on<AnimeDeleted>(_onDeleted);
  }

  Future<void> _load(Emitter<AnimeState> emit, String search) async {
    emit(state.copyWith(status: AnimeStatus.loading, search: search));
    try {
      final animes = await _api.getAnimes(search: search);
      emit(state.copyWith(status: AnimeStatus.success, animes: animes));
    } catch (e) {
      emit(state.copyWith(status: AnimeStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onAdded(AnimeAdded e, Emitter<AnimeState> emit) async {
    try {
      await _api.createAnime(
        title: e.title,
        episodes: e.episodes,
        rating: e.rating,
        genreId: e.genreId,
      );
      await _load(emit, state.search);
    } catch (err) {
      emit(state.copyWith(status: AnimeStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onDeleted(AnimeDeleted e, Emitter<AnimeState> emit) async {
    try {
      await _api.deleteAnime(e.id);
      await _load(emit, state.search);
    } catch (err) {
      emit(state.copyWith(status: AnimeStatus.failure, error: err.toString()));
    }
  }
}
