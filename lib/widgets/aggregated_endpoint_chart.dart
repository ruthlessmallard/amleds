import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ping_result.dart';
import '../theme/retro_terminal_theme.dart';

/// Aggregated chart showing all endpoints together with overlapping lines
class AggregatedEndpointChart extends StatelessWidget {
  final Map<String, List<PingResult>> allHistory;
  final double height;
  final int criticalThreshold;

  const AggregatedEndpointChart({
    super.key,
    required this.allHistory,
    this.height = 120,
    required this.criticalThreshold,
  });

  @override
  Widget build(BuildContext context) {
    if (allHistory.isEmpty) {
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
                'NO ENDPOINT DATA',
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

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: RetroTerminalTheme.amberDim.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Y-axis label
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'LATENCY (MS)',
                    style: RetroTerminalTheme.terminalText.copyWith(
                      fontSize: 10,
                      color: RetroTerminalTheme.amberDim,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    size: Size(double.infinity, height - 60),
                    painter: _AggregatedChartPainter(allHistory, criticalThreshold),
                  ),
                ),
              ],
            ),
          ),
          // X-axis label
          Text(
            'TIME →',
            style: RetroTerminalTheme.terminalText.copyWith(
              fontSize: 10,
              color: RetroTerminalTheme.amberDim,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregatedChartPainter extends CustomPainter {
  final Map<String, List<PingResult>> allHistory;
  final int criticalThreshold;
  final Map<String, Color> _endpointColors = {};

  _AggregatedChartPainter(this.allHistory, this.criticalThreshold) {
    _generateRandomColors();
  }

  void _generateRandomColors() {
    final random = Random(42); // Fixed seed for consistent colors per session
    final endpoints = allHistory.keys.toList();
    
    // Predefined color palette for better visibility
    final colorPalette = [
      RetroTerminalTheme.vitalsStable,
      RetroTerminalTheme.vitalsCaution,
      RetroTerminalTheme.vitalsCritical,
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Magenta  
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF8000), // Orange
      const Color(0xFF8000FF), // Purple
      const Color(0xFF0080FF), // Blue
    ];
    
    for (int i = 0; i < endpoints.length; i++) {
      if (i < colorPalette.length) {
        _endpointColors[endpoints[i]] = colorPalette[i];
      } else {
        // Generate random color for additional endpoints
        _endpointColors[endpoints[i]] = Color.fromRGBO(
          random.nextInt(255),
          random.nextInt(255),
          random.nextInt(255),
          1.0,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (allHistory.isEmpty) return;

    // Find the maximum history length to normalize X axis
    final maxHistoryLength = allHistory.values
        .map((history) => history.length)
        .reduce((a, b) => a > b ? a : b);
    
    if (maxHistoryLength == 0) return;

    // Draw grid lines
    _drawGrid(canvas, size);

    // Draw each endpoint line
    allHistory.forEach((endpoint, history) {
      _drawEndpointLine(canvas, size, endpoint, history, maxHistoryLength);
    });
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = RetroTerminalTheme.amberDim.withOpacity(0.1)
      ..strokeWidth = 1;

    // Horizontal grid lines (response time levels)
    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical grid lines (time intervals)
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawEndpointLine(Canvas canvas, Size size, String endpoint, 
      List<PingResult> history, int maxHistoryLength) {
    
    if (history.isEmpty) return;
    
    final color = _endpointColors[endpoint] ?? RetroTerminalTheme.amberColor;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (maxHistoryLength - 1);

    for (int i = 0; i < history.length; i++) {
      final result = history[i];
      final x = i * stepX;
      
      // Calculate Y based on response time, scaled to critical threshold
      double normalizedY;
      if (result.status == PingStatus.timeout || result.responseTimeMs == null) {
        normalizedY = 0.0; // Bottom for timeout/error
      } else {
        // Normalize to 0-1, with criticalThreshold = bottom, 0ms = top
        // Clip values that exceed critical threshold at the top
        normalizedY = 1.0 - (result.responseTimeMs! / criticalThreshold).clamp(0.0, 1.0);
      }
      
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw glow effect first
    canvas.drawPath(path, glowPaint);
    // Draw main line
    canvas.drawPath(path, paint);

    // Draw points for recent data
    if (history.isNotEmpty) {
      final lastResult = history.last;
      final lastX = (history.length - 1) * stepX;
      double lastNormalizedY;
      if (lastResult.status == PingStatus.timeout || lastResult.responseTimeMs == null) {
        lastNormalizedY = 0.0;
      } else {
        lastNormalizedY = 1.0 - (lastResult.responseTimeMs! / criticalThreshold).clamp(0.0, 1.0);
      }
      final lastY = size.height - (lastNormalizedY * size.height);
      
      // Draw pulsing dot for current endpoint
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        dotPaint,
      );
      
      // Draw glow around dot
      final dotGlowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(lastX, lastY),
        8,
        dotGlowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Legend widget for the aggregated chart
class AggregatedChartLegend extends StatelessWidget {
  final Map<String, List<PingResult>> allHistory;
  final Map<String, PingResult?> latestResults;

  const AggregatedChartLegend({
    super.key,
    required this.allHistory,
    required this.latestResults,
  });

  @override
  Widget build(BuildContext context) {
    if (allHistory.isEmpty) return const SizedBox.shrink();

    // Generate same colors as chart
    final endpointColors = _generateEndpointColors();
    final endpoints = allHistory.keys.toList();
    
    // Calculate screen width for full-width cards
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENDPOINT LEGEND',
            style: RetroTerminalTheme.terminalHeader.copyWith(
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Full-width grid of endpoint cards (2x height)
          ...endpoints.map((endpoint) {
            final color = endpointColors[endpoint] ?? RetroTerminalTheme.amberColor;
            final latestResult = latestResults[endpoint];
            final history = allHistory[endpoint] ?? [];
            final status = _getStatusText(latestResult);
            final peakTime = _calculatePeak(history);
            final avgTime = _calculateAverage(history);
            
            return Container(
              width: double.infinity,
              height: 80, // 2x the original height
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Endpoint info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ENDPOINT',
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 9,
                            color: RetroTerminalTheme.amberDim,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          endpoint,
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Current status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CURRENT',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 9,
                          color: RetroTerminalTheme.amberDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Average time
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'AVG',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 9,
                          color: RetroTerminalTheme.amberDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${avgTime}ms',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: RetroTerminalTheme.amberColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Peak time
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PEAK',
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 9,
                          color: RetroTerminalTheme.amberDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getPeakDisplay(history),
                        style: RetroTerminalTheme.terminalText.copyWith(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: _getPeakColor(history),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, Color> _generateEndpointColors() {
    final random = Random(42); // Same seed as chart painter
    final endpoints = allHistory.keys.toList();
    final colors = <String, Color>{};
    
    final colorPalette = [
      RetroTerminalTheme.vitalsStable,
      RetroTerminalTheme.vitalsCaution,
      RetroTerminalTheme.vitalsCritical,
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Magenta  
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF8000), // Orange
      const Color(0xFF8000FF), // Purple
      const Color(0xFF0080FF), // Blue
    ];
    
    for (int i = 0; i < endpoints.length; i++) {
      if (i < colorPalette.length) {
        colors[endpoints[i]] = colorPalette[i];
      } else {
        colors[endpoints[i]] = Color.fromRGBO(
          random.nextInt(255),
          random.nextInt(255),
          random.nextInt(255),
          1.0,
        );
      }
    }
    
    return colors;
  }

  String _getStatusText(PingResult? result) {
    if (result == null) return 'INIT';
    if (result.responseTimeMs == null) return 'TIMEOUT';
    return '${result.responseTimeMs}ms';
  }
  
  int _calculateAverage(List<PingResult> history) {
    final valid = history.where((r) => r.responseTimeMs != null).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<int>(0, (a, b) => a + b.responseTimeMs!);
    return (sum / valid.length).round();
  }

  int? _calculatePeak(List<PingResult> history) {
    // Check if any timeout exists - that's the "worst" peak
    final hasTimeout = history.any((r) => r.responseTimeMs == null);
    if (hasTimeout) return null; // Timeout is OL/overload
    
    // Otherwise find highest valid ping
    final valid = history.where((r) => r.responseTimeMs != null).toList();
    if (valid.isEmpty) return null; // Empty history
    return valid.map((r) => r.responseTimeMs!).reduce((a, b) => a > b ? a : b);
  }

  String _getPeakDisplay(List<PingResult> history) {
    final peak = _calculatePeak(history);
    if (peak == null) return 'OL'; // Timeout = overload/flatline like a DMM
    return '${peak}ms';
  }

  Color _getPeakColor(List<PingResult> history) {
    final peak = _calculatePeak(history);
    if (peak == null) return RetroTerminalTheme.vitalsFlatline; // Timeout
    if (peak > 200) return RetroTerminalTheme.vitalsCritical;  // Assume >200ms is critical
    if (peak > 100) return RetroTerminalTheme.vitalsCaution;   // Assume >100ms is caution
    return RetroTerminalTheme.vitalsStable;
  }
}

// BlinkingCursor imported from retro_terminal_theme.dart