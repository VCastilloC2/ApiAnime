import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'chart_card.dart';

/// BÁSICO · Distribución de géneros (`/stats/by-genre`). Toca una porción para resaltarla.
class GenreDonutChart extends StatefulWidget {
  const GenreDonutChart({super.key, required this.stats});
  final List<GenreStat> stats;

  @override
  State<GenreDonutChart> createState() => _GenreDonutChartState();
}

class _GenreDonutChartState extends State<GenreDonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final total = stats.fold<int>(0, (s, e) => s + e.totalAnimes);
    return ChartCard(
      title: 'Distribución por género',
      subtitle: 'Animes por categoría',
      height: 280,
      child: stats.isEmpty || total == 0
          ? const ChartEmpty('Aún no hay animes con género.')
          : Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 52,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, resp) => setState(() {
                              _touched = (!event.isInterestedForInteractions || resp?.touchedSection == null)
                                  ? -1
                                  : resp!.touchedSection!.touchedSectionIndex;
                            }),
                          ),
                          sections: [
                            for (final (i, s) in stats.indexed)
                              PieChartSectionData(
                                value: s.totalAnimes.toDouble(),
                                color: AppColors.chart[i % AppColors.chart.length],
                                radius: i == _touched ? 62 : 52,
                                showTitle: s.totalAnimes / total > .08,
                                title: '${(s.totalAnimes / total * 100).round()}%',
                                titleStyle: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_touched >= 0 ? '${stats[_touched].totalAnimes}' : '$total',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                          Text(_touched >= 0 ? stats[_touched].genre : 'animes',
                              style: axisStyle(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Leyenda con scroll por si hay muchos géneros.
                SizedBox(
                  width: 120,
                  child: ListView(
                    children: [
                      for (final (i, s) in stats.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: AppColors.chart[i % AppColors.chart.length]),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.genre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
