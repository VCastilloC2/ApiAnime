import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/floating_card.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/genre_donut_chart.dart';
import '../widgets/genre_radar_chart.dart';
import '../widgets/kpi_row.dart';
import '../widgets/latency_live_chart.dart';
import '../widgets/rating_bar_chart.dart';
import '../widgets/registration_trend_chart.dart';
import '../widgets/scatter_regression_chart.dart';

/// Dashboard analítico. Cada tarjeta observa SU provider: carga/falla de forma independiente.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _placeholderHeight = 350.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(statsSummaryProvider);
    final genres = ref.watch(genreStatsProvider);
    final ratings = ref.watch(ratingDistributionProvider);
    final catalog = ref.watch(catalogPointsProvider);

    return ResponsiveBuilder(
      builder: (context, size, _) {
        final pad = size == ScreenSize.mobile ? 16.0 : 32.0;
        return RefreshIndicator(
          onRefresh: () => refreshDashboard(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
            children: [
              ContentConstraint(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dashboard', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                              Text('Analítica del catálogo en vivo desde FastAPI',
                                  style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Actualizar',
                          onPressed: () => refreshDashboard(ref),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AsyncValueView(
                      value: summary,
                      loadingHeight: 90,
                      onRetry: () => ref.invalidate(statsSummaryProvider),
                      data: (s) => KpiRow(summary: s),
                    ),
                    const SizedBox(height: 20),
                    ResponsiveColumns(
                      children: [
                        _chart(genres, () => ref.invalidate(genreStatsProvider), (g) => GenreDonutChart(stats: g)),
                        _chart(ratings, () => ref.invalidate(ratingDistributionProvider),
                            (r) => RatingBarChart(buckets: r)),
                        _chart(
                          catalog,
                          () => ref.invalidate(catalogPointsProvider),
                          (pts) => ScatterRegressionChart(
                            points: pts,
                            regression: ref.read(computeRegressionProvider)(pts),
                          ),
                        ),
                        _chart(
                          catalog,
                          () => ref.invalidate(catalogPointsProvider),
                          (pts) => RegistrationTrendChart(trend: ref.read(buildTrendProvider)(pts)),
                        ),
                        _chart(genres, () => ref.invalidate(genreStatsProvider), (g) => GenreRadarChart(stats: g)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const LatencyLiveChart(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Placeholder con la misma silueta de tarjeta mientras carga / si falla.
  Widget _chart<T>(AsyncValue<T> value, VoidCallback retry, Widget Function(T data) builder) => value.when(
        skipLoadingOnRefresh: true,
        data: builder,
        loading: () => const FloatingCard(
          child: SizedBox(height: _placeholderHeight, child: Center(child: CircularProgressIndicator.adaptive())),
        ),
        error: (e, _) => FloatingCard(
          child: SizedBox(height: _placeholderHeight, child: ErrorView(error: e, onRetry: retry)),
        ),
      );
}
