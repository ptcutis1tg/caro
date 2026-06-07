import 'package:flutter/material.dart';

class GameTheme {
  final String id;
  final String name;
  final bool isDark;
  final Color scaffoldBg;
  final Color boardBg;
  final Color cardBg;
  final Color barBg;
  final Color xColor;
  final Color xShadow;
  final Color oColor;
  final Color oShadow;
  final Color winColor;
  final Color winBgColor;
  final Color gridLineColor;
  final Color textColor;
  final Color subTextColor;
  final Color activeScoreBorder;
  final int price;

  const GameTheme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.scaffoldBg,
    required this.boardBg,
    required this.cardBg,
    required this.barBg,
    required this.xColor,
    required this.xShadow,
    required this.oColor,
    required this.oShadow,
    required this.winColor,
    required this.winBgColor,
    required this.gridLineColor,
    required this.textColor,
    required this.subTextColor,
    required this.activeScoreBorder,
    this.price = 0,
  });
}

class GameThemes {
  static const GameTheme cyberpunk = GameTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk Neon',
    isDark: true,
    scaffoldBg: Color(0xFF0F0F1A),
    boardBg: Color(0xFF161626),
    cardBg: Color(0xFF1E1E36),
    barBg: Color(0xFF121224),
    xColor: Colors.cyanAccent,
    xShadow: Colors.cyan,
    oColor: Colors.deepOrangeAccent,
    oShadow: Colors.deepOrange,
    winColor: Colors.amberAccent,
    winBgColor: Color(0x40FFD700),
    gridLineColor: Color(0xFF2E2E3E),
    textColor: Colors.white,
    subTextColor: Colors.grey,
    activeScoreBorder: Colors.cyanAccent,
  );

  static const GameTheme classicLight = GameTheme(
    id: 'classic_light',
    name: 'Classic Light',
    isDark: false,
    scaffoldBg: Color(0xFFF3F4F6),
    boardBg: Colors.white,
    cardBg: Color(0xFFE5E7EB),
    barBg: Colors.white,
    xColor: Color(0xFF1E40AF),
    xShadow: Color(0xFF3B82F6),
    oColor: Color(0xFFB91C1C),
    oShadow: Color(0xFFEF4444),
    winColor: Color(0xFF047857),
    winBgColor: Color(0x4010B981),
    gridLineColor: Color(0xFFE5E7EB),
    textColor: Color(0xFF1F2937),
    subTextColor: Color(0xFF4B5563),
    activeScoreBorder: Color(0xFF1E40AF),
    price: 5,
  );

  static const GameTheme forestEmerald = GameTheme(
    id: 'forest_emerald',
    name: 'Forest Emerald',
    isDark: true,
    scaffoldBg: Color(0xFF0D1D16),
    boardBg: Color(0xFF152E24),
    cardBg: Color(0xFF1C3A2E),
    barBg: Color(0xFF0A1611),
    xColor: Color(0xFF5EEAD4),
    xShadow: Color(0xFF14B8A6),
    oColor: Color(0xFFFDE047),
    oShadow: Color(0xFFEAB308),
    winColor: Color(0xFFF43F5E),
    winBgColor: Color(0x40F43F5E),
    gridLineColor: Color(0xFF224D3D),
    textColor: Color(0xFFECFDF5),
    subTextColor: Color(0xFF86EFAC),
    activeScoreBorder: Color(0xFF5EEAD4),
    price: 8,
  );

  static const GameTheme sweetCandy = GameTheme(
    id: 'sweet_candy',
    name: 'Sweet Candy',
    isDark: false,
    scaffoldBg: Color(0xFFFFF0F5),
    boardBg: Colors.white,
    cardBg: Color(0xFFFFDEEC),
    barBg: Color(0xFFFFF8FB),
    xColor: Color(0xFFDB2777),
    xShadow: Color(0xFFF472B6),
    oColor: Color(0xFF7C3AED),
    oShadow: Color(0xFFA78BFA),
    winColor: Color(0xFFD97706),
    winBgColor: Color(0x40F59E0B),
    gridLineColor: Color(0xFFFCE7F3),
    textColor: Color(0xFF4C0519),
    subTextColor: Color(0xFF9D174D),
    activeScoreBorder: Color(0xFFDB2777),
    price: 10,
  );

  static const List<GameTheme> all = [
    cyberpunk,
    classicLight,
    forestEmerald,
    sweetCandy,
  ];
}
