import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';

/// Shows current index vs baseline (e.g. 7-day average) with trend arrow.
class BaselineIndicator extends StatelessWidget {
  final double currentIndex;
  final List<CogniawareRecord> records;
  final int baselineDays;

  const BaselineIndicator({
    super.key,
    required this.currentIndex,
    required this.records,
    this.baselineDays = 7,
  });

  double? get _baseline {
    if (records.isEmpty) return null;
    final recent = records.take(baselineDays * 3).toList();
    if (recent.isEmpty) return null;
    return recent.map((r) => r.cogniawareIndex).reduce((a, b) => a + b) / recent.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final baseline = _baseline;
    if (baseline == null) return const SizedBox.shrink();

    final diff = currentIndex - baseline;
    final isUp = diff > 0.5;
    final isDown = diff < -0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CogniawareTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : (isDown ? Icons.trending_down : Icons.trending_flat),
            size: 20,
            color: isUp
                ? CogniawareTheme.riskStable
                : (isDown ? CogniawareTheme.riskIncreased : CogniawareTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            'vs $baselineDays-day avg: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
            style: theme.caption,
          ),
        ],
      ),
    );
  }
}
