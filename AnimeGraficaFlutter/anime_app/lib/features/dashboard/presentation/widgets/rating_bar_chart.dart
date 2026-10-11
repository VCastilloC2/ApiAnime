import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'chart_card.dart';

/// BÁSICO · Distribución de puntuaciones (`/stats/rating-distribution`).
class RatingBarChart extends StatelessWidget {
  const RatingBarChart({super.key, required this.buckets});
  final List<RatingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxY = buckets.fold<int>(0, (m, b) => b.total > m ? b.total : m);
    final top = (maxY == 0 ? 1 : maxY) * 1.2;
    return ChartCard(
      title: 'Puntuaciones',
      subtitle: 'Animes por rango de rating',
      child: maxY == 0
          ? const ChartEmpty('Sin datos de puntuación.')
          : BarChart(
              BarChartData(
                maxY: top,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: top / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: top / 4,
                      getTitlesWidget: (v, _) => Text(v.round().toString(), style: axisStyle(context)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(buckets[i].label, style: axisStyle(context)),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${buckets[group.x].label}\n${rod.toY.round()} animes',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
                barGroups: [
                  for (final (i, b) in buckets.indexed)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: b.total.toDouble(),
                          width: 22,
                          gradient: AppColors.accentGradient,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
