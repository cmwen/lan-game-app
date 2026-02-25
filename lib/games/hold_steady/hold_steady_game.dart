import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Hold Steady — hold your phone perfectly still; last player standing wins
// ---------------------------------------------------------------------------

class HoldSteadyGame extends MiniGame {
  HoldSteadyGame(this._ctx);

  final GameContext _ctx;

  @override
  GameMetadata get metadata => HoldSteadyFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) => _HoldSteadyWidget(game: this);

  // ── Host state ──
  final Set<String> _alivePlayers = {};
  final Set<String> _eliminatedPlayers = {};
  final Map<String, int> _survivalTimes = {};
  int? _hostStartMs;
  bool _hostGameStarted = false;

  void _initHost() {
    if (!_hostGameStarted) {
      _hostGameStarted = true;
      _hostStartMs = DateTime.now().millisecondsSinceEpoch;
      for (final p in _ctx.room.players) {
        _alivePlayers.add(p.id);
      }
    }
  }

  void _handleHostInput(GameMessage message) {
    _initHost();

    final senderId = message.senderId;
    final eliminated = message.payload['eliminated'] as bool? ?? false;

    if (eliminated && _alivePlayers.contains(senderId)) {
      _alivePlayers.remove(senderId);
      _eliminatedPlayers.add(senderId);
      _survivalTimes[senderId] = message.payload['survivedMs'] as int? ?? 0;

      _broadcastAlive();

      // Check if game should end (0 or 1 remaining)
      if (_alivePlayers.length <= 1) {
        _endGame();
      }
    } else {
      // Just a stability update — broadcast alive list periodically
      _broadcastAlive();
    }
  }

  void _broadcastAlive() {
    _ctx.broadcastState({
      'alive': _alivePlayers.toList(),
      'eliminated': _eliminatedPlayers.toList(),
    });
  }

  void _endGame() {
    final scores = <String, int>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    final gameMs = now - (_hostStartMs ?? now);

    // Winner is the last person alive
    String? winnerId;
    if (_alivePlayers.length == 1) {
      winnerId = _alivePlayers.first;
    }

    // Score based on survival time
    for (final pid in _eliminatedPlayers) {
      scores[pid] = _survivalTimes[pid] ?? 0;
    }
    for (final pid in _alivePlayers) {
      scores[pid] = gameMs; // survived the whole game
    }

    final result = GameResult(
      gameId: HoldSteadyFactory.gameId,
      playerScores: scores,
      winnerId: winnerId,
      durationMs: gameMs,
    );

    _ctx.broadcastState({'phase': 'end', 'result': result.toJson()});
    _ctx.completeGame(result);
  }

  @override
  void onMessage(GameMessage message) {
    if (_ctx.isHost && message.type == 'game.input') {
      _handleHostInput(message);
    }
  }

  @override
  void dispose() {}
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

class HoldSteadyFactory extends MiniGameFactory {
  static const String gameId = 'hold_steady';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Hold Steady',
    description:
        'Hold your phone perfectly still! The gyroscope detects movement.',
    emoji: '🤫',
    minPlayers: 2,
    maxPlayers: 8,
    durationSeconds: 60,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => HoldSteadyGame(context);
}

// ---------------------------------------------------------------------------
// Game Widget
// ---------------------------------------------------------------------------

class _HoldSteadyWidget extends StatefulWidget {
  const _HoldSteadyWidget({required this.game});
  final HoldSteadyGame game;

  @override
  State<_HoldSteadyWidget> createState() => _HoldSteadyWidgetState();
}

class _HoldSteadyWidgetState extends State<_HoldSteadyWidget>
    with SingleTickerProviderStateMixin {
  double _instability = 0.0; // 0.0 = rock solid, 1.0 = eliminated
  bool _eliminated = false;
  bool _gameOver = false;
  int _aliveCount = 0;
  int _totalPlayers = 0;
  List<String> _alivePlayers = [];
  double _elapsedSeconds = 0;

  // Threshold decreases over time to increase difficulty
  double get _threshold => max(0.1, 0.3 - (_elapsedSeconds / 100) * 0.2);

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<GameMessage>? _messageSub;
  Timer? _stabilityTimer;
  Timer? _reportTimer;
  Timer? _elapsedTimer;
  int? _startTimeMs;

  late AnimationController _ringPulse;

  @override
  void initState() {
    super.initState();
    _totalPlayers = widget.game._ctx.room.players.length;
    _aliveCount = _totalPlayers;

    _ringPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startTimeMs = DateTime.now().millisecondsSinceEpoch;

    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_eliminated && !_gameOver) {
        setState(() {
          _elapsedSeconds =
              (DateTime.now().millisecondsSinceEpoch - _startTimeMs!) / 1000.0;
        });
      }
    });

    _startGyroscope();
    _messageSub = widget.game._ctx.incomingMessages.listen(_onMessage);

    // Report stability to host periodically
    _reportTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_eliminated && !_gameOver) {
        widget.game._ctx.sendInput({
          'stability': _instability,
          'eliminated': false,
        });
      }
    });
  }

  void _startGyroscope() {
    _gyroSub =
        gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((event) {
          if (_eliminated || _gameOver) return;

          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          setState(() {
            if (magnitude > _threshold) {
              // Movement detected — instability rises
              _instability = min(
                1.0,
                _instability + (magnitude - _threshold) * 0.02,
              );
            } else {
              // Slowly recover
              _instability = max(0.0, _instability - 0.003);
            }

            if (_instability >= 1.0 && !_eliminated) {
              _onEliminated();
            }
          });
        });
  }

  void _onEliminated() {
    _eliminated = true;
    final survivedMs =
        DateTime.now().millisecondsSinceEpoch - (_startTimeMs ?? 0);
    widget.game._ctx.sendInput({'eliminated': true, 'survivedMs': survivedMs});
  }

  void _onMessage(GameMessage message) {
    if (message.type == 'game.state') {
      final payload = message.payload;
      if (payload.containsKey('alive')) {
        setState(() {
          _alivePlayers = List<String>.from(payload['alive'] as List);
          _aliveCount = _alivePlayers.length;
        });
      }
      if (payload.containsKey('phase') && payload['phase'] == 'end') {
        setState(() => _gameOver = true);
      }
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _messageSub?.cancel();
    _stabilityTimer?.cancel();
    _reportTimer?.cancel();
    _elapsedTimer?.cancel();
    _ringPulse.dispose();
    super.dispose();
  }

  Color get _meterColor {
    if (_instability < 0.3) return AppColors.neonLime;
    if (_instability < 0.6) return AppColors.warning;
    if (_instability < 0.85) return AppColors.error;
    return const Color(0xFFFF0000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main stability ring
            Expanded(child: _buildStabilityRing()),
            // Status text
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '⏱ ${_elapsedSeconds.toStringAsFixed(1)}s',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Threshold: ${_threshold.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_aliveCount / $_totalPlayers alive',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neonCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityRing() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            SizedBox.expand(
              child: CustomPaint(
                painter: _StabilityRingPainter(
                  progress: _instability,
                  color: _meterColor,
                  backgroundColor: AppColors.surfaceVariant,
                ),
              ),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_eliminated) ...[
                  const Text(
                    '❌',
                    style: TextStyle(fontSize: 48),
                  ).animate().scale(
                    begin: const Offset(2, 2),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You moved!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    '${_elapsedSeconds.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else if (_gameOver) ...[
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 48),
                  ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Winner!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonLime,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${(_instability * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: _meterColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hold still!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (!_eliminated && !_gameOver)
            Text(
              _instability < 0.3
                  ? '🧘 Perfectly still...'
                  : _instability < 0.6
                  ? '😰 Careful...'
                  : '🫨 Too much movement!',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          if (_eliminated)
            Text(
              'Survived ${_elapsedSeconds.toStringAsFixed(1)} seconds',
              style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stability Ring Painter
// ---------------------------------------------------------------------------

class _StabilityRingPainter extends CustomPainter {
  _StabilityRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 16.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    if (progress > 0.5) {
      final glowPaint = Paint()
        ..color = color.withAlpha((50 * progress).toInt())
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StabilityRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
