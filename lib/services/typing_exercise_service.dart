import 'dart:math' as math;
import '../models/typing_metrics.dart';

/// Typing exercise prompts. Only timing is stored; content is never recorded.
class TypingExerciseService {
  static const List<String> prompts = [
    'The quick brown fox',
    'Hello world',
    'Cogniaware tracks wellness',
    'Type this phrase at your usual speed.',
    'One two three four five',
    'Good morning',
    'Cognitive health matters',
    'Short sentence to type',
  ];

  static String getRandomPrompt([math.Random? rng]) {
    final r = rng ?? math.Random();
    return prompts[r.nextInt(prompts.length)];
  }

  /// Compute typing metrics from inter-key timestamps (ms). Content not used.
  static TypingMetrics computeFromTimestamps(List<int> timestampsMs) {
    if (timestampsMs.length < 2) {
      return TypingMetrics(
        avgDwellTimeMs: 80,
        avgFlightTimeMs: 120,
        dwellVariability: 20,
        rhythmConsistency: 0.75,
      );
    }
    final intervals = <int>[];
    for (int i = 1; i < timestampsMs.length; i++) {
      intervals.add(timestampsMs[i] - timestampsMs[i - 1]);
    }
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => (x - avg) * (x - avg)).reduce((a, b) => a + b) / intervals.length;
    final std = math.sqrt(variance);
    final cv = avg > 0 ? std / avg : 0;
    final rhythmConsistency = (1 - math.min(cv, 1.0)).clamp(0.0, 1.0).toDouble();
    return TypingMetrics(
      avgDwellTimeMs: (60 + avg * 0.3).toDouble(),
      avgFlightTimeMs: avg.toDouble().clamp(50.0, 400.0),
      dwellVariability: std.clamp(0.0, 100.0).toDouble(),
      rhythmConsistency: rhythmConsistency,
    );
  }

  static double typingIndexFromMetrics(TypingMetrics t) {
    final dwellOk = t.avgDwellTimeMs >= 60 && t.avgDwellTimeMs <= 150 ? 1.0 : 0.75;
    final varScore = (1 - (t.dwellVariability / 80).clamp(0.0, 1.0));
    final rhythmScore = t.rhythmConsistency.clamp(0.0, 1.0);
    return (dwellOk * 0.3 + varScore * 0.4 + rhythmScore * 0.3) * 100;
  }
}
