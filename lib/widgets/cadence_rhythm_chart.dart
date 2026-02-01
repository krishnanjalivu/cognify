import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gait_metrics.dart';
import '../app_theme.dart';

/// Bar chart for cadence and rhythm consistency.
/// Animates bar growth from zero to actual values over ~1s.
class CadenceRhythmChart extends StatefulWidget {
  final GaitMetrics? metrics;
  final double height;
  final Duration tweenDuration;

  const CadenceRhythmChart({
    super.key,
    this.metrics,
    this.height = 120,
    this.tweenDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<CadenceRhythmChart> createState() => _CadenceRhythmChartState();
}

class _CadenceRhythmChartState extends State<CadenceRhythmChart>
    with SingleTickerProviderStateMixin {
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
    if (widget.metrics != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tweenController.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant CadenceRhythmChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metrics != null && widget.metrics != oldWidget.metrics) {
      _tweenController.forward(from: 0);
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
    if (widget.metrics == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('No gait data', style: theme.caption),
        ),
      );
    }

    final m = widget.metrics!;
    final cadenceNorm = (m.cadence / 120).clamp(0.0, 1.0);
    final rhythmNorm = m.rhythmConsistency.clamp(0.0, 1.0);
    final progress = _tweenAnimation.value;

    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: cadenceNorm * progress,
            color: CogniawareTheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: rhythmNorm * progress,
            color: CogniawareTheme.riskStable,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    ];

    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Cadence', style: theme.caption),
              Text('Rhythm', style: theme.caption),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 0) {
                          return Text(
                              '${m.cadence.toStringAsFixed(0)}/min',
                              style: theme.caption);
                        }
                        if (value.toInt() == 1) {
                          return Text(
                              '${(m.rhythmConsistency * 100).toStringAsFixed(0)}%',
                              style: theme.caption);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
