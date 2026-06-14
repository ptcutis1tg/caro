import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_theme.dart';
import '../widgets/caro_board.dart';
import '../widgets/caro_control_bar.dart';
import '../widgets/caro_header.dart';
import '../widgets/theme_selector_bottom_sheet.dart';
import '../services/audio_manager.dart';

enum GameMode { playerVsPlayer, playerVsMachine }

enum MachineDifficulty { easy, medium, hard }

class CaroGameScreen extends StatefulWidget {
  final GameTheme currentTheme;
  final ValueChanged<GameTheme> onThemeChanged;
  final String userEmail;
  final Future<void> Function() onLogout;
  final Future<void> Function(String password) onChangePassword;

  const CaroGameScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.userEmail,
    required this.onLogout,
    required this.onChangePassword,
  });

  @override
  State<CaroGameScreen> createState() => _CaroGameScreenState();
}

class _CaroGameScreenState extends State<CaroGameScreen> {
  static const int _baseReviveCost = 1;

  int _boardSize = 20;
  int _pendingBoardSize = 20;
  double _sliderMax = 30;
  final double _cellSize = 40.0;
  final Random _random = Random();

  Map<Point<int>, String> _board = {};

  GameMode _gameMode = GameMode.playerVsPlayer;
  MachineDifficulty _difficulty = MachineDifficulty.easy;
  bool _isConfigured = false;
  bool _isMachineThinking = false;
  String _currentPlayer = 'X';
  String? _winner;
  Set<Point<int>> _winningCells = {};
  Point<int>? _lastMachineMove;
  int _reviveCountThisRound = 0;

  int _scoreX = 0;
  int _scoreO = 0;
  int _wallet = 0;
  final Set<String> _unlockedThemeIds = {GameThemes.cyberpunk.id};

  final TransformationController _transformationController =
      TransformationController();

  int get _requiredLineLength => _lineLengthForSize(_boardSize);

  int get _winReward {
    if (_gameMode == GameMode.playerVsPlayer) {
      return 1;
    }
    return switch (_difficulty) {
      MachineDifficulty.easy => 1,
      MachineDifficulty.medium => 2,
      MachineDifficulty.hard => 3,
    };
  }

  int get _nextReviveCost =>
      _baseReviveCost * pow(2, _reviveCountThisRound).toInt();

  bool get _isMachineTurn =>
      _gameMode == GameMode.playerVsMachine &&
      _currentPlayer == 'O' &&
      _winner == null;

  String _cellAt(int r, int c) => _board[Point(r, c)] ?? '';

  bool _isCellEmpty(int r, int c) => !_board.containsKey(Point(r, c));

  void _setCell(int r, int c, String value) {
    final point = Point(r, c);
    if (value.isEmpty) {
      _board.remove(point);
    } else {
      _board[point] = value;
    }
  }

  void _commitBoardSnapshot() {
    _board = Map<Point<int>, String>.of(_board);
  }

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  @override
  void dispose() {
    AudioManager.instance.stopPvPBgm();
    _transformationController.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    _board = {};
    _currentPlayer = 'X';
    _winner = null;
    _winningCells = {};
    _lastMachineMove = null;
    _reviveCountThisRound = 0;
    _isMachineThinking = false;
    _transformationController.value = Matrix4.identity();
  }

  void _startConfiguredGame() {
    setState(() {
      _boardSize = _pendingBoardSize;
      _scoreX = 0;
      _scoreO = 0;
      _isConfigured = true;
      _initializeBoard();
    });

    if (_gameMode == GameMode.playerVsPlayer) {
      AudioManager.instance.startPvPBgm();
    } else {
      AudioManager.instance.stopPvPBgm();
    }
  }

  void _openSetup() {
    setState(() {
      _pendingBoardSize = _boardSize;
      if (_sliderMax < _pendingBoardSize) {
        _sliderMax = _pendingBoardSize.toDouble();
      }
      _isConfigured = false;
    });
    AudioManager.instance.stopPvPBgm();
  }

  void _returnToSetupAfterLoss() {
    setState(() {
      _isConfigured = false;
      _pendingBoardSize = _boardSize;
      _initializeBoard();
    });
    AudioManager.instance.stopPvPBgm();
  }

  void _resetScores() {
    setState(() {
      _scoreX = 0;
      _scoreO = 0;
      _initializeBoard();
    });
  }

  void _makeMove(int r, int c) {
    if (_winner != null ||
        !_isCellEmpty(r, c) ||
        _isMachineThinking ||
        _isMachineTurn) {
      return;
    }

    final shouldQueueMachine = _placeSymbol(r, c);
    if (shouldQueueMachine) {
      _queueMachineMove();
    }
  }

  bool _placeSymbol(int r, int c) {
    var shouldQueueMachine = false;
    String? roundWinner;

    setState(() {
      _setCell(r, c, _currentPlayer);
      AudioManager.instance.playMove();
      if (_currentPlayer == 'O') {
        _lastMachineMove = Point(r, c);
      }

      if (_checkWin(r, c)) {
        _winner = _currentPlayer;
        roundWinner = _winner;
        if (_currentPlayer == 'X') {
          _scoreX++;
          _wallet += _winReward;
          if (_gameMode == GameMode.playerVsMachine) {
            AudioManager.instance.playWin();
          }
        } else {
          _scoreO++;
          if (_gameMode == GameMode.playerVsPlayer) {
            _wallet += _winReward;
          } else if (_gameMode == GameMode.playerVsMachine) {
            AudioManager.instance.playLose();
          }
        }
      } else if (_checkDraw()) {
        _winner = 'Draw';
        roundWinner = _winner;
      } else {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        shouldQueueMachine = _isMachineTurn;
      }
      _commitBoardSnapshot();
    });

    if (roundWinner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (roundWinner == 'O' && _gameMode == GameMode.playerVsMachine) {
          _showReviveDialog();
        } else {
          _showWinnerDialog();
        }
      });
    }

    return shouldQueueMachine;
  }

  void _queueMachineMove() {
    setState(() {
      _isMachineThinking = true;
    });

    Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_isMachineTurn || _winner != null) {
        return;
      }

      final move = _findMachineMove();
      if (move == null) {
        setState(() {
          _isMachineThinking = false;
        });
        return;
      }

      setState(() {
        _isMachineThinking = false;
      });
      _placeSymbol(move.x, move.y);
    });
  }

  Point<int>? _findMachineMove() {
    return switch (_difficulty) {
      MachineDifficulty.easy => _findEasyMove(),
      MachineDifficulty.medium =>
        _findWinningMove('O') ??
            _findWinningMove('X') ??
            _findBestScoredMove(attackWeight: 1.0, defenseWeight: 1.15) ??
            _findFirstEmptyCell(),
      MachineDifficulty.hard =>
        _findWinningMove('O') ??
            _findWinningMove('X') ??
            _findBestScoredMove(attackWeight: 1.25, defenseWeight: 1.35) ??
            _findFirstEmptyCell(),
    };
  }

  Point<int>? _findEasyMove() {
    if (_checkDraw()) {
      return null;
    }

    for (var i = 0; i < 64; i++) {
      final point = Point(
        _random.nextInt(_boardSize),
        _random.nextInt(_boardSize),
      );
      if (_isCellEmpty(point.x, point.y)) {
        return point;
      }
    }

    return _findFirstEmptyCell();
  }

  Point<int>? _findWinningMove(String symbol) {
    for (final point in _candidateMoves()) {
      if (_wouldWin(point.x, point.y, symbol)) {
        return point;
      }
    }
    return null;
  }

  Point<int>? _findBestScoredMove({
    required double attackWeight,
    required double defenseWeight,
  }) {
    var bestScore = -1;
    Point<int>? bestMove;

    for (final point in _candidateMoves()) {
      final attackScore = _moveScore(point.x, point.y, 'O');
      final defenseScore = _moveScore(point.x, point.y, 'X');
      final centerScore = _centerPreference(point);
      final score =
          (attackScore * attackWeight + defenseScore * defenseWeight).round() +
          centerScore;

      if (score > bestScore) {
        bestScore = score;
        bestMove = point;
      }
    }

    return bestMove;
  }

  int _moveScore(int r, int c, String symbol) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    var total = 0;
    var strongThreats = 0;

    for (final dir in directions) {
      final lineScore = _directionScore(r, c, dir[0], dir[1], symbol);
      total += lineScore.score;
      strongThreats += lineScore.strongThreats;
    }

    if (strongThreats >= 2) {
      total += 85000;
    }

    return total;
  }

  _LineScore _directionScore(int r, int c, int dr, int dc, String symbol) {
    final opponent = symbol == 'X' ? 'O' : 'X';
    final winLength = _requiredLineLength;
    var score = 0;
    var strongThreats = 0;

    for (var offset = -winLength + 1; offset <= 0; offset++) {
      var ownCount = 0;
      var emptyCount = 0;
      var blocked = false;

      for (var i = 0; i < winLength; i++) {
        final nr = r + (offset + i) * dr;
        final nc = c + (offset + i) * dc;
        if (!_isInside(nr, nc)) {
          blocked = true;
          break;
        }

        final value = nr == r && nc == c ? symbol : _cellAt(nr, nc);
        if (value == opponent) {
          blocked = true;
          break;
        }
        if (value == symbol) {
          ownCount++;
        } else {
          emptyCount++;
        }
      }

      if (blocked) {
        continue;
      }

      final beforeR = r + (offset - 1) * dr;
      final beforeC = c + (offset - 1) * dc;
      final afterR = r + (offset + winLength) * dr;
      final afterC = c + (offset + winLength) * dc;
      final openEnds =
          (_isOpenEnd(beforeR, beforeC) ? 1 : 0) +
          (_isOpenEnd(afterR, afterC) ? 1 : 0);
      final windowScore = _windowScore(
        ownCount: ownCount,
        emptyCount: emptyCount,
        openEnds: openEnds,
      );

      score += windowScore;
      if (ownCount >= winLength - 1 && emptyCount <= 1 && openEnds > 0) {
        strongThreats++;
      }
    }

    final contiguous =
        1 +
        _countDirection(r, c, dr, dc, symbol) +
        _countDirection(r, c, -dr, -dc, symbol);
    final leftOpen = _isOpenAfterRun(r, c, -dr, -dc, symbol) ? 1 : 0;
    final rightOpen = _isOpenAfterRun(r, c, dr, dc, symbol) ? 1 : 0;
    score += _contiguousScore(contiguous, leftOpen + rightOpen);

    return _LineScore(score, strongThreats);
  }

  int _windowScore({
    required int ownCount,
    required int emptyCount,
    required int openEnds,
  }) {
    final winLength = _requiredLineLength;
    if (ownCount >= winLength) {
      return 1000000;
    }
    if (ownCount == winLength - 1 && emptyCount == 1) {
      return openEnds == 2 ? 140000 : 70000;
    }
    if (ownCount == winLength - 2 && emptyCount == 2) {
      return openEnds == 2 ? 22000 : 9000;
    }
    if (ownCount == winLength - 3 && emptyCount == 3) {
      return openEnds == 2 ? 3500 : 1200;
    }
    return max(1, ownCount * ownCount * (openEnds + 1));
  }

  int _contiguousScore(int count, int openEnds) {
    final winLength = _requiredLineLength;
    if (count >= winLength) {
      return 1000000;
    }
    if (count == winLength - 1) {
      return openEnds == 2 ? 180000 : 80000;
    }
    if (count == winLength - 2) {
      return openEnds == 2 ? 28000 : 10000;
    }
    if (count == winLength - 3) {
      return openEnds == 2 ? 4500 : 1400;
    }
    return count * count * (openEnds + 1);
  }

  bool _isOpenEnd(int r, int c) {
    return _isInside(r, c) && _cellAt(r, c).isEmpty;
  }

  bool _isOpenAfterRun(int r, int c, int dr, int dc, String symbol) {
    var step = 1;
    while (true) {
      final nr = r + dr * step;
      final nc = c + dc * step;
      if (!_isInside(nr, nc)) {
        return false;
      }
      if (_cellAt(nr, nc) != symbol) {
        return _cellAt(nr, nc).isEmpty;
      }
      step++;
    }
  }

  int _countDirection(int r, int c, int dr, int dc, String symbol) {
    var count = 0;
    var step = 1;
    while (true) {
      final nr = r + dr * step;
      final nc = c + dc * step;
      if (!_isInside(nr, nc) || _cellAt(nr, nc) != symbol) {
        break;
      }
      count++;
      step++;
    }
    return count;
  }

  int _centerPreference(Point<int> point) {
    final center = _boardSize ~/ 2;
    final distance = (point.x - center).abs() + (point.y - center).abs();
    return max(0, _boardSize - distance);
  }

  Point<int>? _findFirstEmptyCell() {
    final center = _boardSize ~/ 2;
    if (_isCellEmpty(center, center)) {
      return Point(center, center);
    }

    for (int r = 0; r < _boardSize; r++) {
      for (int c = 0; c < _boardSize; c++) {
        if (_isCellEmpty(r, c)) {
          return Point(r, c);
        }
      }
    }
    return null;
  }

  Set<Point<int>> _candidateMoves() {
    if (_board.isEmpty) {
      final center = _boardSize ~/ 2;
      return {Point(center, center)};
    }

    final candidates = <Point<int>>{};
    final radius = _difficulty == MachineDifficulty.hard ? 2 : 1;
    for (final point in _board.keys) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr == 0 && dc == 0) {
            continue;
          }

          final r = point.x + dr;
          final c = point.y + dc;
          if (_isInside(r, c) && _isCellEmpty(r, c)) {
            candidates.add(Point(r, c));
          }
        }
      }
    }
    return candidates;
  }

  bool _wouldWin(int r, int c, String symbol) {
    _setCell(r, c, symbol);
    final result = _hasWinningLine(r, c, symbol, updateWinningCells: false);
    _setCell(r, c, '');
    return result;
  }

  bool _checkWin(int r, int c) {
    final symbol = _cellAt(r, c);
    if (symbol.isEmpty) {
      return false;
    }
    return _hasWinningLine(r, c, symbol);
  }

  bool _hasWinningLine(
    int r,
    int c,
    String symbol, {
    bool updateWinningCells = true,
  }) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (final dir in directions) {
      final line = <Point<int>>[Point(r, c)];
      _collectLine(line, r, c, dir[0], dir[1], symbol);
      _collectLine(line, r, c, -dir[0], -dir[1], symbol);

      if (line.length >= _requiredLineLength) {
        if (updateWinningCells) {
          _winningCells = line.toSet();
        }
        return true;
      }
    }

    return false;
  }

  void _collectLine(
    List<Point<int>> line,
    int r,
    int c,
    int dr,
    int dc,
    String symbol,
  ) {
    var step = 1;
    while (true) {
      final nr = r + dr * step;
      final nc = c + dc * step;
      if (!_isInside(nr, nc) || _cellAt(nr, nc) != symbol) {
        break;
      }
      line.add(Point(nr, nc));
      step++;
    }
  }

  bool _isInside(int r, int c) {
    return r >= 0 && r < _boardSize && c >= 0 && c < _boardSize;
  }

  bool _checkDraw() {
    return _board.length >= _boardSize * _boardSize;
  }

  void _revive() {
    final cost = _nextReviveCost;
    final lastMove = _lastMachineMove;
    if (lastMove == null || _wallet < cost) {
      return;
    }

    setState(() {
      _wallet -= cost;
      _reviveCountThisRound++;
      _scoreO = max(0, _scoreO - 1);
      _setCell(lastMove.x, lastMove.y, '');
      _lastMachineMove = null;
      _winner = null;
      _winningCells = {};
      _currentPlayer = 'X';
      _commitBoardSnapshot();
    });
  }

  Future<void> _showReviveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReviveDialog(
        theme: widget.currentTheme,
        wallet: _wallet,
        cost: _nextReviveCost,
        onTopUp: () {
          Navigator.of(context).pop();
          _showShopBottomSheet();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true && _wallet >= _nextReviveCost) {
      _revive();
    } else if (result == false) {
      _returnToSetupAfterLoss();
    }
  }

  void _showWinnerDialog() {
    final theme = widget.currentTheme;
    final btnTextColor =
        ThemeData.estimateBrightnessForColor(theme.xColor) == Brightness.light
        ? Colors.black
        : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _winner == 'Draw'
                  ? theme.subTextColor
                  : (_winner == 'X' ? theme.xColor : theme.oColor),
              width: 2,
            ),
          ),
          title: Center(
            child: Text(
              _winner == 'Draw' ? 'Hòa!' : 'Chiến thắng!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_winner == 'X') ...[
                Text(
                  'Bạn nhận được $_winReward đơn vị',
                  style: TextStyle(color: theme.subTextColor, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Icon(Icons.toll, size: 48, color: theme.winColor),
              ] else if (_winner == 'Draw') ...[
                Icon(
                  Icons.sentiment_neutral,
                  size: 64,
                  color: theme.subTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không còn ô trống.',
                  style: TextStyle(color: theme.subTextColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'Người chơi O thắng',
                  style: TextStyle(color: theme.subTextColor, fontSize: 16),
                ),
              ],
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.replay, color: btnTextColor),
                label: Text(
                  'Ván mới',
                  style: TextStyle(
                    color: btnTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.xColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(_initializeBoard);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 600;
    final theme = widget.currentTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: _isConfigured
            ? _buildGame(theme, isDesktop)
            : _buildSetup(theme, isDesktop),
      ),
    );
  }

  Widget _buildSetup(GameTheme theme, bool isDesktop) {
    final pendingWinLength = _lineLengthForSize(_pendingBoardSize);

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.gridLineColor.withValues(alpha: 0.8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cấu hình ván chơi',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: isDesktop ? 24 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _WalletBadge(theme: theme, wallet: _wallet),
                        IconButton(
                          icon: Icon(
                            Icons.storefront,
                            color: theme.subTextColor,
                          ),
                          tooltip: 'Cửa hàng',
                          onPressed: _showShopBottomSheet,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: theme.subTextColor,
                          ),
                          tooltip: 'Đổi giao diện',
                          onPressed: _showThemeBottomSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<GameMode>(
                      segments: const [
                        ButtonSegment(
                          value: GameMode.playerVsPlayer,
                          icon: Icon(Icons.people_alt_outlined),
                          label: Text('Đấu với người'),
                        ),
                        ButtonSegment(
                          value: GameMode.playerVsMachine,
                          icon: Icon(Icons.smart_toy_outlined),
                          label: Text('Đấu với máy'),
                        ),
                      ],
                      selected: {_gameMode},
                      onSelectionChanged: (value) {
                        setState(() {
                          _gameMode = value.first;
                        });
                      },
                    ),
                    if (_gameMode == GameMode.playerVsMachine) ...[
                      const SizedBox(height: 16),
                      SegmentedButton<MachineDifficulty>(
                        segments: const [
                          ButtonSegment(
                            value: MachineDifficulty.easy,
                            label: Text('Dễ'),
                          ),
                          ButtonSegment(
                            value: MachineDifficulty.medium,
                            label: Text('Vừa'),
                          ),
                          ButtonSegment(
                            value: MachineDifficulty.hard,
                            label: Text('Khó'),
                          ),
                        ],
                        selected: {_difficulty},
                        onSelectionChanged: (value) {
                          setState(() {
                            _difficulty = value.first;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thắng máy nhận $_winReward đơn vị',
                        style: TextStyle(color: theme.subTextColor),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kích cỡ bàn',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${_pendingBoardSize}x$_pendingBoardSize',
                          style: TextStyle(
                            color: theme.xColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 3,
                      max: _sliderMax,
                      divisions: (_sliderMax - 3).round(),
                      value: _pendingBoardSize.toDouble().clamp(3, _sliderMax),
                      label: '${_pendingBoardSize}x$_pendingBoardSize',
                      onChanged: (value) {
                        setState(() {
                          _pendingBoardSize = value.round().clamp(3, 1000000);
                          if (_pendingBoardSize >= _sliderMax - 1) {
                            _sliderMax += 20;
                          }
                        });
                      },
                    ),
                    Text(
                      'Cần $pendingWinLength quân thẳng hàng để thắng',
                      style: TextStyle(color: theme.subTextColor),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.xColor,
                        foregroundColor:
                            ThemeData.estimateBrightnessForColor(
                                  theme.xColor,
                                ) ==
                                Brightness.light
                            ? Colors.black
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _startConfiguredGame,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(GameTheme theme, bool isDesktop) {
    return Column(
      children: [
        CaroHeader(
          theme: theme,
          isDesktop: isDesktop,
          currentPlayer: _isMachineThinking ? 'Máy' : _currentPlayer,
          scoreX: _scoreX,
          scoreO: _scoreO,
          wallet: _wallet,
          userEmail: widget.userEmail,
          onLogout: _confirmLogout,
          onChangePassword: _showChangePasswordDialog,
          onThemePressed: _showThemeBottomSheet,
          onShopPressed: _showShopBottomSheet,
        ),
        Expanded(
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(200),
              minScale: 0.4,
              maxScale: 2.5,
              child: Center(
                child: Container(
                  width: _boardSize * _cellSize,
                  height: _boardSize * _cellSize,
                  decoration: BoxDecoration(
                    color: theme.boardBg,
                    border: Border.all(
                      color: theme.xColor.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CaroBoard(
                      boardSize: _boardSize,
                      cellSize: _cellSize,
                      cells: _board,
                      winningCells: _winningCells,
                      theme: theme,
                      onCellTap: _makeMove,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        CaroControlBar(
          theme: theme,
          boardSize: _boardSize,
          requiredLineLength: _requiredLineLength,
          onConfigure: _openSetup,
          onNewGame: () {
            setState(_initializeBoard);
          },
          onResetScore: _resetScores,
        ),
      ],
    );
  }

  int _lineLengthForSize(int size) {
    if (size == 3) {
      return 3;
    }
    if (size <= 5) {
      return 4;
    }
    return 5;
  }

  void _buyTheme(GameTheme theme) {
    if (_unlockedThemeIds.contains(theme.id) || _wallet < theme.price) {
      return;
    }
    setState(() {
      _wallet -= theme.price;
      _unlockedThemeIds.add(theme.id);
    });
  }

  void _topUp(int units) {
    setState(() {
      _wallet += units;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.currentTheme.cardBg,
          title: Text(
            'Dang xuat?',
            style: TextStyle(
              color: widget.currentTheme.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Ban co chac muon dang xuat khong?',
            style: TextStyle(color: widget.currentTheme.subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Dang xuat'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await widget.onLogout();
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isLoading = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
              });

              try {
                await widget.onChangePassword(passwordController.text);
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Da doi mat khau.')),
                );
              } catch (_) {
                if (!dialogContext.mounted) {
                  return;
                }
                setDialogState(() {
                  errorMessage = 'Khong the doi mat khau. Vui long thu lai.';
                });
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: widget.currentTheme.cardBg,
              title: Text(
                'Doi mat khau',
                style: TextStyle(
                  color: widget.currentTheme.textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      enabled: !isLoading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mat khau moi',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 6) {
                          return 'Mat khau toi thieu 6 ky tu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      enabled: !isLoading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nhap lai mat khau',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Mat khau nhap lai khong khop';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => submit(),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Huy'),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Luu'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
  }

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.currentTheme.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ThemeSelectorBottomSheet(
          currentTheme: widget.currentTheme,
          unlockedThemeIds: _unlockedThemeIds,
          onThemeChanged: widget.onThemeChanged,
          onOpenShop: _showShopBottomSheet,
        );
      },
    );
  }

  void _showShopBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.currentTheme.scaffoldBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _ShopSheet(
              theme: widget.currentTheme,
              wallet: _wallet,
              unlockedThemeIds: _unlockedThemeIds,
              onBuyTheme: (theme) {
                _buyTheme(theme);
                setSheetState(() {});
              },
              onTopUp: (units) {
                _topUp(units);
                setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }
}

class _WalletBadge extends StatelessWidget {
  final GameTheme theme;
  final int wallet;

  const _WalletBadge({required this.theme, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.barBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.gridLineColor.withValues(alpha: 0.55)),
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
    );
  }
}

class _LineScore {
  final int score;
  final int strongThreats;

  const _LineScore(this.score, this.strongThreats);
}

class _ShopSheet extends StatelessWidget {
  final GameTheme theme;
  final int wallet;
  final Set<String> unlockedThemeIds;
  final ValueChanged<GameTheme> onBuyTheme;
  final ValueChanged<int> onTopUp;

  const _ShopSheet({
    required this.theme,
    required this.wallet,
    required this.unlockedThemeIds,
    required this.onBuyTheme,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cửa hàng',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _WalletBadge(theme: theme, wallet: wallet),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.subTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Mua đơn vị',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TopUpButton(
                    theme: theme,
                    units: 5,
                    price: r'$0.99',
                    onTap: onTopUp,
                  ),
                  _TopUpButton(
                    theme: theme,
                    units: 15,
                    price: r'$1.99',
                    onTap: onTopUp,
                  ),
                  _TopUpButton(
                    theme: theme,
                    units: 40,
                    price: r'$4.99',
                    onTap: onTopUp,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bản hiện tại chỉ cộng đơn vị mô phỏng. Thanh toán thật cần tích hợp store/payment SDK.',
                style: TextStyle(color: theme.subTextColor, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Text(
                'Theme',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...GameThemes.all.map((item) {
                final isUnlocked = unlockedThemeIds.contains(item.id);
                final canBuy = wallet >= item.price;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.barBg.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.gridLineColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.scaffoldBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: item.gridLineColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isUnlocked)
                        Text(
                          'Đã sở hữu',
                          style: TextStyle(color: theme.subTextColor),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.toll, size: 18),
                          label: Text('${item.price}'),
                          onPressed: canBuy ? () => onBuyTheme(item) : null,
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _TopUpButton extends StatelessWidget {
  final GameTheme theme;
  final int units;
  final String price;
  final ValueChanged<int> onTap;

  const _TopUpButton({
    required this.theme,
    required this.units,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(Icons.toll, color: theme.winColor, size: 18),
      label: Text('$units - $price'),
      onPressed: () => onTap(units),
    );
  }
}

class _ReviveDialog extends StatefulWidget {
  final GameTheme theme;
  final int wallet;
  final int cost;
  final VoidCallback onTopUp;

  const _ReviveDialog({
    required this.theme,
    required this.wallet,
    required this.cost,
    required this.onTopUp,
  });

  @override
  State<_ReviveDialog> createState() => _ReviveDialogState();
}

class _ReviveDialogState extends State<_ReviveDialog> {
  int _secondsLeft = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop(false);
        }
        return;
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRevive = widget.wallet >= widget.cost;

    return AlertDialog(
      backgroundColor: widget.theme.cardBg,
      title: Text(
        'Bạn đã thua',
        style: TextStyle(
          color: widget.theme.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _secondsLeft / 15,
                  color: widget.theme.xColor,
                  backgroundColor: widget.theme.gridLineColor,
                ),
                Center(
                  child: Text(
                    '$_secondsLeft',
                    style: TextStyle(
                      color: widget.theme.textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Revive với ${widget.cost} đơn vị?',
            style: TextStyle(color: widget.theme.textColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Số dư: ${widget.wallet}',
            style: TextStyle(color: widget.theme.subTextColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Bỏ qua'),
        ),
        if (!canRevive)
          TextButton(onPressed: widget.onTopUp, child: const Text('Nạp thêm')),
        ElevatedButton(
          onPressed: canRevive ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Revive'),
        ),
      ],
    );
  }
}
