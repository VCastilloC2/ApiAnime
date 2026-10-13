import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/anime.dart';
import '../providers/anime_providers.dart';

/// Formulario para crear (POST) o editar (PUT) un anime.
/// Devuelve el [Anime] guardado, o null si se cancela.
Future<Anime?> showAnimeForm(BuildContext context, {Anime? anime}) => showModalBottomSheet<Anime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => AnimeFormSheet(anime: anime),
    );

class AnimeFormSheet extends ConsumerStatefulWidget {
  const AnimeFormSheet({super.key, this.anime});
  final Anime? anime;

  @override
  ConsumerState<AnimeFormSheet> createState() => _AnimeFormSheetState();
}

class _AnimeFormSheetState extends ConsumerState<AnimeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.anime?.title ?? '');
  late final _episodes = TextEditingController(text: widget.anime?.episodes.toString() ?? '');
  late final _rating = TextEditingController(text: widget.anime?.rating.toStringAsFixed(1) ?? '');
  late int? _genreId = widget.anime?.genreId;

  bool _saving = false;
  String? _error; // error general del servidor
  Map<String, String> _serverFields = const {}; // errores por campo (422)

  bool get _isEdit => widget.anime != null;

  @override
  void dispose() {
    _title.dispose();
    _episodes.dispose();
    _rating.dispose();
    super.dispose();
  }

  String? _field(String name, String? local) => local ?? _serverFields[name];

  Future<void> _submit() async {
    setState(() {
      _serverFields = const {};
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final input = AnimeInput(
      title: _title.text.trim(),
      episodes: int.parse(_episodes.text.trim()),
      rating: double.parse(_rating.text.trim().replaceAll(',', '.')),
      genreId: _genreId,
    );

    setState(() => _saving = true);
    try {
      final actions = ref.read(animeActionsProvider);
      final saved = _isEdit ? await actions.update(widget.anime!.id, input) : await actions.create(input);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ValidationFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverFields = f.fieldErrors;
        _error = f.fieldErrors.isEmpty ? f.message : null;
      });
      _formKey.currentState?.validate();
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = f.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final genres = ref.watch(genresProvider).value ?? const <Genre>[];
    // Si el género del anime ya no existe en la lista, evita que el Dropdown falle.
    final genreValue = genres.any((g) => g.id == _genreId) ? _genreId : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(32)),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEdit ? 'Editar anime' : 'Nuevo anime',
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => _field('title', (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _episodes,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Episodios'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return _field('episodes', (n == null || n < 1 || n > 100000) ? 'Entre 1 y 100000' : null);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rating,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rating (0-10)'),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                          return _field('rating', (n == null || n < 0 || n > 10) ? 'Entre 0 y 10' : null);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: genreValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sin género')),
                    for (final g in genres) DropdownMenuItem<int?>(value: g.id, child: Text(g.name)),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _genreId = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isEdit ? 'Guardar cambios' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
