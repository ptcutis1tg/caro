import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_theme.dart';
import '../screens/caro_game_screen.dart';
import '../screens/login_screen.dart';
import '../services/audio_manager.dart';

class AuthGate extends StatefulWidget {
  final GameTheme currentTheme;
  final ValueChanged<GameTheme> onThemeChanged;

  const AuthGate({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _wasLoggedIn = auth.currentSession != null;

    _authSubscription = auth.onAuthStateChange.listen((data) {
      final isLoggedIn = data.session != null;
      if (isLoggedIn && !_wasLoggedIn) {
        AudioManager.instance.playStartup();
      }
      _wasLoggedIn = isLoggedIn;
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        final userEmail = session?.user.email;

        if (session == null || userEmail == null) {
          return LoginScreen(currentTheme: widget.currentTheme);
        }

        return CaroGameScreen(
          currentTheme: widget.currentTheme,
          onThemeChanged: widget.onThemeChanged,
          userEmail: userEmail,
          onLogout: () async {
            await AudioManager.instance.playShutdown();
            await Future.delayed(const Duration(milliseconds: 400));
            await auth.signOut();
          },
          onChangePassword: (password) {
            return auth.updateUser(UserAttributes(password: password));
          },
        );
      },
    );
  }
}
