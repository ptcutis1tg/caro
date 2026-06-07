import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/models/game_theme.dart';
import 'package:my_app/screens/caro_game_screen.dart';

void main() {
  testWidgets('Caro game setup smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaroGameScreen(
          currentTheme: GameThemes.cyberpunk,
          onThemeChanged: (_) {},
          userEmail: 'player@example.com',
          onLogout: () async {},
          onChangePassword: (_) async {},
        ),
      ),
    );

    expect(find.text('Cấu hình ván chơi'), findsOneWidget);
    expect(find.text('Đấu với người'), findsOneWidget);
    expect(find.text('Đấu với máy'), findsOneWidget);
    expect(find.text('20x20'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
  });
}
