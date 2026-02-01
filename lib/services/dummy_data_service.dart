import 'dart:math' as math;
import '../models/cogniaware_record.dart';
import '../models/gait_metrics.dart';
import '../models/typing_metrics.dart';
import '../models/voice_metrics.dart';
import 'preferences_service.dart';
import 'storage_service.dart';

/// Generates dummy gait, typing, and voice data for testing without sensors.
/// Use [seedDummyDataIfNeeded] on first launch or when DB is empty.
class DummyDataService {
  final StorageService _storage = StorageService();

  /// Call on app start: if DB has no recent records and user has not cleared data, seed 90 days of dummy data.
  Future<void> seedDummyDataIfNeeded() async {
    final skipSeed = await PreferencesService.getSkipDummySeed();
    if (skipSeed) return;
    final records = await _storage.getRecordsForDays(7);
    if (records.isNotEmpty) return;
    await seedDummyData(days: 90);
  }

  /// Force seed N days of dummy data (for testing).
  Future<void> seedDummyData({int days = 90}) async {
    final end = DateTime.now();
    final rng = math.Random(42);
    for (int d = 0; d < days; d++) {
      final date = end.subtract(Duration(days: d));
      // 1–3 records per day
      final count = 1 + rng.nextInt(3);
      for (int i = 0; i < count; i++) {
        final hour = 8 + rng.nextInt(10);
        final minute = rng.nextInt(60);
        final timestamp = DateTime(date.year, date.month, date.day, hour, minute);
        final gait = _dummyGait(rng);
        final gaitIndex = _gaitToIndex(gait);
        final typing = _dummyTyping(rng);
        final typingIndex = _typingToIndex(typing);
        final voice = _dummyVoice(rng);
        final voiceIndex = _voiceToIndex(voice);
        final combined = (gaitIndex * 0.5 + typingIndex * 0.3 + voiceIndex * 0.2)
            .clamp(0.0, 100.0);
        await _storage.insertRecord(CogniawareRecord(
          id: 'dummy_${timestamp.millisecondsSinceEpoch}',
          timestamp: timestamp,
          cogniawareIndex: combined,
          gaitMetrics: gait,
          gaitIndex: gaitIndex,
          typingMetrics: typing,
          typingIndex: typingIndex,
          voiceMetrics: voice,
          voiceIndex: voiceIndex,
        ));
      }
    }
  }

  GaitMetrics _dummyGait(math.Random rng) {
    final steps = 15 + rng.nextInt(35);
    return GaitMetrics(
      cadence: 88 + rng.nextDouble() * 24,
      stepIntervalVariabilityMs: 60 + rng.nextDouble() * 80,
      gaitSymmetry: 0.78 + rng.nextDouble() * 0.2,
      rhythmConsistency: 0.72 + rng.nextDouble() * 0.25,
      gyroStability: 0.7 + rng.nextDouble() * 0.28,
      stepCount: steps,
      distanceEstimateM: steps * 0.75,
    );
  }

  double _gaitToIndex(GaitMetrics g) {
    final cadenceScore = (g.cadence >= 80 && g.cadence <= 120) ? 1.0 : 0.7;
    final varScore = (1 - (g.stepIntervalVariabilityMs / 200).clamp(0.0, 1.0));
    final symScore = g.gaitSymmetry;
    final rhythmScore = g.rhythmConsistency.clamp(0.0, 1.0);
    final gyroScore = g.gyroStability.clamp(0.0, 1.0);
    return (cadenceScore * 0.15 + varScore * 0.25 + symScore * 0.25 +
            rhythmScore * 0.2 + gyroScore * 0.15) *
        100;
  }

  TypingMetrics _dummyTyping(math.Random rng) {
    return TypingMetrics(
      avgDwellTimeMs: 80 + rng.nextDouble() * 60,
      avgFlightTimeMs: 120 + rng.nextDouble() * 100,
      dwellVariability: 15 + rng.nextDouble() * 35,
      rhythmConsistency: 0.7 + rng.nextDouble() * 0.28,
    );
  }

  double _typingToIndex(TypingMetrics t) {
    final dwellOk = t.avgDwellTimeMs >= 60 && t.avgDwellTimeMs <= 150 ? 1.0 : 0.75;
    final varScore = (1 - (t.dwellVariability / 80).clamp(0.0, 1.0));
    final rhythmScore = t.rhythmConsistency.clamp(0.0, 1.0);
    return (dwellOk * 0.3 + varScore * 0.4 + rhythmScore * 0.3) * 100;
  }

  VoiceMetrics _dummyVoice(math.Random rng) {
    return VoiceMetrics(
      typeTokenRatio: 0.5 + rng.nextDouble() * 0.4,
      complexityScore: 0.6 + rng.nextDouble() * 0.35,
      speechRhythmConsistency: 0.65 + rng.nextDouble() * 0.32,
    );
  }

  double _voiceToIndex(VoiceMetrics v) {
    final ttrScore = (v.typeTokenRatio / 0.9).clamp(0.0, 1.0);
    final compScore = v.complexityScore.clamp(0.0, 1.0);
    final rhythmScore = v.speechRhythmConsistency.clamp(0.0, 1.0);
    return (ttrScore * 0.35 + compScore * 0.35 + rhythmScore * 0.3) * 100;
  }

  /// Current dummy snapshot for live gauge (no sensors).
  CogniawareRecord dummySnapshot() {
    final rng = math.Random(DateTime.now().millisecond);
    final gait = _dummyGait(rng);
    final typing = _dummyTyping(rng);
    final voice = _dummyVoice(rng);
    final gaitIndex = _gaitToIndex(gait);
    final typingIndex = _typingToIndex(typing);
    final voiceIndex = _voiceToIndex(voice);
    final combined = (gaitIndex * 0.5 + typingIndex * 0.3 + voiceIndex * 0.2)
        .clamp(0.0, 100.0);
    return CogniawareRecord(
      id: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      cogniawareIndex: combined,
      gaitMetrics: gait,
      gaitIndex: gaitIndex,
      typingMetrics: typing,
      typingIndex: typingIndex,
      voiceMetrics: voice,
      voiceIndex: voiceIndex,
    );
  }
}
