import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/anime.dart';
import '../providers/cover_providers.dart';

/// Portada real buscada por título en AniList; si no hay resultado (o falla la
/// red) se muestra un degradado estable derivado del id.
class AnimeCover extends ConsumerWidget {
  const AnimeCover({super.key, required this.anime, this.radius = 20, this.aspectRatio = 16 / 10});

  final Anime anime;
  final double radius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = ref.watch(coverUrlProvider(anime.title)).value;
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
            if (coverUrl == null)
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
              )
            else ...[
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                // Si la imagen no carga, se ve el degradado de fondo.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                  opacity: frame == null && !sync ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: child,
                ),
              ),
              // Oscurece la base para que las etiquetas se lean sobre cualquier portada.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),
            ],
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
