import 'package:flutter/material.dart';

/// Paleta inspirada en la referencia: fondo gris azulado muy suave,
/// tarjetas blancas flotantes, acento coral y botones pizarra oscuro.
class AppColors {
  const AppColors._();

  static const slate = Color(0xFF3C4A54);
  static const coral = Color(0xFFF2675F);
  static const coralLight = Color(0xFFFF9A7B);
  static const bgLight = Color(0xFFF1F3F8);
  static const bgDark = Color(0xFF14171C);
  static const surfaceDark = Color(0xFF1E2229);

  /// Paleta categórica para gráficos (distinguible en claro y oscuro).
  static const chart = <Color>[
    Color(0xFFF2675F), // coral
    Color(0xFF3C7DD9), // azul
    Color(0xFF2FB488), // verde
    Color(0xFFF2B33D), // ámbar
    Color(0xFF8E6AD8), // violeta
    Color(0xFF3AB5C9), // turquesa
    Color(0xFFD96AA7), // rosa
    Color(0xFF8A94A6), // gris
  ];

  static const accentGradient = LinearGradient(
    colors: [coralLight, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.slate,
          brightness: Brightness.light,
          primary: AppColors.slate,
          secondary: AppColors.coral,
          surface: Colors.white,
        ),
        AppColors.bgLight,
      );

  static ThemeData dark() => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.slate,
          brightness: Brightness.dark,
          primary: const Color(0xFFB9C7D3),
          secondary: AppColors.coral,
          surface: AppColors.surfaceDark,
        ),
        AppColors.bgDark,
      );

  static ThemeData _base(ColorScheme scheme, Color background) {
    final text = Typography.material2021().black.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: text,
      dividerColor: scheme.outlineVariant.withValues(alpha: .4),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
