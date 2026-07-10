import 'package:flutter/material.dart';
import '../models/ping_result.dart';
import '../theme/retro_terminal_theme.dart';

/// Vitals monitor style history chart
class PingHistoryChart extends StatelessWidget {
  final List<PingResult> history;
  final double height;

  const PingHistoryChart({
    super.key,
    required this.history,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BlinkingCursor(
                width: 8,
                height: 14,
                color: RetroTerminalTheme.amberDim,
              ),
              const SizedBox(width: 8),
              Text(
                'NO DATA',
                style: RetroTerminalTheme.terminalText.copyWith(
                  fontSize: 11,
                  color: RetroTerminalTheme.amberDim,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history.map((result) {
          return _buildBar(result);
        }).toList(),
      ),
    );
  }

  Widget _buildBar(PingResult result) {
    final color = _getColorForStatus(result.status);
    final heightPercent = _calculateHeight(result);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.responseTimeMs != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${result.responseTimeMs}',
                  style: RetroTerminalTheme.terminalText.copyWith(
                    fontSize: 8,
                    color: color,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              height: height * heightPercent,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateHeight(PingResult result) {
    if (result.status == PingStatus.timeout) return 1.0;
    if (result.responseTimeMs == null) return 0.1;
    
    // Normalize: max 500ms = full height
    final maxMs = 500;
    final normalized = result.responseTimeMs! / maxMs;
    return normalized.clamp(0.1, 1.0);
  }

  Color _getColorForStatus(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return RetroTerminalTheme.vitalsStable;
      case PingStatus.fair:
        return RetroTerminalTheme.vitalsCaution;
      case PingStatus.poor:
        return RetroTerminalTheme.vitalsCritical;
      case PingStatus.timeout:
        return RetroTerminalTheme.vitalsFlatline;
      default:
        return RetroTerminalTheme.vitalsFlatline;
    }
  }
}

/// ECG-style waveform visualization
class VitalsWaveform extends StatelessWidget {
  final List<PingResult> history;
  final double height;

  const VitalsWaveform({
    super.key,
    required this.history,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '---',
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.vitalsFlatline,
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _WaveformPainter(history),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<PingResult> history;

  _WaveformPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final result = history[i];
      final x = i * stepX;
      
      // Calculate Y based on response time (inverted, lower is better)
      double normalizedY;
      if (result.status == PingStatus.timeout || result.responseTimeMs == null) {
        normalizedY = 0; // Bottom for timeout
      } else {
        normalizedY = 1 - (result.responseTimeMs! / 500).clamp(0.0, 1.0);
      }
      
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Create a slight curve for ECG effect
        final prevX = (i - 1) * stepX;
        final prevResult = history[i - 1];
        double prevNormalizedY;
        if (prevResult.status == PingStatus.timeout || prevResult.responseTimeMs == null) {
          prevNormalizedY = 0;
        } else {
          prevNormalizedY = 1 - (prevResult.responseTimeMs! / 500).clamp(0.0, 1.0);
        }
        final prevY = size.height - (prevNormalizedY * size.height);
        
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
      }

      // Set color based on status
      paint.color = _getColorForStatus(result.status);
    }

    canvas.drawPath(path, paint);

    // Draw glow effect
    final glowPaint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..color = paint.color.withOpacity(0.3);
    canvas.drawPath(path, glowPaint);
  }

  Color _getColorForStatus(PingStatus status) {
    switch (status) {
      case PingStatus.excellent:
        return RetroTerminalTheme.vitalsStable;
      case PingStatus.fair:
        return RetroTerminalTheme.vitalsCaution;
      case PingStatus.poor:
        return RetroTerminalTheme.vitalsCritical;
      case PingStatus.timeout:
        return RetroTerminalTheme.vitalsFlatline;
      default:
        return RetroTerminalTheme.vitalsFlatline;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
