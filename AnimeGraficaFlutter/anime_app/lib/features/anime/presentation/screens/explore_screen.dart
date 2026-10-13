import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../providers/anime_providers.dart';
import '../widgets/anime_card.dart';
import '../widgets/anime_detail_sheet.dart';
import '../widgets/anime_form_sheet.dart';
import '../widgets/genre_manager_sheet.dart';
import '../widgets/genre_tabs.dart';

/// Catálogo con búsqueda (debounce), pestañas por género y scroll infinito.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Pide la siguiente página 400 px antes de llegar al final.
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        ref.read(animeListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Debounce: solo consulta a la API cuando el usuario deja de escribir 400 ms.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(animeQueryProvider.notifier).update((q) => q.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(animeListProvider);
    final genres = ref.watch(genresProvider);
    final query = ref.watch(animeQueryProvider);
    final text = Theme.of(context).textTheme;

    return ResponsiveBuilder(
      builder: (context, size, _) {
        final pad = size == ScreenSize.mobile ? 16.0 : 32.0;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(animeListProvider.future),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 24, pad, 12),
                sliver: SliverToBoxAdapter(
                  child: ContentConstraint(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Explorar',
                                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            IconButton(
                              tooltip: 'Gestionar géneros',
                              onPressed: () => showGenreManager(context),
                              icon: const Icon(Icons.category_rounded),
                            ),
                            const SizedBox(width: 4),
                            FilledButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final created = await showAnimeForm(context);
                                if (created != null) {
                                  messenger.showSnackBar(SnackBar(content: Text('"${created.title}" creado')));
                                }
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nuevo'),
                            ),
                          ],
                        ),
                        Text(
                          '${list.value?.total ?? 0} animes en el catálogo',
                          style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por título…',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        genres.maybeWhen(
                          data: (g) => GenreTabs(
                            genres: g,
                            selectedId: query.genreId,
                            onSelected: (id) => ref.read(animeQueryProvider.notifier).update(
                                  (q) => id == null ? q.copyWith(clearGenre: true) : q.copyWith(genreId: id),
                                ),
                          ),
                          orElse: () => const SizedBox(height: 42),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._body(list, size, pad),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(AsyncValue<AnimeListState> list, ScreenSize size, double pad) {
    return list.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator.adaptive()))],
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(error: e, onRetry: () => ref.invalidate(animeListProvider)),
        ),
      ],
      data: (s) {
        if (s.items.isEmpty) {
          return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Sin resultados')))];
        }
        return [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverGrid.builder(
              // Columnas automáticas: 1 en móvil, 3-5 en escritorio, sin media queries manuales.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 250,
                crossAxisSpacing: 20,
                mainAxisSpacing: 12,
              ),
              itemCount: s.items.length,
              itemBuilder: (_, i) => AnimeCard(
                anime: s.items[i],
                onTap: () => showAnimeDetail(context, s.items[i]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: s.loadingMore
                    ? const CircularProgressIndicator.adaptive()
                    : s.hasLoadMoreError
                        ? TextButton(
                            onPressed: () => ref.read(animeListProvider.notifier).loadMore(),
                            child: const Text('Error al cargar más. Reintentar'),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ];
      },
    );
  }
}
