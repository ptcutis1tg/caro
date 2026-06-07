import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class ScoreCard extends StatelessWidget {
  final String player;
  final int score;
  final Color color;
  final bool isActive;
  final GameTheme theme;

  const ScoreCard({
    super.key,
    required this.player,
    required this.score,
    required this.color,
    required this.isActive,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.12)
            : theme.cardBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : theme.gridLineColor.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player,
            style: TextStyle(
              color: isActive ? color : theme.subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
