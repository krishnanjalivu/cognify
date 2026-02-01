import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';
import '../models/gait_metrics.dart';
import '../services/storage_service.dart';
import '../services/dummy_data_service.dart';
import '../services/preferences_service.dart';
import '../services/notifications_service.dart';
import '../widgets/cogniaware_app_bar.dart';
import '../widgets/cogniaware_gauge.dart';
import '../widgets/trend_chart.dart';

/// Home dashboard: Cogniaware Index card, Today's Metrics grid, Cogniaware Trend.
/// Modern, neat layout with blue header and Privacy First.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService();
  final DummyDataService _dummy = DummyDataService();

  List<CogniawareRecord> _records = [];
  int _trendDays = 30;
  CogniawareRecord? _snapshot;
  /// Latest record that has gait/typing/voice so Dashboard shows real-time data for each.
  CogniawareRecord? _latestGaitRecord;
  CogniawareRecord? _latestTypingRecord;
  CogniawareRecord? _latestVoiceRecord;
  bool _loading = true;
  bool _useDummyData = true;
  Timer? _liveRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _useDummyData = await PreferencesService.getUseDummyData();
    if (_useDummyData) {
      await _dummy.seedDummyDataIfNeeded();
      _snapshot = _dummy.dummySnapshot();
    } else {
      final records = await _storage.getRecordsForDays(7);
      _snapshot = records.isNotEmpty ? records.last : null;
      _liveRefreshTimer?.cancel();
      _liveRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted && !_useDummyData) _loadTrends();
      });
    }
    await _loadTrends();
  }

  Future<void> _loadTrends() async {
    final useDummy = await PreferencesService.getUseDummyData();
    if (mounted) setState(() => _useDummyData = useDummy);
    final records = await _storage.getRecordsForDays(_trendDays);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
        if (_useDummyData && _snapshot == null) _snapshot = _dummy.dummySnapshot();
        if (!_useDummyData && records.isNotEmpty) {
          _snapshot = records.last;
          _latestGaitRecord = records.where((r) => r.gaitMetrics != null).lastOrNull;
          _latestTypingRecord = records.where((r) => r.typingIndex != null).lastOrNull;
          _latestVoiceRecord = records.where((r) => r.voiceIndex != null).lastOrNull;
        } else if (_useDummyData) {
          _latestGaitRecord = null;
          _latestTypingRecord = null;
          _latestVoiceRecord = null;
        }
      });
      NotificationsService.evaluateTrendAndNotify(records);
    }
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _storage.close();
    super.dispose();
  }

  double get _currentIndex {
    if (_useDummyData) return _snapshot?.cogniawareIndex ?? 0;
    final g = _latestGaitRecord?.gaitIndex ?? 0;
    final t = _typingIndex;
    final v = _voiceIndex;
    return (g * 0.5 + t * 0.3 + v * 0.2).clamp(0.0, 100.0);
  }
  GaitMetrics? get _currentGait => _latestGaitRecord?.gaitMetrics ?? _snapshot?.gaitMetrics;
  int get _stepsToday => _currentGait?.stepCount ?? 0;
  double get _distanceKm => (_currentGait?.distanceEstimateM ?? 0) / 1000;
  /// Typing: real data from storage, or dummy placeholder until user does a typing exercise.
  double get _typingIndex =>
      _latestTypingRecord?.typingIndex ?? _snapshot?.typingIndex ?? _dummy.dummySnapshot().typingIndex ?? 75;
  /// Voice: real data from storage, or dummy placeholder until user does a voice exercise.
  double get _voiceIndex =>
      _latestVoiceRecord?.voiceIndex ?? _snapshot?.voiceIndex ?? _dummy.dummySnapshot().voiceIndex ?? 76;

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final riskLevel = CogniawareTheme.riskLevelForIndex(_currentIndex);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: const CogniawareAppBar(title: 'Cogniaware'),
      body: RefreshIndicator(
        onRefresh: _loadTrends,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cogniaware Index card
              _indexCard(theme, riskLevel),
              const SizedBox(height: 20),
              // Today's Metrics grid
              Text('Today\'s Metrics', style: theme.subtitle1),
              const SizedBox(height: 12),
              _metricsGrid(theme),
              const SizedBox(height: 24),
              // Index Breakdown (3 small gauges)
              Text('Index Breakdown', style: theme.subtitle1),
              const SizedBox(height: 12),
              _indexBreakdown(theme),
              const SizedBox(height: 24),
              // Cogniaware Trend
              _trendCard(theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indexCard(CogniawareTheme theme, CogniawareRiskLevel riskLevel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cogniaware Index', style: theme.headline?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Your Composite Cognitive Health Score',
            style: theme.caption?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          Center(
            child: CogniawareGauge(
              value: _currentIndex,
              size: 180,
              showLabel: true,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Trend: ', style: theme.body),
                Icon(Icons.arrow_forward, size: 16, color: CogniawareTheme.primary),
                const SizedBox(width: 4),
                Text(
                  riskLevel == CogniawareRiskLevel.stable
                      ? 'Stable'
                      : riskLevel == CogniawareRiskLevel.moderate
                          ? 'Moderate'
                          : 'Variable',
                  style: theme.subtitle1?.copyWith(color: CogniawareTheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CogniawareTheme.cardGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: CogniawareTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy First: All data processed on your device. Nothing is shared.',
                    style: theme.caption?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _metricsGrid(CogniawareTheme theme) {
    final stepsStr = _formatSteps(_stepsToday);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.directions_walk,
                label: 'Steps Today',
                value: stepsStr,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${_distanceKm.toStringAsFixed(2)} km',
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.keyboard,
                label: 'Typing Index',
                value: _typingIndex.round().toString(),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.mic,
                label: 'Voice Index',
                value: _voiceIndex.round().toString(),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required CogniawareTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CogniawareTheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.headline?.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: theme.caption),
        ],
      ),
    );
  }

  Widget _indexBreakdown(CogniawareTheme theme) {
    final gaitIndex = _snapshot?.gaitIndex ?? _currentIndex;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniGauge(theme, gaitIndex, 'Gait'),
          _miniGauge(theme, _typingIndex, 'Typing'),
          _miniGauge(theme, _voiceIndex, 'Voice'),
        ],
      ),
    );
  }

  Widget _miniGauge(CogniawareTheme theme, double value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CogniawareGauge(value: value, size: 80, showLabel: true),
        const SizedBox(height: 8),
        Text('$label →', style: theme.caption?.copyWith(color: CogniawareTheme.primary)),
      ],
    );
  }

  Widget _trendCard(CogniawareTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CogniawareTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cogniaware Trend', style: theme.subtitle1),
              Icon(Icons.open_in_new, size: 18, color: CogniawareTheme.textSecondary),
            ],
          ),
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
            height: 200,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TrendChart(records: _records, days: _trendDays, height: 200),
          ),
        ],
      ),
    );
  }
}
