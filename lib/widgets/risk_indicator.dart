import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Compact risk level label with color dot (green / yellow / orange).
class RiskIndicator extends StatelessWidget {
  final CogniawareRiskLevel level;
  final bool compact;

  const RiskIndicator({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final color = theme.riskColor(level);
    final label = _labelFor(level);
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.caption?.copyWith(color: color)),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.caption?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _labelFor(CogniawareRiskLevel level) {
    switch (level) {
      case CogniawareRiskLevel.stable:
        return 'Stable';
      case CogniawareRiskLevel.moderate:
        return 'Moderate variability';
      case CogniawareRiskLevel.increased:
        return 'Increased variability';
    }
  }
}
