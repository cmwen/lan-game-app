import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Tilt Racer — tilt your phone to steer a ball through obstacles to a goal
// ---------------------------------------------------------------------------

class TiltRacerGame extends MiniGame {
  TiltRacerGame(this._ctx);

  final GameContext _ctx;

  @override
  GameMetadata get metadata => TiltRacerFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) => _TiltRacerWidget(game: this);

  // ── Host state ──
  final List<_FinishEntry> _finishOrder = [];
  int? _hostStartMs;
  Timer? _timeoutTimer;
  bool _hostEnded = false;

  void _initHost() {
    if (_hostStartMs != null) return;
    _hostStartMs = DateTime.now().millisecondsSinceEpoch;
    // 60-second timeout
    _timeoutTimer = Timer(const Duration(seconds: 60), _endGame);
  }

  void _handleHostInput(GameMessage message) {
    _initHost();

    final senderId = message.senderId;
    final finishTimeMs = message.payload['finishTimeMs'] as int?;

    if (finishTimeMs != null) {
      // Player finished
      if (!_finishOrder.any((e) => e.playerId == senderId)) {
        _finishOrder.add(
          _FinishEntry(playerId: senderId, timeMs: finishTimeMs),
        );

        _ctx.broadcastState({
          'finished': _finishOrder
              .map((e) => {'playerId': e.playerId, 'timeMs': e.timeMs})
              .toList(),
        });

        // Check if all players finished
        if (_finishOrder.length >= _ctx.room.players.length) {
          _endGame();
        }
      }
    }
  }

  void _endGame() {
    if (_hostEnded) return;
    _hostEnded = true;
    _timeoutTimer?.cancel();

    final scores = <String, int>{};
    String? winnerId;
    int bestTime = 999999;

    for (final entry in _finishOrder) {
      // Score: higher is better. Invert time.
      final score = max(0, 60000 - entry.timeMs);
      scores[entry.playerId] = score;
      if (entry.timeMs < bestTime) {
        bestTime = entry.timeMs;
        winnerId = entry.playerId;
      }
    }

    // Give 0 points to players who didn't finish
    for (final p in _ctx.room.players) {
      scores.putIfAbsent(p.id, () => 0);
    }

    final durationMs =
        DateTime.now().millisecondsSinceEpoch - (_hostStartMs ?? 0);

    final result = GameResult(
      gameId: TiltRacerFactory.gameId,
      playerScores: scores,
      winnerId: winnerId,
      durationMs: durationMs,
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
  void dispose() {
    _timeoutTimer?.cancel();
  }
}

class _FinishEntry {
  _FinishEntry({required this.playerId, required this.timeMs});
  final String playerId;
  final int timeMs;
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

class TiltRacerFactory extends MiniGameFactory {
  static const String gameId = 'tilt_racer';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Tilt Racer',
    description: 'Tilt your phone to steer through the maze! Fastest wins.',
    emoji: '🏎️',
    minPlayers: 1,
    maxPlayers: 8,
    durationSeconds: 60,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => TiltRacerGame(context);
}

// ---------------------------------------------------------------------------
// Game Widget
// ---------------------------------------------------------------------------

class _TiltRacerWidget extends StatefulWidget {
  const _TiltRacerWidget({required this.game});
  final TiltRacerGame game;

  @override
  State<_TiltRacerWidget> createState() => _TiltRacerWidgetState();
}

class _TiltRacerWidgetState extends State<_TiltRacerWidget>
    with SingleTickerProviderStateMixin {
  // Ball physics
  double _ballX = 0;
  double _ballY = 0;
  double _velX = 0;
  double _velY = 0;
  static const double _ballRadius = 12;
  static const double _friction = 0.96;
  static const double _tiltSensitivity = 0.4;

  // Game state
  bool _finished = false;
  bool _gameOver = false;
  int? _startTimeMs;
  int? _finishTimeMs;
  double _elapsedSeconds = 0;
  List<Map<String, dynamic>> _finishedPlayers = [];

  // Track layout — normalized 0..1 coordinates
  // Obstacles are defined as (x, y, width, height) in 0..1 space
  static const List<List<double>> _obstacles = [
    [0.30, 0.10, 0.50, 0.04], // horizontal bar near top
    [0.00, 0.22, 0.45, 0.04], // horizontal bar left
    [0.60, 0.30, 0.04, 0.20], // vertical bar right
    [0.20, 0.40, 0.35, 0.04], // horizontal bar mid-left
    [0.70, 0.52, 0.30, 0.04], // horizontal bar right
    [0.00, 0.62, 0.40, 0.04], // horizontal bar left-low
    [0.50, 0.70, 0.04, 0.18], // vertical bar center-low
    [0.20, 0.85, 0.50, 0.04], // horizontal bar near bottom
  ];

  // Goal in bottom-right
  static const double _goalX = 0.88;
  static const double _goalY = 0.92;
  static const double _goalRadius = 0.04;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GameMessage>? _messageSub;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Timer? _posReportTimer;

  @override
  void initState() {
    super.initState();

    // Start position: top-left
    _ballX = 0.08;
    _ballY = 0.05;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;

    _ticker = createTicker(_onTick)..start();

    _accelSub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((event) {
          if (_finished || _gameOver) return;
          // event.x → left/right tilt, event.y → forward/back tilt
          // Negate x because tilting right gives negative x
          _velX += -event.x * _tiltSensitivity;
          _velY += event.y * _tiltSensitivity;
        });

    _messageSub = widget.game._ctx.incomingMessages.listen(_onMessage);

    // Report position to host every 500ms
    _posReportTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_finished && !_gameOver) {
        widget.game._ctx.sendInput({
          'position': {'x': _ballX, 'y': _ballY},
        });
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (_finished || _gameOver) return;

    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.1) return; // skip large gaps

    setState(() {
      _elapsedSeconds =
          (DateTime.now().millisecondsSinceEpoch - _startTimeMs!) / 1000.0;

      // Apply friction
      _velX *= _friction;
      _velY *= _friction;

      // Candidate position
      double newX = _ballX + _velX * dt * 0.01;
      double newY = _ballY + _velY * dt * 0.01;

      // Clamp to bounds
      newX = newX.clamp(0.0, 1.0);
      newY = newY.clamp(0.0, 1.0);

      // Check collisions with obstacles
      final ballR = _ballRadius / 400; // normalize radius
      for (final obs in _obstacles) {
        final ox = obs[0];
        final oy = obs[1];
        final ow = obs[2];
        final oh = obs[3];

        // Expanded obstacle rect by ball radius
        final left = ox - ballR;
        final right = ox + ow + ballR;
        final top = oy - ballR;
        final bottom = oy + oh + ballR;

        if (newX >= left && newX <= right && newY >= top && newY <= bottom) {
          // Determine which side was penetrated and bounce
          final dLeft = (newX - left).abs();
          final dRight = (newX - right).abs();
          final dTop = (newY - top).abs();
          final dBottom = (newY - bottom).abs();
          final minD = [dLeft, dRight, dTop, dBottom].reduce(min);

          if (minD == dLeft || minD == dRight) {
            _velX = -_velX * 0.5;
            newX = minD == dLeft ? left - 0.001 : right + 0.001;
          } else {
            _velY = -_velY * 0.5;
            newY = minD == dTop ? top - 0.001 : bottom + 0.001;
          }
        }
      }

      _ballX = newX.clamp(0.0, 1.0);
      _ballY = newY.clamp(0.0, 1.0);

      // Check goal
      final dx = _ballX - _goalX;
      final dy = _ballY - _goalY;
      if (sqrt(dx * dx + dy * dy) < _goalRadius + ballR) {
        _onFinish();
      }
    });
  }

  void _onFinish() {
    if (_finished) return;
    _finished = true;
    _finishTimeMs = DateTime.now().millisecondsSinceEpoch - (_startTimeMs ?? 0);

    widget.game._ctx.sendInput({'finishTimeMs': _finishTimeMs});
  }

  void _onMessage(GameMessage message) {
    if (message.type == 'game.state') {
      final payload = message.payload;
      if (payload.containsKey('finished')) {
        setState(() {
          _finishedPlayers = List<Map<String, dynamic>>.from(
            payload['finished'] as List,
          );
        });
      }
      if (payload.containsKey('phase') && payload['phase'] == 'end') {
        setState(() => _gameOver = true);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _accelSub?.cancel();
    _messageSub?.cancel();
    _posReportTimer?.cancel();
    super.dispose();
  }

  Color get _playerColor {
    final idx = widget.game._ctx.localPlayer.avatarIndex;
    return AppColors.playerColors[idx.clamp(0, 7)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _TrackPainter(
                          ballX: _ballX,
                          ballY: _ballY,
                          ballRadius: _ballRadius,
                          ballColor: _playerColor,
                          obstacles: _obstacles,
                          goalX: _goalX,
                          goalY: _goalY,
                          goalRadius: _goalRadius,
                          finished: _finished,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '⏱ ${_elapsedSeconds.toStringAsFixed(1)}s',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_finished)
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonLime.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🏁 ${(_finishTimeMs! / 1000).toStringAsFixed(2)}s',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonLime,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                ),
          Text(
            '${_finishedPlayers.length} finished',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_gameOver) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child:
            const Text(
                  '🏁 Race complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonCyan,
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms),
      );
    }
    if (_finished) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Waiting for others...',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        '📱 Tilt to steer • Reach the 🟢 goal',
        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track Painter — renders the maze, ball, and goal
// ---------------------------------------------------------------------------

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.ballColor,
    required this.obstacles,
    required this.goalX,
    required this.goalY,
    required this.goalRadius,
    required this.finished,
  });

  final double ballX;
  final double ballY;
  final double ballRadius;
  final Color ballColor;
  final List<List<double>> obstacles;
  final double goalX;
  final double goalY;
  final double goalRadius;
  final bool finished;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF111128),
    );

    // Grid lines for visual depth
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A40)
      ..strokeWidth = 1;
    for (double i = 0; i <= 1.0; i += 0.1) {
      canvas.drawLine(Offset(i * w, 0), Offset(i * w, h), gridPaint);
      canvas.drawLine(Offset(0, i * h), Offset(w, i * h), gridPaint);
    }

    // Goal
    final goalPaint = Paint()
      ..color = AppColors.neonLime.withAlpha(finished ? 100 : 200);
    canvas.drawCircle(
      Offset(goalX * w, goalY * h),
      goalRadius * min(w, h),
      goalPaint,
    );
    // Goal glow
    canvas.drawCircle(
      Offset(goalX * w, goalY * h),
      goalRadius * min(w, h) * 1.4,
      Paint()
        ..color = AppColors.neonLime.withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Obstacles
    for (final obs in obstacles) {
      final rect = Rect.fromLTWH(
        obs[0] * w,
        obs[1] * h,
        obs[2] * w,
        obs[3] * h,
      );
      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(3)),
        Paint()
          ..color = AppColors.neonMagenta.withAlpha(30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Wall
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = AppColors.neonMagenta.withAlpha(180),
      );
    }

    // Start marker
    canvas.drawCircle(
      Offset(0.08 * w, 0.05 * h),
      8,
      Paint()..color = AppColors.neonCyan.withAlpha(100),
    );

    // Ball glow
    canvas.drawCircle(
      Offset(ballX * w, ballY * h),
      ballRadius * 2,
      Paint()
        ..color = ballColor.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Ball
    canvas.drawCircle(
      Offset(ballX * w, ballY * h),
      ballRadius,
      Paint()..color = ballColor,
    );

    // Ball highlight
    canvas.drawCircle(
      Offset(ballX * w - 3, ballY * h - 3),
      ballRadius * 0.35,
      Paint()..color = Colors.white.withAlpha(120),
    );
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.ballX != ballX ||
        oldDelegate.ballY != ballY ||
        oldDelegate.finished != finished;
  }
}
