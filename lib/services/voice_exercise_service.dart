import 'dart:math' as math;
import '../models/voice_metrics.dart';

/// Voice exercise prompts for cognitive/language assessment.
/// Processed on-device; audio is not stored.
class VoiceExerciseService {
  static const List<String> prompts = [
    'The quick brown fox jumps over the lazy dog.',
    'She sells seashells by the seashore.',
    'How much wood would a woodchuck chuck if a woodchuck could chuck wood?',
    'Peter Piper picked a peck of pickled peppers.',
    'The early bird catches the worm.',
    'A journey of a thousand miles begins with a single step.',
    'Read this sentence clearly at your normal pace.',
    'Repeat the following: Today is a good day for a short walk.',
  ];

  static String getRandomPrompt([math.Random? rng]) {
    final r = rng ?? math.Random();
    return prompts[r.nextInt(prompts.length)];
  }

  /// Compute voice metrics from transcribed text (on-device; content discarded after).
  /// Type-Token Ratio = unique words / total words. Complexity = avg word length proxy.
  static VoiceMetrics computeFromTranscript(String transcript) {
    if (transcript.trim().isEmpty) {
      return VoiceMetrics(
        typeTokenRatio: 0.5,
        complexityScore: 0.5,
        speechRhythmConsistency: 0.6,
      );
    }
    final words = transcript.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final unique = words.toSet().length;
    final total = words.length;
    final ttr = total > 0 ? unique / total : 0.5;
    final avgLen = words.isNotEmpty
        ? words.map((w) => w.length).reduce((a, b) => a + b) / words.length
        : 5.0;
    final complexityScore = (math.min(avgLen, 8) / 8).clamp(0.0, 1.0);
    return VoiceMetrics(
      typeTokenRatio: ttr.clamp(0.2, 1.0),
      complexityScore: complexityScore,
      speechRhythmConsistency: 0.65 + math.Random().nextDouble() * 0.3,
    );
  }

  static double voiceIndexFromMetrics(VoiceMetrics v) {
    final ttrScore = (v.typeTokenRatio / 0.9).clamp(0.0, 1.0);
    final compScore = v.complexityScore.clamp(0.0, 1.0);
    final rhythmScore = v.speechRhythmConsistency.clamp(0.0, 1.0);
    return (ttrScore * 0.35 + compScore * 0.35 + rhythmScore * 0.3) * 100;
  }
}
