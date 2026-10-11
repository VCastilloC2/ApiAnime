import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/dashboard_providers.dart';
import 'chart_card.dart';

/// AVANZADO · Métricas de la API en tiempo real.
/// Sondea `/health` y grafica 2 series:
///  - Servidor: cabecera `X-Process-Time-ms` (middleware de tu FastAPI).
///  - Ida y vuelta: medido en el cliente (incluye red).
class LatencyLiveChart extends ConsumerWidget {
  const LatencyLiveChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(latencyMonitorProvider);
    final samples = state.samples;
    final last = samples.isEmpty ? null : samples.last;
    final maxY = samples.fold<double>(10, (m, s) => [m, s.serverMs, s.roundTripMs.toDouble()].reduce((a, b) => a > b ? a : b));

    return ChartCard(
      title: 'Latencia de la API · en vivo',
      subtitle: state.error != null
          ? '⚠ ${state.error!.message}'
          : last == null
              ? 'Midiendo…'
              : 'Servidor ${last.serverMs.toStringAsFixed(1)} ms  ·  Total ${last.roundTripMs} ms',
      height: 240,
      trailing: IconButton.filledTonal(
        tooltip: state.running ? 'Pausar' : 'Reanudar',
        onPressed: () => ref.read(latencyMonitorProvider.notifier).toggle(),
        icon: Icon(state.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
      ),
      child: samples.length < 2
          ? const ChartEmpty('Recolectando muestras…')
          : LineChart(
              duration: Duration.zero, // sin animación: el flujo en vivo se siente más fluido
              LineChartData(
                minX: 0,
                maxX: (samples.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.25,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text('ms', style: axisStyle(context)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) => v == meta.max
                          ? const SizedBox.shrink()
                          : Text(v.round().toString(), style: axisStyle(context)),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${s.y.toStringAsFixed(1)} ms',
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  _line([for (final (i, s) in samples.indexed) FlSpot(i.toDouble(), s.roundTripMs.toDouble())],
                      AppColors.chart[1]),
                  _line([for (final (i, s) in samples.indexed) FlSpot(i.toDouble(), s.serverMs)],
                      AppColors.coral),
                ],
              ),
            ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color c) => LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        barWidth: 3,
        color: c,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: c.withValues(alpha: .08)),
      );
}
