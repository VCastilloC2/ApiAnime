import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/responsive/breakpoints.dart';
import '../core/theme/app_theme.dart';
import '../features/anime/presentation/screens/explore_screen.dart';
import '../features/anime/presentation/screens/ranking_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../shared/widgets/floating_card.dart';

class NavIndex extends Notifier<int> {
  @override
  int build() => 0;
  void select(int i) => state = i;
}

final navIndexProvider = NotifierProvider<NavIndex, int>(NavIndex.new);

class _Dest {
  const _Dest(this.icon, this.label, this.page);
  final IconData icon;
  final String label;
  final Widget page;
}

const _destinations = <_Dest>[
  _Dest(Icons.explore_rounded, 'Explorar', ExploreScreen()),
  _Dest(Icons.emoji_events_rounded, 'Ranking', RankingScreen()),
  _Dest(Icons.insights_rounded, 'Dashboard', DashboardScreen()),
];

/// Shell adaptativo:
///   ≥ 1100 px  -> Sidebar flotante extendida (web/escritorio)
///   600-1100   -> NavigationRail compacto (tablet)
///   < 600      -> Barra inferior flotante (móvil)
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);
    void select(int i) => ref.read(navIndexProvider.notifier).select(i);

    // Solo se construye la página activa (el resto no consume memoria ni red).
    // Los datos de Explorar sobreviven porque su provider no es autoDispose.
    final page = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(index), child: _destinations[index].page),
    );

    return ResponsiveBuilder(
      builder: (context, size, _) {
        switch (size) {
          case ScreenSize.desktop:
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(width: 260, child: _Sidebar(index: index, onSelect: select)),
                    ),
                    Expanded(child: page),
                  ],
                ),
              ),
            );
          case ScreenSize.tablet:
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: select,
                      backgroundColor: Colors.transparent,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final d in _destinations)
                          NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
                      ],
                    ),
                    Expanded(child: page),
                  ],
                ),
              ),
            );
          case ScreenSize.mobile:
            return Scaffold(
              body: SafeArea(bottom: false, child: page),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 24)],
                      ),
                      child: NavigationBar(
                        height: 64,
                        backgroundColor: Colors.transparent,
                        selectedIndex: index,
                        onDestinationSelected: select,
                        destinations: [
                          for (final d in _destinations)
                            NavigationDestination(icon: Icon(d.icon), label: d.label),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingCard(
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de marca/usuario (avatar + datos), como en la referencia.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.accentGradient),
                  child: const Text('AP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Anime Pulse', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(Uri.parse(Env.apiBaseUrl).authority,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: scheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final (i, d) in _destinations.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NavItem(dest: d, selected: i == index, onTap: () => onSelect(i)),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.dest, required this.selected, required this.onTap});
  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: .75);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(dest.icon, size: 20, color: fg),
            const SizedBox(width: 14),
            Text(dest.label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}
