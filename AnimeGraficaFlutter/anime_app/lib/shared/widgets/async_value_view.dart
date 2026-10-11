import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';

/// Renderiza los 3 estados de un [AsyncValue] con UI consistente.
/// Mantiene el dato anterior visible durante un refresh (`skipLoadingOnRefresh`).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.loadingHeight = 220,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) => value.when(
        skipLoadingOnRefresh: true,
        data: data,
        loading: () => SizedBox(
          height: loadingHeight,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (e, _) => ErrorView(error: e, onRetry: onRetry),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failure = error is Failure ? error as Failure : const UnknownFailure();
    final icon = switch (failure) {
      NetworkFailure() || TimeoutFailure() => Icons.wifi_off_rounded,
      NotFoundFailure() => Icons.search_off_rounded,
      _ => Icons.error_outline_rounded,
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.secondary),
            const SizedBox(height: 12),
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
