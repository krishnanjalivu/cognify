import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cogniaware_record.dart';
import '../app_theme.dart';

/// Trend line of Cogniaware Index over time (7 / 30 / 90 days).
/// Animates from zero to actual values over 1.2s (tween).
class TrendChart extends StatefulWidget {
  final List<CogniawareRecord> records;
  final int days;
  final double height;
  /// Duration for the line growth animation (0.5–2 seconds).
  final Duration tweenDuration;

  const TrendChart({
    super.key,
    required this.records,
    this.days = 7,
    this.height = 180,
    this.tweenDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart>
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
  void didUpdateWidget(covariant TrendChart oldWidget) {
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
          child: Text(
            'No data for the last ${widget.days} days',
            style: theme.caption,
          ),
        ),
      );
    }
    if (records.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final spots = records.asMap().entries.map((e) {
      final y = e.value.cogniawareIndex * _progress;
      return FlSpot(e.key.toDouble(), y);
    }).toList();

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
                    child: Text(
                      '${d.month}/${d.day}',
                      style: theme.caption,
                    ),
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: CogniawareTheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: records.length <= 14,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: CogniawareTheme.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: CogniawareTheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
