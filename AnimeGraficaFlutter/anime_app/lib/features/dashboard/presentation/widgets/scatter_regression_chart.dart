import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'chart_card.dart';

/// AVANZADO / PREDICTIVO · Episodios vs. rating con recta de mínimos cuadrados.
///
/// Se dibuja con un único `LineChart` (puntos = serie sin línea + recta = 2ª serie)
/// para que ambos compartan ejes exactamente.
class ScatterRegressionChart extends StatelessWidget {
  const ScatterRegressionChart({super.key, required this.points, required this.regression});
  final List<CatalogPoint> points;
  final RegressionResult? regression;

  @override
  Widget build(BuildContext context) {
    final maxX = points.isEmpty ? 1.0 : points.map((p) => p.episodes).reduce((a, b) => a > b ? a : b).toDouble();
    final xEnd = maxX * 1.05;
    final reg = regression;

    return ChartCard(
      title: 'Episodios vs. rating',
      subtitle: reg == null
          ? 'Tendencia lineal (mínimos cuadrados)'
          : 'rating ≈ ${reg.intercept.toStringAsFixed(2)} ${reg.slope >= 0 ? '+' : '−'} '
              '${reg.slope.abs().toStringAsFixed(4)}·eps   ·   R² = ${reg.r2.toStringAsFixed(2)}',
      child: points.length < 2
          ? const ChartEmpty('Se necesitan al menos 2 animes.')
          : LineChart(
              LineChartData(
                minX: 0,
                maxX: xEnd,
                minY: 0,
                maxY: 10,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [4, 4]),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text('Rating', style: axisStyle(context)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 2,
                      getTitlesWidget: (v, _) => Text(v.round().toString(), style: axisStyle(context)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text('Episodios', style: axisStyle(context)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (xEnd / 5).ceilToDouble().clamp(1.0, double.infinity).toDouble(),
                      getTitlesWidget: (v, _) => Text(v.round().toString(), style: axisStyle(context)),
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  // Nube de puntos: línea invisible, solo puntos.
                  LineChartBarData(
                    spots: [for (final p in points) FlSpot(p.episodes.toDouble(), p.rating)],
                    barWidth: 0,
                    color: Colors.transparent,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.chart[1].withValues(alpha: .55),
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                  // Recta de regresión recortada al rango visible 0..10 de rating.
                  if (reg != null)
                    LineChartBarData(
                      spots: [FlSpot(0, reg.predict(0).clamp(0.0, 10.0).toDouble()), FlSpot(xEnd, reg.predict(xEnd).clamp(0.0, 10.0).toDouble())],
                      barWidth: 3,
                      color: AppColors.coral,
                      dashArray: [8, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
    );
  }
}
