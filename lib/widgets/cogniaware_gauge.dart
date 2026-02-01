import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Circular gauge for Cogniaware Index (0–100) with color by risk level.
/// Animates smoothly when [value] changes.
class CogniawareGauge extends StatefulWidget {
  final double value; // 0–100
  final double size;
  final bool showLabel;

  const CogniawareGauge({
    super.key,
    required this.value,
    this.size = 160,
    this.showLabel = true,
  });

  @override
  State<CogniawareGauge> createState() => _CogniawareGaugeState();
}

class _CogniawareGaugeState extends State<CogniawareGauge> {
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant CogniawareGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    } else {
      _previousValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previousValue, end: widget.value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final riskLevel = CogniawareTheme.riskLevelForIndex(animValue);
        final color = theme.riskColor(riskLevel);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  value: animValue,
                  backgroundColor: CogniawareTheme.surfaceLight,
                  progressColor: color,
                  strokeWidth: widget.size * 0.08,
                ),
              ),
              if (widget.showLabel)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animValue.round().toString(),
                      style: theme.headlineIndex?.copyWith(fontSize: widget.size * 0.22),
                    ),
                    Text(
                      '/ 100',
                      style: theme.caption?.copyWith(
                          fontSize: widget.size * 0.06,
                          color: CogniawareTheme.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _GaugePainter({
    required this.value,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    const startAngle = -3.0 * 3.1415926535 / 2; // top
    const sweepFull = 3.1415926535; // half circle

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = (value / 100.0).clamp(0.0, 1.0) * sweepFull;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.progressColor != progressColor;
}
