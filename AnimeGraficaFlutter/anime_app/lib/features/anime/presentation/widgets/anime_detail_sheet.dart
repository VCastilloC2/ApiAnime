import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/anime.dart';
import '../providers/anime_providers.dart';
import 'anime_card.dart';
import 'anime_form_sheet.dart';

/// Detalle en hoja modal (móvil: sube desde abajo; web: centrada con ancho máximo).
Future<void> showAnimeDetail(BuildContext context, Anime anime) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => AnimeDetailSheet(anime: anime),
    );

class AnimeDetailSheet extends ConsumerWidget {
  const AnimeDetailSheet({super.key, required this.anime});
  final Anime anime;

  Future<void> _edit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop(); // cierra el detalle y abre el formulario
    final saved = await showAnimeForm(navigator.context, anime: anime);
    if (saved != null) {
      messenger.showSnackBar(SnackBar(content: Text('"${saved.title}" actualizado')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar anime'),
        content: Text('¿Eliminar "${anime.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(animeActionsProvider).delete(anime.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('"${anime.title}" eliminado')));
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context, ref),
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
