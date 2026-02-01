import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';

/// Shows streak: consecutive days in stable zone (index >= 70).
/// Optional: moderate streak (45–70), increased streak (< 45).
class StreaksIndicator extends StatelessWidget {
  final List<CogniawareRecord> records;
  final int days;

  const StreaksIndicator({
    super.key,
    required this.records,
    this.days = 7,
  });

  /// Consecutive days (from today backward) where daily avg index >= threshold.
  static int stableStreak(List<CogniawareRecord> records, {double threshold = 70}) {
    if (records.isEmpty) return 0;
    final byDay = <String, List<double>>{};
    for (final r in records) {
      final key = '${r.timestamp.year}-${r.timestamp.month}-${r.timestamp.day}';
      byDay.putIfAbsent(key, () => []).add(r.cogniawareIndex);
    }
    final sortedDays = byDay.keys.toList()..sort();
    if (sortedDays.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      final values = byDay[key];
      if (values == null || values.isEmpty) break;
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (avg >= threshold) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final stable = stableStreak(records);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CogniawareTheme.riskStable.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CogniawareTheme.riskStable.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: CogniawareTheme.riskStable, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$stable day${stable == 1 ? '' : 's'} in stable zone',
                style: theme.subtitle1?.copyWith(
                  color: CogniawareTheme.riskStable,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Index ≥ 70 (green band)',
                style: theme.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
