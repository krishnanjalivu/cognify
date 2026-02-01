import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../app_theme.dart';
import '../models/voice_metrics.dart';
import '../models/cogniaware_record.dart';
import '../services/voice_exercise_service.dart';
import '../services/storage_service.dart';
import '../widgets/risk_indicator.dart';

/// Voice exercise: read a prompt aloud. Speech processed on-device and discarded.
/// Results (Type-Token Ratio, complexity, rhythm) feed into Cogniaware Index.
class VoiceExerciseScreen extends StatefulWidget {
  const VoiceExerciseScreen({super.key});

  @override
  State<VoiceExerciseScreen> createState() => _VoiceExerciseScreenState();
}

class _VoiceExerciseScreenState extends State<VoiceExerciseScreen> {
  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = StorageService();

  String _prompt = '';
  bool _listening = false;
  String _status = '';
  VoiceMetrics? _result;
  double _voiceIndex = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _prompt = VoiceExerciseService.getRandomPrompt();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (!available) {
      setState(() => _status = 'Speech recognition not available.');
      return;
    }
    setState(() {
      _listening = true;
      _status = 'Listening... Read the sentence aloud.';
      _result = null;
      _saved = false;
    });
    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult || result.recognizedWords.isEmpty) return;
        _speech.stop();
        final metrics = VoiceExerciseService.computeFromTranscript(
          result.recognizedWords,
        );
        final index = VoiceExerciseService.voiceIndexFromMetrics(metrics);
        setState(() {
          _listening = false;
          _status = 'Done. Processing on-device only; audio discarded.';
          _result = metrics;
          _voiceIndex = index;
        });
        _saveResult(metrics, index);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: false,
        cancelOnError: false,
      ),
    );
  }

  Future<void> _saveResult(VoiceMetrics metrics, double voiceIndex) async {
    final records = await _storage.getRecordsForDays(7);
    final latestGait = records.where((r) => r.gaitIndex != null).lastOrNull;
    final latestTyping = records.where((r) => r.typingIndex != null).lastOrNull;
    final gaitIndex = latestGait?.gaitIndex ?? 0;
    final typingIndex = latestTyping?.typingIndex ?? 0;
    final combined = (gaitIndex * 0.5 + typingIndex * 0.3 + voiceIndex * 0.2).clamp(0.0, 100.0);
    await _storage.insertRecord(CogniawareRecord(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      cogniawareIndex: combined,
      gaitMetrics: latestGait?.gaitMetrics,
      gaitIndex: latestGait?.gaitIndex,
      typingMetrics: latestTyping?.typingMetrics,
      typingIndex: latestTyping?.typingIndex,
      voiceMetrics: metrics,
      voiceIndex: voiceIndex,
    ));
    if (mounted) setState(() => _saved = true);
  }

  void _newPrompt() {
    setState(() {
      _prompt = VoiceExerciseService.getRandomPrompt();
      _status = '';
      _result = null;
      _saved = false;
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _storage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: AppBar(
        title: const Text('Voice Exercise'),
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
              'Read the sentence aloud. Speech is processed on-device and discarded—only metrics are stored.',
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
                padding: const EdgeInsets.all(20),
                child: Text(
                  _prompt,
                  style: theme.subtitle1?.copyWith(
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_listening)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(_status, style: theme.body),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.mic),
                label: const Text('Start listening'),
                style: FilledButton.styleFrom(
                  backgroundColor: CogniawareTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            if (_status.isNotEmpty && !_listening)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_status, style: theme.caption),
              ),
            if (_result != null) ...[
              const SizedBox(height: 28),
              RiskIndicator(
                level: CogniawareTheme.riskLevelForIndex(_voiceIndex),
                compact: false,
              ),
              const SizedBox(height: 16),
              Text('Voice index: ${_voiceIndex.toStringAsFixed(1)}', style: theme.subtitle1),
              const SizedBox(height: 8),
              Text(
                'Type-Token Ratio: ${(_result!.typeTokenRatio * 100).toStringAsFixed(0)}% · '
                'Complexity: ${(_result!.complexityScore * 100).toStringAsFixed(0)}% · '
                'Rhythm: ${(_result!.speechRhythmConsistency * 100).toStringAsFixed(0)}%',
                style: theme.caption,
              ),
              if (_saved)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Saved to your trends.', style: theme.caption),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
