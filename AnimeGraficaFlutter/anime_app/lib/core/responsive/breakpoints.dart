import 'package:flutter/widgets.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Breakpoints centralizados. Se miden sobre el ANCHO DISPONIBLE (LayoutBuilder),
/// no sobre la pantalla, para que funcionen también dentro de paneles/ventanas redimensionadas.
class Breakpoints {
  const Breakpoints._();

  static const double mobile = 600;
  static const double desktop = 1100;

  /// Ancho máximo del contenido en pantallas ultra-anchas.
  static const double maxContentWidth = 1440;

  static ScreenSize of(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= mobile) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

/// Entrega el [ScreenSize] calculado desde las constraints.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenSize size, BoxConstraints constraints) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => builder(context, Breakpoints.of(c.maxWidth), c),
      );
}

/// Centra y limita el ancho del contenido (evita líneas eternas en monitores 4K).
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: child,
        ),
      );
}

/// Distribuye hijos en N columnas iguales según el ancho disponible.
/// Más barato que un GridView cuando los hijos tienen alturas propias.
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.children,
    this.minColumnWidth = 460,
    this.spacing = 20,
  });

  final List<Widget> children;
  final double minColumnWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final cols = (c.maxWidth / minColumnWidth).floor().clamp(1, 3);
          final w = (c.maxWidth - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [for (final child in children) SizedBox(width: w, child: child)],
          );
        },
      );
}
