import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/floating_card.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Tarjetas KPI (`/stats/summary`). 2 columnas en móvil, 4 en escritorio.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.summary});
  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.movie_filter_rounded, 'Animes', '${summary.totalAnimes}', '${summary.animesWithoutGenre} sin género'),
      (Icons.category_rounded, 'Géneros', '${summary.totalGenres}', 'categorías activas'),
      (Icons.star_rounded, 'Rating medio', summary.avgRating.toStringAsFixed(2), 'sobre 10'),
      (Icons.play_circle_rounded, 'Episodios', _compact(summary.totalEpisodes), 'en total'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : 2;
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, it) in items.indexed)
              SizedBox(
                width: w,
                child: FloatingCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.chart[i].withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(it.$1, color: AppColors.chart[i]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.$3, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                            Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(it.$4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
