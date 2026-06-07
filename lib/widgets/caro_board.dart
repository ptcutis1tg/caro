import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_theme.dart';

class CaroBoard extends StatelessWidget {
  final int boardSize;
  final double cellSize;
  final Map<Point<int>, String> cells;
  final Set<Point<int>> winningCells;
  final GameTheme theme;
  final void Function(int row, int col) onCellTap;

  const CaroBoard({
    super.key,
    required this.boardSize,
    required this.cellSize,
    required this.cells,
    required this.winningCells,
    required this.theme,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final boardExtent = boardSize * cellSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final col = details.localPosition.dx ~/ cellSize;
        final row = details.localPosition.dy ~/ cellSize;
        if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
          onCellTap(row, col);
        }
      },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(boardExtent),
          painter: _CaroBoardPainter(
            boardSize: boardSize,
            cellSize: cellSize,
            cells: cells,
            winningCells: winningCells,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

class _CaroBoardPainter extends CustomPainter {
  final int boardSize;
  final double cellSize;
  final Map<Point<int>, String> cells;
  final Set<Point<int>> winningCells;
  final GameTheme theme;

  _CaroBoardPainter({
    required this.boardSize,
    required this.cellSize,
    required this.cells,
    required this.winningCells,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = Offset.zero & size;
    final paintRect = canvas
        .getLocalClipBounds()
        .inflate(cellSize * 2)
        .intersect(boardRect);

    final backgroundPaint = Paint()..color = theme.boardBg;
    canvas.drawRect(paintRect, backgroundPaint);

    _paintGrid(canvas, paintRect);
    _paintWinningCells(canvas, paintRect);
    _paintPieces(canvas, paintRect);
  }

  void _paintGrid(Canvas canvas, Rect paintRect) {
    final linePaint = Paint()
      ..color = theme.gridLineColor
      ..strokeWidth = 0.5;

    final firstCol = max(0, paintRect.left ~/ cellSize);
    final lastCol = min(boardSize, (paintRect.right / cellSize).ceil());
    final firstRow = max(0, paintRect.top ~/ cellSize);
    final lastRow = min(boardSize, (paintRect.bottom / cellSize).ceil());

    for (int col = firstCol; col <= lastCol; col++) {
      final x = col * cellSize;
      canvas.drawLine(
        Offset(x, firstRow * cellSize),
        Offset(x, lastRow * cellSize),
        linePaint,
      );
    }

    for (int row = firstRow; row <= lastRow; row++) {
      final y = row * cellSize;
      canvas.drawLine(
        Offset(firstCol * cellSize, y),
        Offset(lastCol * cellSize, y),
        linePaint,
      );
    }
  }

  void _paintWinningCells(Canvas canvas, Rect paintRect) {
    if (winningCells.isEmpty) {
      return;
    }

    final winPaint = Paint()..color = theme.winBgColor;
    for (final point in winningCells) {
      final rect = Rect.fromLTWH(
        point.y * cellSize,
        point.x * cellSize,
        cellSize,
        cellSize,
      );
      if (paintRect.overlaps(rect)) {
        canvas.drawRect(rect, winPaint);
      }
    }
  }

  void _paintPieces(Canvas canvas, Rect paintRect) {
    for (final entry in cells.entries) {
      final point = entry.key;
      final rect = Rect.fromLTWH(
        point.y * cellSize,
        point.x * cellSize,
        cellSize,
        cellSize,
      );
      if (!paintRect.overlaps(rect)) {
        continue;
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontSize: cellSize * 0.55,
            fontWeight: FontWeight.bold,
            color: winningCells.contains(point)
                ? theme.winColor
                : (entry.value == 'X' ? theme.xColor : theme.oColor),
            shadows: [
              Shadow(
                color: winningCells.contains(point)
                    ? theme.winColor
                    : (entry.value == 'X' ? theme.xShadow : theme.oShadow),
                blurRadius: winningCells.contains(point) ? 12 : 8,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          rect.left + (cellSize - textPainter.width) / 2,
          rect.top + (cellSize - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CaroBoardPainter oldDelegate) {
    return oldDelegate.boardSize != boardSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.cells != cells ||
        oldDelegate.winningCells != winningCells ||
        oldDelegate.theme != theme;
  }
}
