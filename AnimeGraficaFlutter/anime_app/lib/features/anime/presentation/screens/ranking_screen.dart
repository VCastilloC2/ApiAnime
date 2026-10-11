import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/floating_card.dart';
import '../providers/anime_providers.dart';
import '../widgets/anime_detail_sheet.dart';

/// Ranking: consume `GET /stats/top-rated`.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = ref.watch(topRatedProvider);
    final text = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(topRatedProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          ContentConstraint(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ranking', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                AsyncValueView(
                  value: top,
                  onRetry: () => ref.invalidate(topRatedProvider),
                  data: (items) => Column(
                    children: [
                      for (final (i, a) in items.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FloatingCard(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            radius: 20,
                            onTap: () => showAnimeDetail(context, a),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: i < 3 ? AppColors.coral : Theme.of(context).colorScheme.outline,
                                      )),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text('${a.genreName ?? 'Sin género'} · ${a.episodes} eps',
                                          style: text.bodySmall),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.star_rounded, color: Color(0xFFF2B33D)),
                                Text(a.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
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
