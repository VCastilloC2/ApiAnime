import 'package:flutter/material.dart';

import '../../../../shared/widgets/floating_card.dart';

/// Contenedor común de gráficos: título, subtítulo, acción opcional y altura fija.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.height = 280,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final outline = Theme.of(context).colorScheme.outline;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(subtitle, style: text.bodySmall?.copyWith(color: outline)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

/// Mensaje cuando no hay datos suficientes para dibujar.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
}

TextStyle axisStyle(BuildContext context) =>
    TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline);
