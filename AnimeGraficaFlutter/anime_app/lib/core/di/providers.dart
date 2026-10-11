import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Raíz de la inyección de dependencias (Riverpod).
/// En tests: `ProviderScope(overrides: [apiClientProvider.overrideWithValue(fake)])`.
final tokenStorageProvider = Provider<TokenStorage>((ref) => const SecureTokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = buildDio(tokenStorage: ref.watch(tokenStorageProvider));
  ref.onDispose(dio.close);
  return ApiClient(dio);
});
