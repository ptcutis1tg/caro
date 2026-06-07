import 'package:flutter/material.dart';

import '../models/game_theme.dart';
import 'score_card.dart';

class CaroHeader extends StatelessWidget {
  final GameTheme theme;
  final bool isDesktop;
  final String currentPlayer;
  final int scoreX;
  final int scoreO;
  final int wallet;
  final String userEmail;
  final Future<void> Function() onLogout;
  final VoidCallback onChangePassword;
  final VoidCallback onThemePressed;
  final VoidCallback onShopPressed;

  const CaroHeader({
    super.key,
    required this.theme,
    required this.isDesktop,
    required this.currentPlayer,
    required this.scoreX,
    required this.scoreO,
    required this.wallet,
    required this.userEmail,
    required this.onLogout,
    required this.onChangePassword,
    required this.onThemePressed,
    required this.onShopPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = currentPlayer == 'X' ? theme.xColor : theme.oColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.barBg.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: theme.gridLineColor.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ScoreCard(
            player: 'X',
            score: scoreX,
            color: theme.xColor,
            isActive: currentPlayer == 'X',
            theme: theme,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 18 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: activeColor),
                ),
                child: Text(
                  'Lượt $currentPlayer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ScoreCard(
            player: 'O',
            score: scoreO,
            color: theme.oColor,
            isActive: currentPlayer == 'O',
            theme: theme,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardBg.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.gridLineColor.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.toll, color: theme.winColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$wallet',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.storefront, color: theme.subTextColor),
            tooltip: 'Cửa hàng',
            onPressed: onShopPressed,
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: theme.subTextColor),
            tooltip: 'Đổi giao diện',
            onPressed: onThemePressed,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 220 : 120),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardBg.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.gridLineColor.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    color: theme.subTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: isDesktop ? 13 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.password, color: theme.subTextColor),
            tooltip: 'Doi mat khau',
            onPressed: onChangePassword,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.subTextColor),
            tooltip: 'Dang xuat',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
