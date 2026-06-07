import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class CaroCell extends StatelessWidget {
  final String value;
  final bool isWinning;
  final GameTheme theme;
  final VoidCallback onTap;

  const CaroCell({
    super.key,
    required this.value,
    required this.isWinning,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Náº¿u Ã´ náº±m trong chuá»—i tháº¯ng, tÃ´ mÃ u ná»n tháº¯ng cuá»™c tá»« theme
    Color? cellColor = isWinning ? theme.winBgColor : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: theme.gridLineColor, width: 0.5),
        ),
        child: Center(
          child: AnimatedScale(
            scale: value.isEmpty
                ? 0.0
                : 1.0, // Hiá»‡u á»©ng phÃ³ng to mÆ°á»£t mÃ  khi ngÆ°á»i dÃ¹ng Ä‘Ã¡nh vÃ o Ã´
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isWinning
                    ? theme.winColor
                    : (value == 'X' ? theme.xColor : theme.oColor),
                shadows: [
                  if (value.isNotEmpty)
                    Shadow(
                      color: isWinning
                          ? theme.winColor
                          : (value == 'X' ? theme.xShadow : theme.oShadow),
                      blurRadius: isWinning ? 12 : 8,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
