import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ProviderScope = contenedor de inyección de dependencias de toda la app.
  runApp(const ProviderScope(child: AnimePulseApp()));
}
