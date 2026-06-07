import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_theme.dart';
import '../screens/caro_game_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  final GameTheme currentTheme;
  final ValueChanged<GameTheme> onThemeChanged;

  const AuthGate({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        final userEmail = session?.user.email;

        if (session == null || userEmail == null) {
          return LoginScreen(currentTheme: currentTheme);
        }

        return CaroGameScreen(
          currentTheme: currentTheme,
          onThemeChanged: onThemeChanged,
          userEmail: userEmail,
          onLogout: auth.signOut,
          onChangePassword: (password) {
            return auth.updateUser(UserAttributes(password: password));
          },
        );
      },
    );
  }
}
