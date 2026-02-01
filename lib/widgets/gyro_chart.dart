import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';

/// Line chart of gyroscope-derived stability (gyroStability 0–1) over time.
/// Animates from zero to actual values over ~1.2s.
class GyroChart extends StatefulWidget {
  final List<CogniawareRecord> records;
  final int days;
  final double height;
  final Duration tweenDuration;

  const GyroChart({
    super.key,
    required this.records,
    this.days = 7,
    this.height = 140,
    this.tweenDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<GyroChart> createState() => _GyroChartState();
}

class _GyroChartState extends State<GyroChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _tweenController;
  late Animation<double> _tweenAnimation;
  List<CogniawareRecord> _withGyro = [];

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
        _withGyro =
            widget.records.where((r) => r.gaitMetrics != null).toList();
        if (_withGyro.isNotEmpty) {
          setState(() {});
          _tweenController.forward(from: 0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant GyroChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _withGyro = widget.records.where((r) => r.gaitMetrics != null).toList();
      if (_withGyro.isNotEmpty) _tweenController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tweenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    final withGyro =
        _withGyro.isNotEmpty ? _withGyro : widget.records.where((r) => r.gaitMetrics != null).toList();
    if (withGyro.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No gyroscope stability data for the last ${widget.days} days',
            style: theme.caption,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final progress = _tweenAnimation.value;
    final spots = withGyro.asMap().entries.map((e) {
      final y = e.value.gaitMetrics!.gyroStability * progress;
      return FlSpot(e.key.toDouble(), y);
    }).toList();

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
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
                interval: 0.25,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
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
                  final i = value.round().clamp(0, withGyro.length - 1);
                  if (withGyro.isEmpty) return const SizedBox.shrink();
                  final step =
                      (withGyro.length / 4).ceil().clamp(1, withGyro.length);
                  if (i % step != 0 && i != withGyro.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = withGyro[i].timestamp;
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
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 1.0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: CogniawareTheme.riskModerate,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 14,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: CogniawareTheme.riskModerate,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: CogniawareTheme.riskModerate.withValues(alpha: 0.1),
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
