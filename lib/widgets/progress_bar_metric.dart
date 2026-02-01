import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Horizontal progress bar with label, value, and description. Modern, neat.
class ProgressBarMetric extends StatelessWidget {
  final String label;
  final double value; // 0–100 or 0–1
  final String description;
  final Color? barColor;
  final bool valueAsPercent;

  const ProgressBarMetric({
    super.key,
    required this.label,
    required this.value,
    required this.description,
    this.barColor,
    this.valueAsPercent = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final color = barColor ?? CogniawareTheme.riskStable;
    final targetPct = valueAsPercent ? value.clamp(0.0, 100.0) / 100 : value.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.subtitle1),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, valueAsPercent ? 100.0 : 1.0)),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) => Text(
                  valueAsPercent ? '${animValue.round()}%' : animValue.toStringAsFixed(0),
                  style: theme.subtitle1?.copyWith(color: CogniawareTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: targetPct),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, pct, child) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: CogniawareTheme.cardGray,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: theme.caption),
        ],
      ),
    );
  }
}
