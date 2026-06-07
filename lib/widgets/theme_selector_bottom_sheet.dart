import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class ThemeSelectorBottomSheet extends StatelessWidget {
  final GameTheme currentTheme;
  final Set<String> unlockedThemeIds;
  final ValueChanged<GameTheme> onThemeChanged;
  final VoidCallback onOpenShop;

  const ThemeSelectorBottomSheet({
    super.key,
    required this.currentTheme,
    required this.unlockedThemeIds,
    required this.onThemeChanged,
    required this.onOpenShop,
  });

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: currentTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: currentTheme.xColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chọn giao diện',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textColor,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Cửa hàng'),
                onPressed: () {
                  Navigator.pop(context);
                  onOpenShop();
                },
              ),
              IconButton(
                icon: Icon(Icons.close, color: currentTheme.subTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: GameThemes.all.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final theme = GameThemes.all[index];
                final isSelected = theme.id == currentTheme.id;
                final isUnlocked = unlockedThemeIds.contains(theme.id);

                return InkWell(
                  onTap: isUnlocked
                      ? () {
                          onThemeChanged(theme);
                          Navigator.pop(context);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: isUnlocked ? 1 : 0.55,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.xColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.xColor
                              : currentTheme.subTextColor.withValues(
                                  alpha: 0.2,
                                ),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.gridLineColor,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: theme.xColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                theme.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.xColor
                                      : currentTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                          if (!isUnlocked)
                            Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: currentTheme.subTextColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text('${theme.price}'),
                              ],
                            )
                          else if (isSelected)
                            Icon(Icons.check_circle, color: theme.xColor)
                          else
                            Row(
                              children: [
                                _buildColorDot(theme.xColor),
                                const SizedBox(width: 4),
                                _buildColorDot(theme.oColor),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
