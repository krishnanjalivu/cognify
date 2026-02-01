/// Voice metrics from active exercises. Processed on-device; audio discarded.
class VoiceMetrics {
  /// Type-Token Ratio (vocabulary diversity).
  final double typeTokenRatio;
  /// Sentence complexity score (0–1).
  final double complexityScore;
  /// Pause/rhythm consistency (0–1).
  final double speechRhythmConsistency;

  VoiceMetrics({
    required this.typeTokenRatio,
    required this.complexityScore,
    required this.speechRhythmConsistency,
  });

  Map<String, dynamic> toJson() => {
        'typeTokenRatio': typeTokenRatio,
        'complexityScore': complexityScore,
        'speechRhythmConsistency': speechRhythmConsistency,
      };

  factory VoiceMetrics.fromJson(Map<String, dynamic> json) => VoiceMetrics(
        typeTokenRatio: (json['typeTokenRatio'] as num).toDouble(),
        complexityScore: (json['complexityScore'] as num).toDouble(),
        speechRhythmConsistency: (json['speechRhythmConsistency'] as num).toDouble(),
      );
}
