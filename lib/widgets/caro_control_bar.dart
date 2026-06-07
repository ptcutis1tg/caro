import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class CaroControlBar extends StatelessWidget {
  final GameTheme theme;
  final int boardSize;
  final int requiredLineLength;
  final VoidCallback onConfigure;
  final VoidCallback onNewGame;
  final VoidCallback onResetScore;

  const CaroControlBar({
    super.key,
    required this.theme,
    required this.boardSize,
    required this.requiredLineLength,
    required this.onConfigure,
    required this.onNewGame,
    required this.onResetScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.barBg.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: theme.gridLineColor.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardBg.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.gridLineColor.withValues(alpha: 0.55),
                ),
              ),
              child: Center(
                child: Text(
                  '${boardSize}x$boardSize | $requiredLineLength',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.tune, color: theme.subTextColor),
              tooltip: 'Cấu hình',
              onPressed: onConfigure,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.refresh, color: theme.xColor),
              tooltip: 'Ván mới',
              onPressed: onNewGame,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              color: Colors.redAccent.withValues(alpha: 0.9),
              tooltip: 'Reset tỉ số',
              onPressed: onResetScore,
            ),
          ],
        ),
      ),
    );
  }
}
