/// Typing metrics: timing only (no content). Dwell time, flight time, variability.
class TypingMetrics {
  /// Average key-down duration (ms).
  final double avgDwellTimeMs;
  /// Average time between key-up and next key-down (ms).
  final double avgFlightTimeMs;
  /// Variability of dwell times (std dev or CV).
  final double dwellVariability;
  /// Rhythm consistency (0–1).
  final double rhythmConsistency;

  TypingMetrics({
    required this.avgDwellTimeMs,
    required this.avgFlightTimeMs,
    required this.dwellVariability,
    required this.rhythmConsistency,
  });

  Map<String, dynamic> toJson() => {
        'avgDwellTimeMs': avgDwellTimeMs,
        'avgFlightTimeMs': avgFlightTimeMs,
        'dwellVariability': dwellVariability,
        'rhythmConsistency': rhythmConsistency,
      };

  factory TypingMetrics.fromJson(Map<String, dynamic> json) => TypingMetrics(
        avgDwellTimeMs: (json['avgDwellTimeMs'] as num).toDouble(),
        avgFlightTimeMs: (json['avgFlightTimeMs'] as num).toDouble(),
        dwellVariability: (json['dwellVariability'] as num).toDouble(),
        rhythmConsistency: (json['rhythmConsistency'] as num).toDouble(),
      );
}
