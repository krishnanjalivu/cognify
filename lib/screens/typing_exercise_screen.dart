import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/typing_metrics.dart';
import '../models/cogniaware_record.dart';
import '../services/typing_exercise_service.dart';
import '../services/storage_service.dart';
import '../widgets/risk_indicator.dart';

/// Typing exercise: type the shown phrase. Only key timings are stored; content is not recorded.
class TypingExerciseScreen extends StatefulWidget {
  const TypingExerciseScreen({super.key});

  @override
  State<TypingExerciseScreen> createState() => _TypingExerciseScreenState();
}

class _TypingExerciseScreenState extends State<TypingExerciseScreen> {
  final StorageService _storage = StorageService();
  final List<int> _timestampsMs = [];
  final TextEditingController _controller = TextEditingController();

  String _prompt = '';
  TypingMetrics? _result;
  double _typingIndex = 0;
  bool _saved = false;
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _prompt = TypingExerciseService.getRandomPrompt();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final len = _controller.text.length;
    if (len > _lastLen) {
      _timestampsMs.add(DateTime.now().millisecondsSinceEpoch);
    }
    _lastLen = len;
  }

  Future<void> _submit() async {
    if (_timestampsMs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type at least a few characters.')),
      );
      return;
    }
    final metrics = TypingExerciseService.computeFromTimestamps(_timestampsMs);
    final index = TypingExerciseService.typingIndexFromMetrics(metrics);
    setState(() {
      _result = metrics;
      _typingIndex = index;
    });
    final records = await _storage.getRecordsForDays(7);
    final latestGait = records.where((r) => r.gaitIndex != null).lastOrNull;
    final latestVoice = records.where((r) => r.voiceIndex != null).lastOrNull;
    final gaitIndex = latestGait?.gaitIndex ?? 0;
    final voiceIndex = latestVoice?.voiceIndex ?? 0;
    final combined = (gaitIndex * 0.5 + index * 0.3 + voiceIndex * 0.2).clamp(0.0, 100.0);
    await _storage.insertRecord(CogniawareRecord(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      cogniawareIndex: combined,
      gaitMetrics: latestGait?.gaitMetrics,
      gaitIndex: latestGait?.gaitIndex,
      typingMetrics: metrics,
      typingIndex: index,
      voiceMetrics: latestVoice?.voiceMetrics,
      voiceIndex: latestVoice?.voiceIndex,
    ));
    if (mounted) setState(() => _saved = true);
  }

  void _newPrompt() {
    setState(() {
      _prompt = TypingExerciseService.getRandomPrompt();
      _controller.clear();
      _timestampsMs.clear();
      _lastLen = 0;
      _result = null;
      _saved = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _storage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: AppBar(
        title: const Text('Typing Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newPrompt,
            tooltip: 'New prompt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Type the phrase below. Only timing is recorded—what you type is not stored.',
              style: theme.caption,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: CogniawareTheme.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CogniawareTheme.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _prompt,
                  style: theme.subtitle1?.copyWith(
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Type here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: CogniawareTheme.surfaceLight,
              ),
              maxLines: 2,
              enabled: _result == null,
            ),
            const SizedBox(height: 20),
            if (_result == null)
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Submit (timing only)'),
                style: FilledButton.styleFrom(
                  backgroundColor: CogniawareTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else ...[
              RiskIndicator(
                level: CogniawareTheme.riskLevelForIndex(_typingIndex),
                compact: false,
              ),
              const SizedBox(height: 16),
              Text(
                'Typing index: ${_typingIndex.toStringAsFixed(1)}',
                style: theme.subtitle1,
              ),
              const SizedBox(height: 8),
              Text(
                'Avg inter-key: ${_result!.avgFlightTimeMs.toStringAsFixed(0)} ms · '
                'Variability: ${_result!.dwellVariability.toStringAsFixed(0)} · '
                'Rhythm: ${(_result!.rhythmConsistency * 100).toStringAsFixed(0)}%',
                style: theme.caption,
              ),
              if (_saved)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Saved to your trends.', style: theme.caption),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _newPrompt,
                icon: const Icon(Icons.refresh),
                label: const Text('New phrase'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
