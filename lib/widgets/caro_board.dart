import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/game_theme.dart';

class CaroBoard extends StatefulWidget {
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
  State<CaroBoard> createState() => _CaroBoardState();
}

class _CaroBoardState extends State<CaroBoard> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Map<Point<int>, DateTime> _placementTimes = {};
  static const _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (final point in widget.cells.keys) {
      _placementTimes[point] = now.subtract(_animationDuration);
    }

    _ticker = createTicker((elapsed) {
      final now = DateTime.now();
      bool anyAnimating = false;
      for (final time in _placementTimes.values) {
        if (now.difference(time) < _animationDuration) {
          anyAnimating = true;
          break;
        }
      }

      if (!anyAnimating) {
        _ticker.stop();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CaroBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final now = DateTime.now();
    bool addedAny = false;

    _placementTimes.removeWhere((key, _) => !widget.cells.containsKey(key));

    for (final entry in widget.cells.entries) {
      final point = entry.key;
      final value = entry.value;
      final oldValue = oldWidget.cells[point];

      if (oldValue != value) {
        _placementTimes[point] = now;
        addedAny = true;
      }
    }

    if (addedAny) {
      if (!_ticker.isTicking) {
        _ticker.start();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardExtent = widget.boardSize * widget.cellSize;
    final now = DateTime.now();
    final Map<Point<int>, double> scales = {};

    for (final entry in widget.cells.entries) {
      final point = entry.key;
      final time = _placementTimes[point];
      if (time == null) {
        scales[point] = 1.0;
      } else {
        final elapsed = now.difference(time);
        final progress = (elapsed.inMilliseconds / _animationDuration.inMilliseconds).clamp(0.0, 1.0);
        scales[point] = Curves.easeOutBack.transform(progress);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final col = details.localPosition.dx ~/ widget.cellSize;
        final row = details.localPosition.dy ~/ widget.cellSize;
        if (row >= 0 && row < widget.boardSize && col >= 0 && col < widget.boardSize) {
          widget.onCellTap(row, col);
        }
      },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(boardExtent),
          painter: _CaroBoardPainter(
            boardSize: widget.boardSize,
            cellSize: widget.cellSize,
            cells: widget.cells,
            winningCells: widget.winningCells,
            theme: widget.theme,
            scales: scales,
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
  final Map<Point<int>, double> scales;

  _CaroBoardPainter({
    required this.boardSize,
    required this.cellSize,
    required this.cells,
    required this.winningCells,
    required this.theme,
    required this.scales,
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

      final scale = scales[point] ?? 1.0;

      if (scale != 1.0) {
        canvas.save();
        final center = rect.center;
        canvas.translate(center.dx, center.dy);
        canvas.scale(scale);
        canvas.translate(-center.dx, -center.dy);
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

      if (scale != 1.0) {
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CaroBoardPainter oldDelegate) {
    return oldDelegate.boardSize != boardSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.cells != cells ||
        oldDelegate.winningCells != winningCells ||
        oldDelegate.theme != theme ||
        oldDelegate.scales != scales;
  }
}
