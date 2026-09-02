import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ping_result.dart';
import '../theme/retro_terminal_theme.dart';

/// Aggregated chart showing all endpoints together with overlapping lines
class AggregatedEndpointChart extends StatelessWidget {
  final Map<String, List<PingResult>> allHistory;
  final double height;

  const AggregatedEndpointChart({
    super.key,
    required this.allHistory,
    this.height = 120,
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
      child: CustomPaint(
        size: Size(double.infinity, height - 32),
        painter: _AggregatedChartPainter(allHistory),
      ),
    );
  }
}

class _AggregatedChartPainter extends CustomPainter {
  final Map<String, List<PingResult>> allHistory;
  final Map<String, Color> _endpointColors = {};

  _AggregatedChartPainter(this.allHistory) {
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
      
      // Calculate Y based on response time (inverted, lower ping = higher on screen)
      double normalizedY;
      if (result.status == PingStatus.timeout || result.responseTimeMs == null) {
        normalizedY = 0.0; // Bottom for timeout/error
      } else {
        // Normalize to 0-1, with 500ms = bottom, 0ms = top
        normalizedY = 1.0 - (result.responseTimeMs! / 500).clamp(0.0, 1.0);
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
        lastNormalizedY = 1.0 - (lastResult.responseTimeMs! / 500).clamp(0.0, 1.0);
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

    return Container(
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: endpoints.map((endpoint) {
              final color = endpointColors[endpoint] ?? RetroTerminalTheme.amberColor;
              final latestResult = latestResults[endpoint];
              final status = _getStatusText(latestResult);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          endpoint,
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          status,
                          style: RetroTerminalTheme.terminalText.copyWith(
                            fontSize: 8,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
}

/// Blinking cursor widget for loading states
class BlinkingCursor extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const BlinkingCursor({
    super.key,
    this.width = 10,
    this.height = 20,
    this.color = Colors.white,
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _animationController.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            color: widget.color,
          ),
        );
      },
    );
  }
}