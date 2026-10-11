import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/dashboard_usecases.dart';

// ───────────── DI ─────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(DashboardRemoteDataSource(ref.watch(apiClientProvider))),
);

final getStatsSummaryProvider = Provider((ref) => GetStatsSummary(ref.watch(dashboardRepositoryProvider)));
final getGenreStatsProvider = Provider((ref) => GetGenreStats(ref.watch(dashboardRepositoryProvider)));
final getRatingDistributionProvider =
    Provider((ref) => GetRatingDistribution(ref.watch(dashboardRepositoryProvider)));
final getCatalogPointsProvider = Provider((ref) => GetCatalogPoints(ref.watch(dashboardRepositoryProvider)));
final pingApiProvider = Provider((ref) => PingApi(ref.watch(dashboardRepositoryProvider)));

// Casos de uso puros (sin dependencias).
final computeRegressionProvider = Provider((_) => const ComputeLinearRegression());
final buildTrendProvider = Provider((_) => const BuildRegistrationTrend());

// ───────────── Datos: un provider por tarjeta ─────────────
// Cada gráfico carga y falla de forma independiente: si /stats/by-genre cae,
// el resto del dashboard sigue funcionando.
final statsSummaryProvider = FutureProvider<StatsSummary>((ref) => ref.watch(getStatsSummaryProvider)());
final genreStatsProvider = FutureProvider<List<GenreStat>>((ref) => ref.watch(getGenreStatsProvider)());
final ratingDistributionProvider =
    FutureProvider<List<RatingBucket>>((ref) => ref.watch(getRatingDistributionProvider)());
final catalogPointsProvider = FutureProvider<List<CatalogPoint>>((ref) => ref.watch(getCatalogPointsProvider)());

/// Recarga todo el dashboard (pull-to-refresh / botón).
Future<void> refreshDashboard(WidgetRef ref) async {
  await Future.wait([
    ref.refresh(statsSummaryProvider.future),
    ref.refresh(genreStatsProvider.future),
    ref.refresh(ratingDistributionProvider.future),
    ref.refresh(catalogPointsProvider.future),
  ]);
}

// ───────────── Monitor de latencia en tiempo real ─────────────
class LatencyState {
  final List<LatencySample> samples;
  final bool running;
  final Failure? error;

  const LatencyState({this.samples = const [], this.running = true, this.error});

  LatencyState copyWith({List<LatencySample>? samples, bool? running, Failure? error, bool clearError = false}) =>
      LatencyState(
        samples: samples ?? this.samples,
        running: running ?? this.running,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Sondea `/health` cada [Env.latencyPollInterval]. Al ser autoDispose, el timer
/// se cancela solo cuando el usuario sale del Dashboard (cero tráfico en segundo plano).
class LatencyMonitor extends AutoDisposeNotifier<LatencyState> {
  static const _maxSamples = 30;
  Timer? _timer;
  bool _inFlight = false;
  bool _disposed = false;

  @override
  LatencyState build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    _startTimer();
    Future.microtask(_tick); // primera medición inmediata
    return const LatencyState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Env.latencyPollInterval, (_) => _tick());
  }

  void toggle() {
    if (state.running) {
      _timer?.cancel();
      state = state.copyWith(running: false);
    } else {
      _startTimer();
      state = state.copyWith(running: true);
      _tick();
    }
  }

  Future<void> _tick() async {
    if (_inFlight || _disposed) return; // evita solapar si el servidor está lento
    _inFlight = true;
    try {
      final sample = await ref.read(pingApiProvider)();
      if (_disposed) return;
      final all = [...state.samples, sample];
      state = state.copyWith(
        samples: all.length > _maxSamples ? all.sublist(all.length - _maxSamples) : all,
        clearError: true,
      );
    } on Failure catch (f) {
      if (!_disposed) state = state.copyWith(error: f);
    } finally {
      _inFlight = false;
    }
  }
}

final latencyMonitorProvider =
    AutoDisposeNotifierProvider<LatencyMonitor, LatencyState>(LatencyMonitor.new);
