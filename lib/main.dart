import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/retro_terminal_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for retro terminal look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: RetroTerminalTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const AmledsApp());
}

class AmledsApp extends StatelessWidget {
  const AmledsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMLEDS',
      debugShowCheckedModeBanner: false,
      theme: RetroTerminalTheme.theme,
      darkTheme: RetroTerminalTheme.theme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
