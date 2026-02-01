/// Gait metrics computed from accelerometer/gyroscope data.
/// Used for cognitive stability indicators and stored locally.
class GaitMetrics {
  /// Steps per minute (cadence).
  final double cadence;

  /// Standard deviation of step intervals (ms) - lower = more consistent.
  final double stepIntervalVariabilityMs;

  /// Left-right symmetry ratio (0–1, 1 = perfect symmetry).
  final double gaitSymmetry;

  /// Coefficient of variation of step intervals - rhythm consistency.
  final double rhythmConsistency;

  /// From gyroscope: rotation variance (lower = more stable). 0–1 normalized.
  final double gyroStability;

  /// Total steps detected in the measurement window (e.g. last 30s or session).
  final int stepCount;

  /// Estimated distance in meters (step count × avg stride; stride ~0.75m typical).
  final double distanceEstimateM;

  GaitMetrics({
    required this.cadence,
    required this.stepIntervalVariabilityMs,
    required this.gaitSymmetry,
    required this.rhythmConsistency,
    this.gyroStability = 0.85,
    this.stepCount = 0,
    this.distanceEstimateM = 0,
  });

  Map<String, dynamic> toJson() => {
        'cadence': cadence,
        'stepIntervalVariabilityMs': stepIntervalVariabilityMs,
        'gaitSymmetry': gaitSymmetry,
        'rhythmConsistency': rhythmConsistency,
        'gyroStability': gyroStability,
        'stepCount': stepCount,
        'distanceEstimateM': distanceEstimateM,
      };

  factory GaitMetrics.fromJson(Map<String, dynamic> json) => GaitMetrics(
        cadence: (json['cadence'] as num).toDouble(),
        stepIntervalVariabilityMs: (json['stepIntervalVariabilityMs'] as num).toDouble(),
        gaitSymmetry: (json['gaitSymmetry'] as num).toDouble(),
        rhythmConsistency: (json['rhythmConsistency'] as num).toDouble(),
        gyroStability: (json['gyroStability'] as num?)?.toDouble() ?? 0.85,
        stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
        distanceEstimateM: (json['distanceEstimateM'] as num?)?.toDouble() ?? 0,
      );
}
