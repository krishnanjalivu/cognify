import 'gait_metrics.dart';
import 'typing_metrics.dart';
import 'voice_metrics.dart';

/// Single record: combined Cogniaware Index + optional Gait/Typing/Voice breakdown.
/// Stored locally for trend analysis (7, 30, 90 days).
class CogniawareRecord {
  final String id;
  final DateTime timestamp;
  /// Combined index 0–100 (Gait + Typing + Voice weighted).
  final double cogniawareIndex;
  final GaitMetrics? gaitMetrics;
  /// Gait sub-index 0–100 (for reports and breakdown).
  final double? gaitIndex;
  final TypingMetrics? typingMetrics;
  final double? typingIndex;
  final VoiceMetrics? voiceMetrics;
  final double? voiceIndex;

  CogniawareRecord({
    required this.id,
    required this.timestamp,
    required this.cogniawareIndex,
    this.gaitMetrics,
    this.gaitIndex,
    this.typingMetrics,
    this.typingIndex,
    this.voiceMetrics,
    this.voiceIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'cogniawareIndex': cogniawareIndex,
        'gaitMetrics': gaitMetrics?.toJson(),
        'gaitIndex': gaitIndex,
        'typingMetrics': typingMetrics?.toJson(),
        'typingIndex': typingIndex,
        'voiceMetrics': voiceMetrics?.toJson(),
        'voiceIndex': voiceIndex,
      };

  factory CogniawareRecord.fromJson(Map<String, dynamic> json) => CogniawareRecord(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        cogniawareIndex: (json['cogniawareIndex'] as num).toDouble(),
        gaitMetrics: json['gaitMetrics'] != null
            ? GaitMetrics.fromJson(json['gaitMetrics'] as Map<String, dynamic>)
            : null,
        gaitIndex: (json['gaitIndex'] as num?)?.toDouble(),
        typingMetrics: json['typingMetrics'] != null
            ? TypingMetrics.fromJson(json['typingMetrics'] as Map<String, dynamic>)
            : null,
        typingIndex: (json['typingIndex'] as num?)?.toDouble(),
        voiceMetrics: json['voiceMetrics'] != null
            ? VoiceMetrics.fromJson(json['voiceMetrics'] as Map<String, dynamic>)
            : null,
        voiceIndex: (json['voiceIndex'] as num?)?.toDouble(),
      );
}
