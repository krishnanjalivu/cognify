import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';

/// Line chart with multiple series: Combined, Gait, Typing, Voice indices.
/// Animates from zero/baseline to actual data over 1.2s (tween).
class MultiMetricChart extends StatefulWidget {
  final List<CogniawareRecord> records;
  final int days;
  final double height;
  final bool showGait;
  final bool showTyping;
  final bool showVoice;
  /// Duration for the line/bar growth animation (0.5–2 seconds).
  final Duration tweenDuration;

  const MultiMetricChart({
    super.key,
    required this.records,
    this.days = 7,
    this.height = 200,
    this.showGait = true,
    this.showTyping = true,
    this.showVoice = true,
    this.tweenDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<MultiMetricChart> createState() => _MultiMetricChartState();
}

class _MultiMetricChartState extends State<MultiMetricChart>
    with SingleTickerProviderStateMixin {
  List<CogniawareRecord> _displayRecords = [];
  late AnimationController _tweenController;
  late Animation<double> _tweenAnimation;

  @override
  void initState() {
    super.initState();
    _tweenController = AnimationController(
      vsync: this,
      duration: widget.tweenDuration,
    );
    _tweenAnimation = CurvedAnimation(
      parent: _tweenController,
      curve: Curves.easeOutCubic,
    );
    _tweenController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.records.isNotEmpty) {
        setState(() => _displayRecords = widget.records);
        _tweenController.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MultiMetricChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _displayRecords = [];
      _tweenController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.records.isNotEmpty) {
          setState(() => _displayRecords = widget.records);
          _tweenController.forward(from: 0);
        }
      });
    }
    if (oldWidget.tweenDuration != widget.tweenDuration) {
      _tweenController.duration = widget.tweenDuration;
    }
  }

  @override
  void dispose() {
    _tweenController.dispose();
    super.dispose();
  }

  double get _progress => _tweenAnimation.value;

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final records = _displayRecords;
    if (records.isEmpty && widget.records.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('No data for the last ${widget.days} days', style: theme.caption),
        ),
      );
    }
    if (records.isEmpty) {
      return SizedBox(
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()));
    }

    final lineBars = <LineChartBarData>[
      _bar(records, (r) => r.cogniawareIndex, CogniawareTheme.primary, 'Index'),
    ];
    if (widget.showGait) {
      final withGait = records.where((r) => r.gaitIndex != null).toList();
      if (withGait.isNotEmpty) {
        lineBars.add(_barFromIndices(
            withGait, (r) => r.gaitIndex!, CogniawareTheme.riskStable, 'Gait'));
      }
    }
    if (widget.showTyping) {
      final withTyping = records.where((r) => r.typingIndex != null).toList();
      if (withTyping.isNotEmpty) {
        lineBars.add(_barFromIndices(withTyping, (r) => r.typingIndex!,
            CogniawareTheme.riskModerate, 'Typing'));
      }
    }
    if (widget.showVoice) {
      final withVoice = records.where((r) => r.voiceIndex != null).toList();
      if (withVoice.isNotEmpty) {
        lineBars.add(_barFromIndices(withVoice, (r) => r.voiceIndex!,
            CogniawareTheme.riskIncreased, 'Voice'));
      }
    }

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: CogniawareTheme.divider,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: theme.caption,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round().clamp(0, records.length - 1);
                  if (records.isEmpty) return const SizedBox.shrink();
                  final step =
                      (records.length / 4).ceil().clamp(1, records.length);
                  if (i % step != 0 && i != records.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = records[i].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${d.month}/${d.day}', style: theme.caption),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (records.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: lineBars,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Build bar with y values scaled by tween progress (start from zero).
  LineChartBarData _bar(
    List<CogniawareRecord> list,
    double Function(CogniawareRecord) getY,
    Color color,
    String label,
  ) {
    final spots = list.asMap().entries.map((e) {
      final y = getY(e.value) * _progress;
      return FlSpot(e.key.toDouble(), y);
    }).toList();
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: list.length <= 14,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    );
  }

  LineChartBarData _barFromIndices(
    List<CogniawareRecord> list,
    double Function(CogniawareRecord) getY,
    Color color,
    String label,
  ) {
    final spots = list.asMap().entries.map((e) {
      final y = getY(e.value) * _progress;
      return FlSpot(e.key.toDouble(), y);
    }).toList();
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: list.length <= 14,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}
