import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Tap Frenzy — tap a big button as fast as possible for 10 seconds
// ---------------------------------------------------------------------------

class TapFrenzyGame extends MiniGame {
  TapFrenzyGame(this._ctx);

  final GameContext _ctx;

  @override
  GameMetadata get metadata => TapFrenzyFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) => _TapFrenzyWidget(game: this);

  // ── Host state ──
  final Map<String, int> _hostScores = {};
  Timer? _hostTimer;
  int? _hostStartTimeMs;

  static const Duration _gameDuration = Duration(seconds: 10);

  void _handleHostMessage(GameMessage message) {
    if (message.type == 'game.input') {
      final senderId = message.senderId;
      final count = message.payload['tapCount'] as int? ?? 0;
      _hostScores[senderId] = count;

      // Start host timer on first input
      if (_hostTimer == null) {
        _hostStartTimeMs = DateTime.now().millisecondsSinceEpoch;
        _hostTimer = Timer(_gameDuration, _endGame);
      }

      // Broadcast scoreboard
      _ctx.broadcastState({'scores': _hostScores});
    }
  }

  void _endGame() {
    final scores = Map<String, int>.from(_hostScores);

    String? winnerId;
    int maxScore = -1;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        winnerId = entry.key;
      }
    }

    // Check for ties
    final topPlayers = scores.entries
        .where((e) => e.value == maxScore)
        .toList();
    if (topPlayers.length > 1) winnerId = null;

    final durationMs =
        DateTime.now().millisecondsSinceEpoch - (_hostStartTimeMs ?? 0);

    final result = GameResult(
      gameId: TapFrenzyFactory.gameId,
      playerScores: scores,
      winnerId: winnerId,
      durationMs: durationMs,
    );

    _ctx.broadcastState({'gameEnd': true, 'result': result.toJson()});
    _ctx.completeGame(result);
  }

  @override
  void onMessage(GameMessage message) {
    if (_ctx.isHost) {
      _handleHostMessage(message);
    }
  }

  @override
  void dispose() {
    _hostTimer?.cancel();
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

class TapFrenzyFactory extends MiniGameFactory {
  static const String gameId = 'tap_frenzy';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Tap Frenzy',
    description: 'Tap as fast as you can for 10 seconds! Most taps wins.',
    emoji: '🔥',
    minPlayers: 2,
    maxPlayers: 8,
    durationSeconds: 15,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => TapFrenzyGame(context);
}

// ---------------------------------------------------------------------------
// Game Widget
// ---------------------------------------------------------------------------

class _TapFrenzyWidget extends StatefulWidget {
  const _TapFrenzyWidget({required this.game});
  final TapFrenzyGame game;

  @override
  State<_TapFrenzyWidget> createState() => _TapFrenzyWidgetState();
}

class _TapFrenzyWidgetState extends State<_TapFrenzyWidget>
    with TickerProviderStateMixin {
  int _tapCount = 0;
  double _secondsLeft = 10.0;
  bool _gameStarted = false;
  bool _gameOver = false;
  Map<String, int> _scores = {};
  Timer? _countdownTimer;
  StreamSubscription<GameMessage>? _messageSub;
  int _milestone = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  Color get _playerColor {
    final idx = widget.game._ctx.localPlayer.avatarIndex;
    return AppColors.playerColors[idx.clamp(0, 7)];
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _messageSub = widget.game._ctx.incomingMessages.listen(_onMessage);
  }

  void _onMessage(GameMessage message) {
    if (message.type == 'game.state') {
      final payload = message.payload;
      if (payload.containsKey('scores')) {
        setState(() {
          _scores = Map<String, int>.from(
            (payload['scores'] as Map).map(
              (k, v) => MapEntry(k.toString(), v as int),
            ),
          );
        });
      }
      if (payload.containsKey('gameEnd') && payload['gameEnd'] == true) {
        setState(() => _gameOver = true);
        _countdownTimer?.cancel();
      }
    }
  }

  void _onTap() {
    if (_gameOver) return;

    if (!_gameStarted) {
      _gameStarted = true;
      _secondsLeft = 10.0;
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        setState(() {
          _secondsLeft = max(0.0, _secondsLeft - 0.05);
        });
        if (_secondsLeft <= 0) {
          timer.cancel();
          setState(() => _gameOver = true);
        }
      });
    }

    setState(() => _tapCount++);
    // Pulse feedback
    _pulseController.forward(from: 0);

    // Milestone shake
    final newMilestone = _tapCount ~/ 25;
    if (newMilestone > _milestone) {
      _milestone = newMilestone;
      _shakeController.forward(from: 0);
    }

    // Send to host
    widget.game._ctx.sendInput({'tapCount': _tapCount});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _messageSub?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timer bar
        _buildTimerBar(),
        // Main tap area
        Expanded(child: _buildTapArea()),
      ],
    );
  }

  Widget _buildTimerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Text(
            _gameStarted ? _secondsLeft.toStringAsFixed(1) : 'TAP TO START',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _secondsLeft <= 3 ? AppColors.error : AppColors.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _secondsLeft / 10.0,
              backgroundColor: AppColors.surfaceVariant,
              color: _secondsLeft <= 3 ? AppColors.error : AppColors.neonCyan,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapArea() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset =
            sin(_shakeController.value * pi * 6) *
            8 *
            (1 - _shakeController.value);
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _onTap(),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 - (_pulseController.value * 0.05);
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _gameOver
                  ? AppColors.surfaceVariant
                  : _playerColor.withAlpha(200),
              borderRadius: BorderRadius.circular(32),
              boxShadow: _gameOver
                  ? []
                  : [
                      BoxShadow(
                        color: _playerColor.withAlpha(80),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        '$_tapCount',
                        style: const TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      )
                      .animate(target: _tapCount > 0 ? 1 : 0)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 100.ms,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    _gameOver ? '⏰ Time\'s up!' : 'TAP! TAP! TAP!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  if (_gameOver && _scores.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ..._buildScoreboard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScoreboard() {
    final sorted = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final players = widget.game._ctx.room.players;

    return [
      for (final entry in sorted)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${players.where((p) => p.id == entry.key).firstOrNull?.nickname ?? "?"}: ${entry.value}',
            style: TextStyle(
              fontSize: 16,
              color: entry.key == widget.game._ctx.localPlayer.id
                  ? _playerColor
                  : Colors.white70,
            ),
          ),
        ),
    ];
  }
}
