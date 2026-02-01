import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';
import '../services/dummy_data_service.dart';
import '../services/storage_service.dart';
import '../widgets/cogniaware_app_bar.dart';
import '../widgets/cogniaware_gauge.dart';
import '../widgets/progress_bar_metric.dart';
import '../widgets/multi_metric_chart.dart';
import 'typing_exercise_screen.dart';

/// Typing Metrics: Current Typing Index, Today's Patterns (Dwell, Flight, Variability).
/// Modern, neat layout with blue header.
class TypingMetricsScreen extends StatefulWidget {
  const TypingMetricsScreen({super.key});

  @override
  State<TypingMetricsScreen> createState() => _TypingMetricsScreenState();
}

class _TypingMetricsScreenState extends State<TypingMetricsScreen> {
  final StorageService _storage = StorageService();
  final DummyDataService _dummy = DummyDataService();
  List<CogniawareRecord> _records = [];
  int _trendDays = 30;
  bool _loading = true;
  /// Latest record with typing data from storage (real-time). Null = show dummy placeholder.
  CogniawareRecord? _latestTypingRecord;

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
        _latestTypingRecord = records.where((r) => r.typingIndex != null).lastOrNull;
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
    final r = _latestTypingRecord;
    final dummySnap = _dummy.dummySnapshot();
    final typingIndex = r?.typingIndex ?? dummySnap.typingIndex ?? 75.0;
    final t = r?.typingMetrics ?? dummySnap.typingMetrics;
    final dwellMs = t?.avgDwellTimeMs ?? 120.0;
    final flightMs = t?.avgFlightTimeMs ?? 150.0;
    final dwellVar = (t?.dwellVariability ?? 25).roundToDouble();
    final flightVar = (t != null ? (t.rhythmConsistency * 100 * 0.6 + 20) : 35).roundToDouble();

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
            Text('Typing Metrics', style: theme.headline?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              'Passive keystroke rhythm analysis',
              style: theme.caption?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            _currentTypingIndexCard(theme, typingIndex),
            const SizedBox(height: 20),
            Text('Today\'s Patterns', style: theme.subtitle1),
            const SizedBox(height: 12),
            _patternsGrid(theme, dwellMs, flightMs, dwellVar, flightVar),
            const SizedBox(height: 24),
            Text('Understanding the Metrics', style: theme.subtitle1),
            const SizedBox(height: 12),
            _definitionsCard(theme),
            const SizedBox(height: 24),
            Text('Rhythm Consistency', style: theme.subtitle1),
            const SizedBox(height: 12),
            _rhythmCard(theme, dwellVar, flightVar),
            const SizedBox(height: 24),
            _trendCard(theme),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TypingExerciseScreen(),
                    ),
                  );
                  if (mounted) await _loadTrends();
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('Do typing exercise'),
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

  Widget _currentTypingIndexCard(CogniawareTheme theme, double typingIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CogniawareTheme.cardGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CogniawareTheme.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Text('Current Typing Index', style: theme.subtitle1),
          const SizedBox(height: 16),
          CogniawareGauge(value: typingIndex, size: 140, showLabel: true),
          const SizedBox(height: 12),
          Text(
            'Based on typing rhythm, timing consistency, and patterns',
            style: theme.caption?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _patternsGrid(CogniawareTheme theme, double dwellMs, double flightMs, double dwellVar, double flightVar) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _patternCard(theme, Icons.schedule, 'Dwell Time', '${dwellMs.round()} ms')),
            const SizedBox(width: 12),
            Expanded(child: _patternCard(theme, Icons.flash_on, 'Flight Time', '${flightMs.round()} ms')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _patternCard(theme, Icons.grid_on, 'Dwell Variability', '${dwellVar.round()} %')),
            const SizedBox(width: 12),
            Expanded(child: _patternCard(theme, Icons.grid_on, 'Flight Variability', '${flightVar.round()} %')),
          ],
        ),
      ],
    );
  }

  Widget _patternCard(CogniawareTheme theme, IconData icon, String label, String value) {
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

  Widget _definitionsCard(CogniawareTheme theme) {
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
          Text('Dwell Time: How long keys are pressed', style: theme.body),
          const SizedBox(height: 8),
          Text('Flight Time: Time between key releases and next press', style: theme.body),
          const SizedBox(height: 8),
          Text('Variability: Consistency of typing rhythm (lower is more consistent)', style: theme.body),
        ],
      ),
    );
  }

  Widget _rhythmCard(CogniawareTheme theme, double dwellVar, double flightVar) {
    final dwellConsistency = (100 - dwellVar).clamp(0.0, 100.0);
    final flightConsistency = (100 - flightVar).clamp(0.0, 100.0);
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
            label: 'Dwell Time Consistency',
            value: dwellConsistency,
            description: 'Good consistency',
            barColor: CogniawareTheme.progressPurple,
          ),
          ProgressBarMetric(
            label: 'Flight Time Consistency',
            value: flightConsistency,
            description: 'Good consistency',
            barColor: CogniawareTheme.progressPurple,
          ),
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
          Text('Typing Trends', style: theme.subtitle1),
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
                    ? Center(child: Text('No typing data yet', style: theme.caption))
                    : MultiMetricChart(
                        records: _records,
                        days: _trendDays,
                        height: 180,
                        showGait: false,
                        showTyping: true,
                        showVoice: false,
                      ),
          ),
        ],
      ),
    );
  }
}
