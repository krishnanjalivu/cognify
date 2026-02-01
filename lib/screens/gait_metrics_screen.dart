import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/gait_metrics.dart';
import '../models/cogniaware_record.dart';
import '../services/gait_analysis_service.dart';
import '../services/sensor_service.dart';
import '../services/dummy_data_service.dart';
import '../services/storage_service.dart';
import '../services/preferences_service.dart';
import '../widgets/cogniaware_app_bar.dart';
import '../widgets/cogniaware_gauge.dart';
import '../widgets/progress_bar_metric.dart';
import '../widgets/multi_metric_chart.dart';

/// Gait Analysis: 7-day averages, Current Gait Index, Today's Activity, progress bars, trend.
class GaitMetricsScreen extends StatefulWidget {
  const GaitMetricsScreen({super.key});

  @override
  State<GaitMetricsScreen> createState() => _GaitMetricsScreenState();
}

class _GaitMetricsScreenState extends State<GaitMetricsScreen> {
  late SensorService _sensorService;
  late GaitAnalysisService _gaitService;
  final DummyDataService _dummy = DummyDataService();
  final StorageService _storage = StorageService();
  GaitMetrics? _metrics;
  double _index = 0;
  List<CogniawareRecord> _records = [];
  int _trendDays = 7;
  bool _loading = true;
  bool _useDummy = true;
  StreamSubscription<GaitMetrics?>? _sub;
  /// Throttle UI updates to avoid flooding setState at sensor rate.
  DateTime? _lastUiUpdateAt;
  static const _uiUpdateThrottleMs = 400;
  /// Persist live gait to storage so Dashboard and trends reflect real-time data.
  int _lastSavedStepCount = -1;
  DateTime? _lastSavedAt;
  static const _persistIntervalSec = 30;
  static const _persistStepDelta = 5;

  @override
  void initState() {
    super.initState();
    _sensorService = SensorService();
    _gaitService = GaitAnalysisService(_sensorService);
    _initMode();
  }

  Future<void> _initMode() async {
    _useDummy = await PreferencesService.getUseDummyData();
    if (_useDummy) {
      final snap = _dummy.dummySnapshot();
      if (mounted) {
        setState(() {
          _metrics = snap.gaitMetrics;
          _index = snap.gaitIndex ?? 75;
        });
      }
      await _loadTrends();
      return;
    }
    _gaitService.startListening();
    _sub = _gaitService.metricsStream.listen((m) {
      if (m == null || !mounted) return;
      final now = DateTime.now();
      final throttleOk = _lastUiUpdateAt == null ||
          now.difference(_lastUiUpdateAt!).inMilliseconds >= _uiUpdateThrottleMs;
      if (throttleOk) {
        _lastUiUpdateAt = now;
        setState(() {
          _metrics = m;
          _index = _gaitService.computeCogniawareIndex(m);
        });
      }
      _maybePersistLiveGait(m, now);
    });
    await _loadTrends();
  }

  /// Persist live gait to storage periodically so Dashboard and trends show real-time data.
  Future<void> _maybePersistLiveGait(GaitMetrics m, DateTime now) async {
    final stepDelta = m.stepCount - _lastSavedStepCount;
    final timeOk = _lastSavedAt == null ||
        now.difference(_lastSavedAt!).inSeconds >= _persistIntervalSec;
    final stepOk = stepDelta >= _persistStepDelta;
    final firstSteps = _lastSavedStepCount < 0 && m.stepCount >= 2;
    if (!timeOk && !stepOk && !firstSteps) return;
    _lastSavedStepCount = m.stepCount;
    _lastSavedAt = now;
    final gaitIndex = _gaitService.computeCogniawareIndex(m);
    final record = CogniawareRecord(
      id: 'live_${now.millisecondsSinceEpoch}',
      timestamp: now,
      cogniawareIndex: gaitIndex,
      gaitMetrics: m,
      gaitIndex: gaitIndex,
      typingMetrics: null,
      typingIndex: null,
      voiceMetrics: null,
      voiceIndex: null,
    );
    await _storage.insertRecord(record);
    if (mounted) await _loadTrends();
  }

  Future<void> _loadTrends() async {
    final records = await _storage.getRecordsForDays(30);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _gaitService.dispose();
    _storage.close();
    super.dispose();
  }

  int get _steps7Day {
    final withGait = _records.where((r) => r.gaitMetrics != null).toList();
    if (withGait.isEmpty) return _displayedMetrics?.stepCount ?? 0;
    final total = withGait.map((r) => r.gaitMetrics!.stepCount).reduce((a, b) => a + b);
    return (total / 7).round().clamp(0, 99999);
  }

  double get _km7Day => (_steps7Day * 0.75) / 1000;
  int get _spm7Day => _displayedMetrics?.cadence.round() ?? 0;

  /// Displayed gait: real sensor data when available, else dummy so UI is never empty.
  GaitMetrics? get _displayedMetrics =>
      _metrics ?? _dummy.dummySnapshot().gaitMetrics;
  double get _displayedIndex =>
      _metrics != null ? _index : (_dummy.dummySnapshot().gaitIndex ?? 75);

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final g = _displayedMetrics;

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: const CogniawareAppBar(title: 'Cogniaware'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_useDummy && _metrics == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Showing placeholder until sensor data arrives. Walk with your phone to see live steps.',
                  style: theme.caption?.copyWith(
                    color: CogniawareTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            Text('Gait Analysis', style: theme.headline?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              'Passive walking pattern monitoring',
              style: theme.caption?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            _sevenDayAverages(theme),
            const SizedBox(height: 20),
            _currentGaitIndexCard(theme),
            const SizedBox(height: 20),
            Text('Today\'s Activity', style: theme.subtitle1),
            const SizedBox(height: 12),
            _activityGrid(theme, g),
            const SizedBox(height: 24),
            Text('Advanced Gait Metrics', style: theme.subtitle1),
            const SizedBox(height: 12),
            _progressSection(theme, g),
            const SizedBox(height: 24),
            _gaitTrendsCard(theme),
                  const SizedBox(height: 24),
                  Text(
                    'How it works: Gait patterns are analyzed using device motion sensors. All processing happens locally on your device. No location data is collected.',
                    style: theme.caption?.copyWith(fontSize: 11),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sevenDayAverages(CogniawareTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CogniawareTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('$_steps7Day', style: theme.headline?.copyWith(fontSize: 24)),
              Text('Steps/day', style: theme.caption),
            ],
          ),
          Column(
            children: [
              Text(_km7Day.toStringAsFixed(2), style: theme.headline?.copyWith(fontSize: 24)),
              Text('km/day', style: theme.caption),
            ],
          ),
          Column(
            children: [
              Text('$_spm7Day', style: theme.headline?.copyWith(fontSize: 24)),
              Text('spm avg', style: theme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _currentGaitIndexCard(CogniawareTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CogniawareTheme.riskStable.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.riskStable.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Current Gait Index', style: theme.subtitle1),
          const SizedBox(height: 16),
          CogniawareGauge(value: _displayedIndex, size: 140, showLabel: true),
          const SizedBox(height: 12),
          Text(
            'Based on step count, cadence, symmetry, and variability',
            style: theme.caption?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _activityGrid(CogniawareTheme theme, GaitMetrics? g) {
    final steps = g?.stepCount ?? 0;
    final distKm = (g?.distanceEstimateM ?? 0) / 1000;
    final cadence = g?.cadence.round() ?? 0;
    final sym = ((g?.gaitSymmetry ?? 0) * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _activityCard(theme, Icons.directions_walk, 'Step Count', '$steps')),
            const SizedBox(width: 12),
            Expanded(child: _activityCard(theme, Icons.straighten, 'Distance', '${distKm.toStringAsFixed(2)} km')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _activityCard(theme, Icons.show_chart, 'Cadence', '$cadence spm')),
            const SizedBox(width: 12),
            Expanded(child: _activityCard(theme, Icons.balance, 'Symmetry', '$sym %')),
          ],
        ),
      ],
    );
  }

  Widget _activityCard(CogniawareTheme theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CogniawareTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CogniawareTheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.headline?.copyWith(fontSize: 18)),
          Text(label, style: theme.caption),
        ],
      ),
    );
  }

  Widget _progressSection(CogniawareTheme theme, GaitMetrics? g) {
    final variability = g != null ? (100 - (g.stepIntervalVariabilityMs / 2).clamp(0.0, 100.0)) : 77.0;
    final symmetry = (g?.gaitSymmetry ?? 0.9) * 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBarMetric(
            label: 'Step Variability',
            value: variability.clamp(0.0, 100.0),
            description: 'Lower is better (more consistent)',
            barColor: CogniawareTheme.riskStable,
          ),
          ProgressBarMetric(
            label: 'Gait Symmetry',
            value: symmetry.clamp(0.0, 100.0),
            description: 'Higher is better (balanced gait)',
            barColor: CogniawareTheme.progressBlue,
          ),
        ],
      ),
    );
  }

  Widget _gaitTrendsCard(CogniawareTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gait Trends', style: theme.subtitle1),
          const SizedBox(height: 12),
          Row(
            children: [7, 30, 90].map((d) {
              final selected = _trendDays == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: selected ? CogniawareTheme.primary : CogniawareTheme.cardGray,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      setState(() => _trendDays = d);
                      _loadTrends();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '$d Days',
                        style: theme.caption?.copyWith(
                          color: selected ? Colors.white : CogniawareTheme.textPrimary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(child: Text('No gait data yet', style: theme.caption))
                    : MultiMetricChart(
                        records: _records,
                        days: _trendDays,
                        height: 180,
                        showGait: true,
                        showTyping: false,
                        showVoice: false,
                      ),
          ),
        ],
      ),
    );
  }
}
