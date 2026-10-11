import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/anime.dart';
import 'anime_card.dart';

/// Detalle en hoja modal (móvil: sube desde abajo; web: centrada con ancho máximo).
Future<void> showAnimeDetail(BuildContext context, Anime anime) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => AnimeDetailSheet(anime: anime),
    );

class AnimeDetailSheet extends StatelessWidget {
  const AnimeDetailSheet({super.key, required this.anime});
  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(32)),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimeCover(anime: anime, radius: 24, aspectRatio: 16 / 9),
              const SizedBox(height: 18),
              Text(anime.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(anime.genreName ?? 'Sin género', style: text.bodyMedium?.copyWith(color: scheme.outline)),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Stat(label: 'Rating', value: anime.rating.toStringAsFixed(1), icon: Icons.star_rounded),
                  const SizedBox(width: 12),
                  _Stat(label: 'Episodios', value: '${anime.episodes}', icon: Icons.play_circle_outline_rounded),
                  const SizedBox(width: 12),
                  _Stat(label: 'ID', value: '#${anime.id}', icon: Icons.tag_rounded),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.coral),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(fontSize: 12, color: scheme.outline)),
          ],
        ),
      ),
    );
  }
}
