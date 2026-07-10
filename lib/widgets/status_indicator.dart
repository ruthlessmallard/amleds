import 'package:flutter/material.dart';
import '../models/ping_result.dart';
import '../theme/retro_terminal_theme.dart' hide PingStatus;

/// Vitals-style status indicator for ping results
class StatusIndicator extends StatelessWidget {
  final PingStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  Color get _color {
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

  IconData get _icon {
    switch (status) {
      case PingStatus.excellent:
        return Icons.check_circle;
      case PingStatus.fair:
        return Icons.warning;
      case PingStatus.poor:
        return Icons.error_outline;
      case PingStatus.timeout:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String get label {
    switch (status) {
      case PingStatus.excellent:
        return 'STABLE';
      case PingStatus.fair:
        return 'CAUTION';
      case PingStatus.poor:
        return 'CRITICAL';
      case PingStatus.timeout:
        return 'FLATLINE';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: _color,
            size: size,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RetroTerminalTheme.terminalText.copyWith(
              color: _color,
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple status dot with glow effect
class StatusDot extends StatelessWidget {
  final PingStatus status;
  final double size;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 12,
  });

  Color get _color {
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
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.6),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.2,
          ),
        ],
      ),
    );
  }
}

/// Animated pulse indicator for vitals monitoring
class VitalsPulseIndicator extends StatefulWidget {
  final PingStatus status;
  final double size;

  const VitalsPulseIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  State<VitalsPulseIndicator> createState() => _VitalsPulseIndicatorState();
}

class _VitalsPulseIndicatorState extends State<VitalsPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  Color get _color {
    switch (widget.status) {
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
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Only pulse for stable/caution status
    if (widget.status == PingStatus.excellent || widget.status == PingStatus.fair) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.6),
                blurRadius: widget.size * _pulseAnimation.value * 0.5,
                spreadRadius: widget.size * 0.2,
              ),
            ],
          ),
        );
      },
    );
  }
}