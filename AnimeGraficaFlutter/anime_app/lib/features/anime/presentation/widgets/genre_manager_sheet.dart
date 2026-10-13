import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/anime.dart';
import '../providers/anime_providers.dart';

/// CRUD de géneros: crear (POST), renombrar (PUT) y eliminar (DELETE).
Future<void> showGenreManager(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const GenreManagerSheet(),
    );

class GenreManagerSheet extends ConsumerStatefulWidget {
  const GenreManagerSheet({super.key});

  @override
  ConsumerState<GenreManagerSheet> createState() => _GenreManagerSheetState();
}

class _GenreManagerSheetState extends ConsumerState<GenreManagerSheet> {
  final _newName = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _toast(okMsg);
    } on Failure catch (f) {
      if (mounted) _toast(f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    await _run(() async {
      await ref.read(animeActionsProvider).createGenre(name);
      _newName.clear();
    }, 'Género creado');
  }

  Future<void> _rename(Genre g) async {
    final ctrl = TextEditingController(text: g.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar género'),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 50),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || name == g.name) return;
    await _run(() => ref.read(animeActionsProvider).renameGenre(g.id, name), 'Género renombrado');
  }

  Future<void> _delete(Genre g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar género'),
        content: Text('¿Eliminar "${g.name}"? Sus animes quedarán sin género.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ref.read(animeActionsProvider).deleteGenre(g.id), 'Género eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final genres = ref.watch(genresProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Géneros', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newName,
                    enabled: !_busy,
                    maxLength: 50,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(labelText: 'Nuevo género', counterText: ''),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(onPressed: _busy ? null : _add, child: const Icon(Icons.add_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: genres.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e is Failure ? e.message : 'No se pudieron cargar los géneros'),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Aún no hay géneros'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final g = list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Renombrar',
                                  icon: const Icon(Icons.edit_rounded),
                                  onPressed: _busy ? null : () => _rename(g),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                                  onPressed: _busy ? null : () => _delete(g),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ),
          ],
        ),
      ),
    );
  }
}
