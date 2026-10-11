import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'chart_card.dart';

/// AVANZADO · Perfil comparativo de los 6 géneros con más animes.
/// Dos series normalizadas a 0-100: volumen (vs. el máximo) y rating medio (sobre 10).
class GenreRadarChart extends StatelessWidget {
  const GenreRadarChart({super.key, required this.stats});
  final List<GenreStat> stats;

  @override
  Widget build(BuildContext context) {
    final top = ([...stats]..sort((a, b) => b.totalAnimes.compareTo(a.totalAnimes))).take(6).toList();
    final maxCount = top.isEmpty ? 1 : top.first.totalAnimes;

    RadarDataSet set(Color c, double Function(GenreStat) value) => RadarDataSet(
          fillColor: c.withValues(alpha: .2),
          borderColor: c,
          borderWidth: 2.5,
          entryRadius: 3,
          dataEntries: [for (final g in top) RadarEntry(value: value(g))],
        );

    return ChartCard(
      title: 'Perfil por género',
      subtitle: 'Volumen vs. rating medio (escala 0–100)',
      trailing: const Wrap(
        spacing: 12,
        children: [
          _Legend(color: AppColors.coral, label: 'Volumen'),
          _Legend(color: Color(0xFF3C7DD9), label: 'Rating'),
        ],
      ),
      child: top.length < 3
          ? const ChartEmpty('Se necesitan al menos 3 géneros con animes\npara el radar.')
          : RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                tickBorderData: BorderSide(color: Theme.of(context).dividerColor),
                gridBorderData: BorderSide(color: Theme.of(context).dividerColor),
                radarBorderData: BorderSide(color: Theme.of(context).dividerColor),
                titlePositionPercentageOffset: .16,
                titleTextStyle: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                getTitle: (i, _) => RadarChartTitle(text: top[i].genre),
                dataSets: [
                  set(AppColors.coral, (g) => g.totalAnimes / maxCount * 100),
                  set(const Color(0xFF3C7DD9), (g) => g.avgRating / 10 * 100),
                ],
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
