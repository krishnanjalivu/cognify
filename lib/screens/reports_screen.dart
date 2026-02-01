import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/storage_service.dart';
import '../services/report_service.dart';
import '../widgets/cogniaware_app_bar.dart';

/// Generate and download cognitive health report (PDF + CSV).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final StorageService _storage = StorageService();
  int _selectedDays = 30;
  bool _generating = false;
  String? _lastPdfPath;
  String? _lastCsvPath;

  @override
  void dispose() {
    _storage.close();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() => _generating = true);
    try {
      final records = await _storage.getRecordsForDays(_selectedDays);
      final result = await ReportService.generateReport(
        records: records,
        days: _selectedDays,
      );
      if (mounted) {
        setState(() {
          _generating = false;
          _lastPdfPath = result.pdfPath;
          _lastCsvPath = result.csvPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report saved. PDF: ${result.pdfPath.split('/').last}\nCSV: ${result.csvPath.split('/').last}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: const CogniawareAppBar(title: 'Cogniaware'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Generate a cognitive health report with Cogniaware Index, gait, typing, and voice trends. Report is created on-device and saved locally.',
            style: theme.body,
          ),
          const SizedBox(height: 24),
          Text('Period', style: theme.subtitle1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [7, 30, 90].map((d) {
              final selected = _selectedDays == d;
              return ChoiceChip(
                label: Text('$d days'),
                selected: selected,
                onSelected: (_) => setState(() => _selectedDays = d),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _generating ? null : _generateReport,
            icon: _generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_generating ? 'Generating…' : 'Generate report (PDF + CSV)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: CogniawareTheme.primary,
            ),
          ),
          if (_lastPdfPath != null) ...[
            const SizedBox(height: 20),
            Text('Last report', style: theme.subtitle1),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: CogniawareTheme.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CogniawareTheme.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PDF: $_lastPdfPath', style: theme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('CSV: $_lastCsvPath', style: theme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Report contents: Cogniaware Index over time, gait/typing/voice indices, summary stats, and risk band distribution. No raw data is included.',
            style: theme.caption,
          ),
        ],
      ),
    );
  }
}
