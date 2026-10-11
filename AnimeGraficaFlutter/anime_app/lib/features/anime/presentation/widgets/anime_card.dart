import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/anime.dart';

/// Portada generativa: la API no almacena imágenes, así que se deriva un
/// degradado estable a partir del id (mismo anime = mismo color siempre).
class AnimeCover extends StatelessWidget {
  const AnimeCover({super.key, required this.anime, this.radius = 20, this.aspectRatio = 16 / 10});

  final Anime anime;
  final double radius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final a = AppColors.chart[anime.id % AppColors.chart.length];
    final b = AppColors.chart[(anime.id * 3 + 2) % AppColors.chart.length];
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [a, Color.lerp(a, b, .75)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -10,
              bottom: -28,
              child: Text(
                anime.title.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 150,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: .22),
                ),
              ),
            ),
            Positioned(top: 12, right: 12, child: _Pill(text: '${anime.episodes} eps')),
            if (anime.genreName != null)
              Positioned(left: 12, bottom: 12, child: _Pill(text: anime.genreName!, dot: true)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.dot = false});
  final String text;
  final bool dot;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              const CircleAvatar(radius: 4, backgroundColor: AppColors.coral),
              const SizedBox(width: 6),
            ],
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
          ],
        ),
      );
}

class AnimeCard extends StatelessWidget {
  const AnimeCard({super.key, required this.anime, required this.onTap});

  final Anime anime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimeCover(anime: anime),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    anime.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF2B33D)),
                const SizedBox(width: 2),
                Text(anime.rating.toStringAsFixed(1), style: text.labelLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
