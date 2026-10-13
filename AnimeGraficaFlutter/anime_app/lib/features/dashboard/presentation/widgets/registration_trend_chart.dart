import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'chart_card.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// AVANZADO · Tendencia temporal: altas acumuladas del catálogo por mes (`created_at`).
///
/// Nota: la API no expone año de estreno; cuando lo agregues (p. ej. `release_year`),
/// basta con cambiar el origen de [TrendPoint] en `BuildRegistrationTrend`.
class RegistrationTrendChart extends StatelessWidget {
  const RegistrationTrendChart({super.key, required this.trend});
  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final maxY = trend.isEmpty ? 1 : trend.last.cumulative;
    // Con altas en un solo mes, el caso de uso agrupa por día.
    final daily = trend.length >= 2 && trend.first.month.year == trend.last.month.year &&
        trend.first.month.month == trend.last.month.month;
    return ChartCard(
      title: 'Tendencia de altas',
      subtitle: daily ? 'Animes acumulados por día de registro' : 'Animes acumulados por mes de registro',
      child: trend.length < 2
          ? const ChartEmpty('Se necesitan altas en al menos 2 días distintos\npara dibujar una tendencia.\n(Registra animes en fechas diferentes.)')
          : LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.15,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, meta) => v == meta.max || v == meta.min && v != 0
                          ? const SizedBox.shrink()
                          : Text(v.round().toString(), style: axisStyle(context)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (trend.length / 6).ceilToDouble().clamp(1.0, 12.0).toDouble(),
                      getTitlesWidget: (v, _) {
                        if (v != v.roundToDouble() || v < 0 || v >= trend.length) return const SizedBox.shrink();
                        final m = trend[v.toInt()].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              daily
                                  ? '${m.day} ${_months[m.month - 1]}'
                                  : "${_months[m.month - 1]} '${(m.year % 100).toString().padLeft(2, '0')}",
                              style: axisStyle(context)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${trend[s.x.toInt()].cumulative} acumulados\n+${trend[s.x.toInt()].added} ${daily ? 'ese día' : 'ese mes'}',
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final (i, p) in trend.indexed) FlSpot(i.toDouble(), p.cumulative.toDouble())],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 4,
                    gradient: AppColors.accentGradient,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.coral.withValues(alpha: .28), AppColors.coral.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
