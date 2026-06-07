import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/game_theme.dart';
import 'supabase_config.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const CaroGameApp());
}

class CaroGameApp extends StatefulWidget {
  const CaroGameApp({super.key});

  @override
  State<CaroGameApp> createState() => _CaroGameAppState();
}

class _CaroGameAppState extends State<CaroGameApp> {
  GameTheme _currentTheme = GameThemes.cyberpunk;

  void _onThemeChanged(GameTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _currentTheme.scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _currentTheme.xColor,
          brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
          primary: _currentTheme.xColor,
          secondary: _currentTheme.oColor,
          surface: _currentTheme.cardBg,
        ),
      ),
      home: AuthGate(
        currentTheme: _currentTheme,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
