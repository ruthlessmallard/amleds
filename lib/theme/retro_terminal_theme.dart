import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Retro IBM Terminal Theme
/// Amber phosphor on dark grey background with medical vitals styling
class RetroTerminalTheme {
  // Core colors
  static const Color backgroundColor = Color(0xFF1a1a1a);
  static const Color surfaceColor = Color(0xFF252525);
  static const Color amberColor = Color(0xFFffb000);
  static const Color amberDim = Color(0xFFcc8c00);
  static const Color amberBright = Color(0xFFFFD700);
  
  // Vitals monitor colors
  static const Color vitalsStable = Color(0xFF00ff41);    // Green - stable
  static const Color vitalsCaution = Color(0xFFffff00);   // Yellow - caution
  static const Color vitalsCritical = Color(0xFFff3333);  // Red - critical
  static const Color vitalsFlatline = Color(0xFF666666);  // Grey - flatline/no data
  
  // Status colors mapped to vitals - use int codes: 0=excellent, 1=fair, 2=poor, 3=timeout
  static Color getVitalsColor(int statusCode) {
    switch (statusCode) {
      case 0:
        return vitalsStable;
      case 1:
        return vitalsCaution;
      case 2:
        return vitalsCritical;
      case 3:
        return vitalsFlatline;
      default:
        return vitalsFlatline;
    }
  }

  // Typography
  static const String fontFamily = 'monospace';
  
  static TextStyle get terminalText => const TextStyle(
    color: amberColor,
    fontFamily: fontFamily,
    fontSize: 14,
    letterSpacing: 0.5,
  );
  
  static TextStyle get terminalHeader => const TextStyle(
    color: amberColor,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );
  
  static TextStyle get terminalTitle => const TextStyle(
    color: amberColor,
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );
  
  static TextStyle get vitalsText => const TextStyle(
    color: vitalsStable,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  // Theme data
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    
    colorScheme: const ColorScheme.dark(
      primary: amberColor,
      secondary: amberDim,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: backgroundColor,
      onSecondary: backgroundColor,
      onSurface: amberColor,
      onBackground: amberColor,
    ),
    
    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: amberColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: terminalHeader.copyWith(fontSize: 18),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: amberDim, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // List tile theme
    listTileTheme: ListTileThemeData(
      tileColor: surfaceColor,
      textColor: amberColor,
      iconColor: amberColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: amberDim, width: 1),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: amberDim, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: amberDim, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: amberColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: vitalsCritical, width: 1),
      ),
      labelStyle: terminalText,
      hintStyle: terminalText.copyWith(color: amberDim),
      prefixIconColor: amberColor,
      suffixIconColor: amberColor,
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: amberColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: terminalHeader.copyWith(
          color: backgroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    
    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: amberColor,
        side: const BorderSide(color: amberColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: terminalText,
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amberColor,
        textStyle: terminalText,
      ),
    ),
    
    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: amberColor,
      foregroundColor: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    
    // Divider theme
    dividerTheme: const DividerThemeData(
      color: amberDim,
      thickness: 1,
      space: 32,
    ),
    
    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: amberColor, width: 2),
      ),
      titleTextStyle: terminalHeader,
      contentTextStyle: terminalText,
    ),
    
    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: terminalText,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: amberColor, width: 1),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Text theme
    textTheme: TextTheme(
      displayLarge: terminalTitle,
      displayMedium: terminalHeader,
      displaySmall: terminalHeader.copyWith(fontSize: 14),
      headlineLarge: terminalHeader,
      headlineMedium: terminalHeader.copyWith(fontSize: 14),
      headlineSmall: terminalText.copyWith(fontWeight: FontWeight.bold),
      titleLarge: terminalHeader,
      titleMedium: terminalText.copyWith(fontWeight: FontWeight.bold),
      titleSmall: terminalText,
      bodyLarge: terminalText,
      bodyMedium: terminalText,
      bodySmall: terminalText.copyWith(fontSize: 12),
      labelLarge: terminalText.copyWith(fontWeight: FontWeight.bold),
      labelMedium: terminalText.copyWith(fontSize: 12),
      labelSmall: terminalText.copyWith(fontSize: 10),
    ),
  );
}



/// CRT Scanline overlay widget
class CRTScanlines extends StatelessWidget {
  final Widget child;
  
  const CRTScanlines({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: List.generate(
                    (constraints.maxHeight / 4).ceil(),
                    (index) => Container(
                      height: 2,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Subtle screen glow
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 0.7,
                  colors: [
                    RetroTerminalTheme.amberColor.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Medical vitals style card
class VitalsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  
  const VitalsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroTerminalTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor ?? RetroTerminalTheme.amberDim,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? RetroTerminalTheme.amberDim).withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Terminal style header
class TerminalHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  
  const TerminalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: RetroTerminalTheme.amberColor, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: RetroTerminalTheme.terminalHeader.copyWith(
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: RetroTerminalTheme.terminalText.copyWith(
              color: RetroTerminalTheme.amberDim,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: RetroTerminalTheme.amberDim,
        ),
      ],
    );
  }
}

/// Blinking cursor widget
class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double width;
  final double height;
  
  const BlinkingCursor({
    super.key,
    this.color = RetroTerminalTheme.amberColor,
    this.width = 8,
    this.height = 16,
  });
  
  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value < 0.5 ? 1.0 : 0.0,
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
