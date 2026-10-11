import 'package:flutter/material.dart';

/// Tarjeta flotante: esquinas muy redondeadas y sombra difusa (profundidad sutil).
class FloatingCard extends StatelessWidget {
  const FloatingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .35 : .06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
