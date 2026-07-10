import 'dart:async';
import 'package:flutter/material.dart';
import 'machine_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scrollAnimation;

  final String _disclaimerText = '''
AMLEDS v1.0.0 - AUTONOMOUS MACHINE LATENCY EVALUATION & DIAGNOSTIC SYSTEM
================================================================================

PHARMACEUTICAL-STYLE DISCLAIMER:

May cause drowsiness, disinterest, desire to disappear and hike the Appalachian 
Trail, and possible autonomous machine monitoring. 

Not for final diagnostics. Not liable for monetary decision making. 

Do not approach any live autonomous equipment. 

Maker not liable for harm, physical, mental, or monetary in nature. 

Do not operate heavy machinery while using this lightweight machinery. 

If ping times last longer than 4 hours, consult a network administrator. 

Results, patience, and device temperature may vary. 

Prolonged use in low-light environments may cause eye strain, existential dread, 
and spontaneous career reassessment.

================================================================================
INITIALIZING SYSTEM...
LOADING DIAGNOSTIC MODULES...
ESTABLISHING NETWORK PROTOCOLS...

[PRESS ANY KEY TO CONTINUE]
''';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _scrollAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.forward();

    // Auto-navigate after animation completes
    Timer(const Duration(seconds: 14), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MachineListScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome,
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: Stack(
          children: [
            // CRT scanline effect
            _buildScanlines(),
            
            // Screen glow effect
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.8,
                  colors: [
                    const Color(0xFFffb000).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Scrolling text
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _scrollAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment(0, _scrollAnimation.value * 2 - 1),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with blinking cursor
                            _buildHeader(),
                            const SizedBox(height: 24),
                            
                            // Disclaimer text
                            Text(
                              _disclaimerText,
                              style: const TextStyle(
                                color: Color(0xFFffb000),
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.6,
                                letterSpacing: 0.5,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Blinking cursor at end
                            _buildBlinkingCursor(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom prompt
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller.isCompleted ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFffb000).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '[ TAP SCREEN TO CONTINUE ]',
                      style: TextStyle(
                        color: Color(0xFFffb000),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 20,
          color: const Color(0xFFffb000),
        ),
        const SizedBox(width: 8),
        const Text(
          'AMLEDS TERMINAL v1.0',
          style: TextStyle(
            color: Color(0xFFffb000),
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBlinkingCursor() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 530),
      builder: (context, value, child) {
        return Opacity(
          opacity: value < 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 12,
            height: 20,
            color: const Color(0xFFffb000),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildScanlines() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: List.generate(
            (constraints.maxHeight / 4).ceil(),
            (index) => Container(
              height: 2,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }
}
