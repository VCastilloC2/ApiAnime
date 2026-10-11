import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/anime_api_client.dart';
import '../../domain/entities/anime.dart';
import '../bloc/anime_bloc.dart';
import 'anime_charts_screen.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({super.key});

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<AnimeBloc>().add(AnimesLoaded(search: value.trim()));
    });
  }

  Future<void> _showAddDialog() async {
    final client = context.read<AnimeApiClient>();
    final bloc = context.read<AnimeBloc>();
    List<Genre> genres = [];
    try {
      genres = await client.getGenres();
    } catch (_) {}
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddAnimeDialog(genres: genres),
    );
    if (result != null) {
      bloc.add(AnimeAdded(
        title: result['title'] as String,
        episodes: result['episodes'] as int,
        rating: result['rating'] as double,
        genreId: result['genreId'] as int?,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animes'),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnimeChartsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por título...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<AnimeBloc, AnimeState>(
              listenWhen: (p, c) =>
                  c.status == AnimeStatus.failure && c.error != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error ?? 'Error')),
                );
              },
              builder: (context, state) {
                if (state.status == AnimeStatus.loading && state.animes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.animes.isEmpty) {
                  return Center(
                    child: Text(
                      state.status == AnimeStatus.failure
                          ? 'No se pudo conectar con la API'
                          : 'Sin resultados',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<AnimeBloc>()
                      .add(AnimesLoaded(search: state.search)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.animes.length,
                    itemBuilder: (_, i) => _AnimeCard(anime: state.animes[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  final Anime anime;
  const _AnimeCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            anime.rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(anime.title),
        subtitle: Text(
          '${anime.genreName ?? 'Sin género'} • ${anime.episodes} episodios',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => context.read<AnimeBloc>().add(AnimeDeleted(anime.id)),
        ),
      ),
    );
  }
}

class _AddAnimeDialog extends StatefulWidget {
  final List<Genre> genres;
  const _AddAnimeDialog({required this.genres});

  @override
  State<_AddAnimeDialog> createState() => _AddAnimeDialogState();
}

class _AddAnimeDialogState extends State<_AddAnimeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _episodes = TextEditingController();
  final _rating = TextEditingController();
  int? _genreId;

  @override
  void dispose() {
    _title.dispose();
    _episodes.dispose();
    _rating.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'episodes': int.parse(_episodes.text),
      'rating': double.parse(_rating.text.replaceAll(',', '.')),
      'genreId': _genreId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo anime'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _episodes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Episodios'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1) ? 'Número mayor a 0' : null;
                },
              ),
              TextFormField(
                controller: _rating,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rating (0-10)'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  return (n == null || n < 0 || n > 10) ? 'Entre 0 y 10' : null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _genreId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Género'),
                items: [
                  for (final g in widget.genres)
                    DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setState(() => _genreId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
