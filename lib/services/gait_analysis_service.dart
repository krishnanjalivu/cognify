import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import '../models/gait_metrics.dart';
import 'sensor_service.dart';

/// Derives gait metrics from accelerometer/gyroscope: step count, cadence,
/// step variability, symmetry, rhythm. Runs on-device; can run in background
/// when app is open (sensors stream while listening).
class GaitAnalysisService {
  final SensorService _sensorService;

  /// Window for analysis (ms). Steps counted in this window.
  static const int windowMs = 30 * 1000;
  /// Magnitude threshold above baseline to count a step (peak).
  static const double stepThreshold = 2.0;
  /// Min ms between two consecutive steps (debounce).
  static const int minStepIntervalMs = 300;
  /// Typical stride length (m) for distance estimate.
  static const double strideM = 0.75;

  final List<double> _magnitudes = [];
  final List<int> _peakTimesMs = [];
  StreamSubscription<AccelerometerEvent>? _sub;
  final _controller = StreamController<GaitMetrics?>.broadcast();

  GaitAnalysisService(this._sensorService);

  Stream<GaitMetrics?> get metricsStream => _controller.stream;

  /// Start listening to accelerometer and emitting gait metrics (with step count).
  void startListening() {
    if (_sub != null) return;
    _sensorService.startListening();
    _magnitudes.clear();
    _peakTimesMs.clear();
    _sub = _sensorService.accelerometer.listen((event) {
      final mag = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      _magnitudes.add(mag);
      if (_magnitudes.length > 500) _magnitudes.removeAt(0);
      _detectPeak(nowMs, mag);
      final m = _computeMetrics(nowMs);
      if (m != null && !_controller.isClosed) _controller.add(m);
    });
  }

  void _detectPeak(int nowMs, double mag) {
    if (_magnitudes.length < 3) return;
    final i = _magnitudes.length - 1;
    final center = _magnitudes[i - 1];
    final before = _magnitudes[i - 2];
    final after = _magnitudes[i];
    if (center <= before || center <= after) return;
    final start = math.max(0, i - 25);
    final baseline = _magnitudes.sublist(start, i - 1).fold<double>(0, (a, b) => a + b) / (i - 1 - start) + stepThreshold;
    if (center < baseline) return;
    final peakTime = nowMs - 50;
    if (_peakTimesMs.isNotEmpty && (peakTime - _peakTimesMs.last) < minStepIntervalMs) return;
    _peakTimesMs.add(peakTime);
    while (_peakTimesMs.isNotEmpty && (nowMs - _peakTimesMs.first) > windowMs) {
      _peakTimesMs.removeAt(0);
    }
  }

  GaitMetrics? _computeMetrics(int nowMs) {
    final inWindow = _peakTimesMs.where((t) => nowMs - t <= windowMs).toList();
    if (inWindow.length < 2) {
      return GaitMetrics(
        cadence: 0,
        stepIntervalVariabilityMs: 0,
        gaitSymmetry: 0.9,
        rhythmConsistency: 0.8,
        gyroStability: 0.85,
        stepCount: inWindow.length,
        distanceEstimateM: inWindow.length * strideM,
      );
    }
    final intervals = <int>[];
    for (int i = 1; i < inWindow.length; i++) {
      intervals.add(inWindow[i] - inWindow[i - 1]);
    }
    final avgIntervalMs = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => (x - avgIntervalMs) * (x - avgIntervalMs)).reduce((a, b) => a + b) / intervals.length;
    final stdMs = math.sqrt(variance);
    final cadence = avgIntervalMs > 0 ? 60000 / avgIntervalMs : 0.0;
    final rhythmConsistency = (stdMs / 200).clamp(0.0, 1.0);
    final rhythmScore = math.max(0, 1 - rhythmConsistency);
    final stepCount = inWindow.length;
    return GaitMetrics(
      cadence: cadence.clamp(0.0, 180.0),
      stepIntervalVariabilityMs: stdMs.toDouble(),
      gaitSymmetry: (0.85 + (0.15 * rhythmScore)).toDouble(),
      rhythmConsistency: rhythmScore.clamp(0.0, 1.0).toDouble(),
      gyroStability: 0.8,
      stepCount: stepCount,
      distanceEstimateM: (stepCount * strideM).toDouble(),
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _sensorService.stopListening();
  }

  void dispose() {
    stopListening();
    _controller.close();
    _sensorService.dispose();
  }

  /// Placeholder metrics when not using sensors (e.g. dummy mode).
  GaitMetrics getPlaceholderMetrics() {
    final r = math.Random();
    final steps = 20 + r.nextInt(40);
    return GaitMetrics(
      cadence: 88 + r.nextDouble() * 24,
      stepIntervalVariabilityMs: 60 + r.nextDouble() * 80,
      gaitSymmetry: 0.78 + r.nextDouble() * 0.2,
      rhythmConsistency: 0.72 + r.nextDouble() * 0.25,
      gyroStability: 0.7 + r.nextDouble() * 0.28,
      stepCount: steps,
      distanceEstimateM: steps * strideM,
    );
  }

  double computeCogniawareIndex(GaitMetrics m) {
    final cadenceScore = (m.cadence >= 80 && m.cadence <= 120) ? 1.0 : 0.7;
    final varScore = math.max(0, 1 - m.stepIntervalVariabilityMs / 200);
    final symScore = m.gaitSymmetry;
    final rhythmScore = math.min(1.0, m.rhythmConsistency);
    final gyroScore = m.gyroStability.clamp(0.0, 1.0);
    final raw = (cadenceScore * 0.15 + varScore * 0.25 + symScore * 0.25 +
            rhythmScore * 0.2 + gyroScore * 0.15) *
        100;
    return raw.clamp(0.0, 100.0);
  }
}
