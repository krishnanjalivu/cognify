import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Streams accelerometer and gyroscope data for gait analysis.
/// All processing is on-device; raw data never leaves the device.
class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final _accelController = StreamController<AccelerometerEvent>.broadcast();
  final _gyroController = StreamController<GyroscopeEvent>.broadcast();

  Stream<AccelerometerEvent> get accelerometer => _accelController.stream;
  Stream<GyroscopeEvent> get gyroscope => _gyroController.stream;

  bool get isListening => _accelSub != null;

  void startListening() {
    if (isListening) return;
    _accelSub = accelerometerEventStream().listen(_accelController.add);
    _gyroSub = gyroscopeEventStream().listen(_gyroController.add);
  }

  void stopListening() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  void dispose() {
    stopListening();
    _accelController.close();
    _gyroController.close();
  }
}
