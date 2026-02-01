import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';
import '../services/dummy_data_service.dart';
import '../services/storage_service.dart';
import '../widgets/cogniaware_app_bar.dart';
import '../widgets/cogniaware_gauge.dart';
import '../widgets/multi_metric_chart.dart';
import 'voice_exercise_screen.dart';

/// Voice Metrics: Current Voice Index, metrics, trend. Modern, neat layout.
class VoiceMetricsScreen extends StatefulWidget {
  const VoiceMetricsScreen({super.key});

  @override
  State<VoiceMetricsScreen> createState() => _VoiceMetricsScreenState();
}

class _VoiceMetricsScreenState extends State<VoiceMetricsScreen> {
  final StorageService _storage = StorageService();
  final DummyDataService _dummy = DummyDataService();
  List<CogniawareRecord> _records = [];
  int _trendDays = 30;
  bool _loading = true;
  /// Latest record with voice data from storage (real-time). Null = show dummy placeholder.
  CogniawareRecord? _latestVoiceRecord;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    final records = await _storage.getRecordsForDays(30);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
        _latestVoiceRecord = records.where((r) => r.voiceIndex != null).lastOrNull;
      });
    }
  }

  @override
  void dispose() {
    _storage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final r = _latestVoiceRecord;
    final dummySnap = _dummy.dummySnapshot();
    final voiceIndex = r?.voiceIndex ?? dummySnap.voiceIndex ?? 76.0;
    final v = r?.voiceMetrics ?? dummySnap.voiceMetrics;
    final ttr = ((v?.typeTokenRatio ?? 0.65) * 100).round();
    final complexity = ((v?.complexityScore ?? 0.75) * 100).round();
    final rhythm = ((v?.speechRhythmConsistency ?? 0.8) * 100).round();

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
            Text('Voice Metrics', style: theme.headline?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              'Active voice exercise analysis',
              style: theme.caption?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            _currentVoiceIndexCard(theme, voiceIndex),
            const SizedBox(height: 20),
            Text('Today\'s Metrics', style: theme.subtitle1),
            const SizedBox(height: 12),
            _metricsGrid(theme, ttr, complexity, rhythm),
            const SizedBox(height: 24),
            _trendCard(theme),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VoiceExerciseScreen(),
                    ),
                  );
                  if (mounted) await _loadTrends();
                },
                icon: const Icon(Icons.mic),
                label: const Text('Do voice exercise'),
                style: FilledButton.styleFrom(
                  backgroundColor: CogniawareTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _currentVoiceIndexCard(CogniawareTheme theme, double voiceIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CogniawareTheme.cardGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Text('Current Voice Index', style: theme.subtitle1),
          const SizedBox(height: 16),
          CogniawareGauge(value: voiceIndex, size: 140, showLabel: true),
          const SizedBox(height: 12),
          Text(
            'Based on Type-Token Ratio, complexity, and speech rhythm',
            style: theme.caption?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(CogniawareTheme theme, int ttr, int complexity, int rhythm) {
    return Row(
      children: [
        Expanded(child: _metricCard(theme, Icons.abc, 'Type-Token', '$ttr%')),
        const SizedBox(width: 12),
        Expanded(child: _metricCard(theme, Icons.psychology, 'Complexity', '$complexity%')),
        const SizedBox(width: 12),
        Expanded(child: _metricCard(theme, Icons.graphic_eq, 'Rhythm', '$rhythm%')),
      ],
    );
  }

  Widget _metricCard(CogniawareTheme theme, IconData icon, String label, String value) {
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

  Widget _trendCard(CogniawareTheme theme) {
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
          Text('Voice Trends', style: theme.subtitle1),
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
                    ? Center(child: Text('No voice data yet', style: theme.caption))
                    : MultiMetricChart(
                        records: _records,
                        days: _trendDays,
                        height: 180,
                        showGait: false,
                        showTyping: false,
                        showVoice: true,
                      ),
          ),
        ],
      ),
    );
  }
}
