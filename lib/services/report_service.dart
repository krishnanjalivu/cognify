import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cogniaware_record.dart';

/// Generates downloadable cognitive health report (PDF). CSV in same folder.
class ReportService {
  /// Generate PDF and CSV; return file paths for sharing/save.
  static Future<ReportResult> generateReport({
    required List<CogniawareRecord> records,
    required int days,
  }) async {
    final dir = await getTemporaryDirectory();
    final baseName = 'Cogniaware_Report_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}';
    final pdfPath = '${dir.path}/$baseName.pdf';
    final csvPath = '${dir.path}/$baseName.csv';

    // PDF (uses default font; for custom fonts add pdf_font_loader or similar)
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Cogniaware Cognitive Health Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Paragraph(
            text: 'Generated on-device. Data never leaves your device.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Summary (last $days days)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _summaryParagraph(records),
          pw.SizedBox(height: 8),
          _walkingSummary(records),
          pw.SizedBox(height: 12),
          pw.Text(
            'Cogniaware Index over time',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          _indexTable(records),
          pw.SizedBox(height: 12),
          pw.Text(
            'Risk bands: Green ≥70 (stable), Yellow 45–70 (moderate), Orange <45 (increased variability).',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());

    // CSV
    final csv = _buildCsv(records);
    await File(csvPath).writeAsString(csv);

    return ReportResult(pdfPath: pdfPath, csvPath: csvPath);
  }

  static pw.Widget _summaryParagraph(List<CogniawareRecord> records) {
    if (records.isEmpty) {
      return pw.Paragraph(text: 'No records in this period.');
    }
    final avg = records.map((r) => r.cogniawareIndex).reduce((a, b) => a + b) / records.length;
    final min = records.map((r) => r.cogniawareIndex).reduce((a, b) => a < b ? a : b);
    final max = records.map((r) => r.cogniawareIndex).reduce((a, b) => a > b ? a : b);
    final stableCount = records.where((r) => r.cogniawareIndex >= 70).length;
    final moderateCount = records.where((r) => r.cogniawareIndex >= 45 && r.cogniawareIndex < 70).length;
    final increasedCount = records.where((r) => r.cogniawareIndex < 45).length;
    return pw.Paragraph(
      text: 'Records: ${records.length}. '
          'Cogniaware Index: average ${avg.toStringAsFixed(1)}, min ${min.toStringAsFixed(1)}, max ${max.toStringAsFixed(1)}. '
          'Distribution: $stableCount stable, $moderateCount moderate, $increasedCount increased variability.',
      style: const pw.TextStyle(fontSize: 10),
    );
  }

  static pw.Widget _walkingSummary(List<CogniawareRecord> records) {
    final withGait = records.where((r) => r.gaitMetrics != null).toList();
    if (withGait.isEmpty) {
      return pw.Paragraph(
        text: 'Walking / Gait: No step data in this period.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }
    int totalSteps = 0;
    double totalDistance = 0;
    for (final r in withGait) {
      final g = r.gaitMetrics!;
      totalSteps += g.stepCount;
      totalDistance += g.distanceEstimateM;
    }
    final avgCadence = withGait.map((r) => r.gaitMetrics!.cadence).reduce((a, b) => a + b) / withGait.length;
    return pw.Paragraph(
      text: 'Walking / Gait (last ${records.length} records with gait data): '
          'Total steps: $totalSteps. Estimated distance: ${totalDistance.toStringAsFixed(0)} m. '
          'Average cadence: ${avgCadence.toStringAsFixed(0)} steps/min.',
      style: const pw.TextStyle(fontSize: 10),
    );
  }

  static pw.Widget _indexTable(List<CogniawareRecord> records) {
    if (records.isEmpty) return pw.SizedBox();
    final limited = records.length > 50 ? records.sublist(0, 50) : records;
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Index', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Gait', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Steps', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Typing', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
          ],
        ),
        ...limited.map((r) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')} ${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(r.cogniawareIndex.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    r.gaitIndex?.toStringAsFixed(1) ?? '—',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    r.gaitMetrics?.stepCount.toString() ?? '—',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    r.typingIndex?.toStringAsFixed(1) ?? '—',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  static String _buildCsv(List<CogniawareRecord> records) {
    final sb = StringBuffer();
    sb.writeln('timestamp,cogniawareIndex,gaitIndex,typingIndex,voiceIndex,stepCount,distanceEstimateM');
    for (final r in records) {
      sb.writeln(
        '${r.timestamp.toIso8601String()},'
        '${r.cogniawareIndex.toStringAsFixed(2)},'
        '${r.gaitIndex?.toStringAsFixed(2) ?? ""},'
        '${r.typingIndex?.toStringAsFixed(2) ?? ""},'
        '${r.voiceIndex?.toStringAsFixed(2) ?? ""},'
        '${r.gaitMetrics?.stepCount ?? ""},'
        '${r.gaitMetrics?.distanceEstimateM.toStringAsFixed(2) ?? ""}',
      );
    }
    return sb.toString();
  }
}

class ReportResult {
  final String pdfPath;
  final String csvPath;
  ReportResult({required this.pdfPath, required this.csvPath});
}
