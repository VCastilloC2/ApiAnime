import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/anime.dart';

/// Pestañas de categoría (estilo "Todos | Manhwa | Manhua | Manga" de la referencia).
class GenreTabs extends StatelessWidget {
  const GenreTabs({super.key, required this.genres, required this.selectedId, required this.onSelected});

  final List<Genre> genres;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _Tab(label: 'Todos', selected: selectedId == null, onTap: () => onSelected(null)),
            for (final g in genres)
              _Tab(label: g.name, selected: selectedId == g.id, onTap: () => onSelected(g.id)),
          ],
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.accentGradient : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : scheme.onSurface.withValues(alpha: .7),
            ),
          ),
        ),
      ),
    );
  }
}
