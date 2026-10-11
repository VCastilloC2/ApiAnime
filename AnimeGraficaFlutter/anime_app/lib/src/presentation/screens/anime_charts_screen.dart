import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/anime_api_client.dart';
import '../../domain/entities/anime.dart';

const _palette = <Color>[
  Color(0xFF7E57C2),
  Color(0xFF26A69A),
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFEC407A),
  Color(0xFF8D6E63),
];

class AnimeChartsScreen extends StatefulWidget {
  const AnimeChartsScreen({super.key});

  @override
  State<AnimeChartsScreen> createState() => _AnimeChartsScreenState();
}

class _AnimeChartsScreenState extends State<AnimeChartsScreen> {
  late Future<List<GenreStat>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AnimeApiClient>().getStatsByGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas de Animes')),
      body: FutureBuilder<List<GenreStat>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar las estadísticas'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final stats = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChartCard(
                title: 'Rating promedio por género (top 8)',
                child: _RatingBarChart(stats: stats.take(8).toList()),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Animes por género (top 6)',
                child: _CountPieChart(stats: stats.take(6).toList()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RatingBarChart extends StatelessWidget {
  final List<GenreStat> stats;
  const _RatingBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                  final name = stats[i].genre;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      name.length > 5 ? name.substring(0, 5) : name,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < stats.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: stats[i].avgRating,
                    color: _palette[i % _palette.length],
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountPieChart extends StatelessWidget {
  final List<GenreStat> stats;
  const _CountPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < stats.length; i++)
                  PieChartSectionData(
                    value: stats[i].totalAnimes.toDouble(),
                    title: '${stats[i].totalAnimes}',
                    color: _palette[i % _palette.length],
                    radius: 64,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < stats.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: _palette[i % _palette.length],
                  ),
                  const SizedBox(width: 6),
                  Text(stats[i].genre, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
