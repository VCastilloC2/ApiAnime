import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'shell/adaptive_shell.dart';

class AnimePulseApp extends StatelessWidget {
  const AnimePulseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Anime Pulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AdaptiveShell(),
      );
}
