import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Reaction Roulette — wait for green, tap as fast as possible, best of 3
// ---------------------------------------------------------------------------

class ReactionGame extends MiniGame {
  ReactionGame(this._ctx) {
    if (_ctx.isHost) {
      // Small delay so clients can set up listeners
      _hostStartTimer = Timer(
        const Duration(milliseconds: 500),
        _hostStartRound,
      );
    }
  }

  final GameContext _ctx;
  Timer? _hostStartTimer;

  @override
  GameMetadata get metadata => ReactionGameFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) => _ReactionWidget(game: this);

  // ── Host state ──
  int _currentRound = 1;
  static const int _totalRounds = 3;
  Timer? _goTimer;
  int? _goTimestamp;
  final Map<String, List<int>> _allReactions = {}; // playerId -> [round times]
  int? _hostStartMs;

  void _hostStartRound() {
    _goTimestamp = null;

    // Tell everyone to wait
    _ctx.broadcastState({'phase': 'wait', 'round': _currentRound});

    // Random delay 2-5 seconds
    final delayMs = 2000 + Random().nextInt(3001);
    _goTimer = Timer(Duration(milliseconds: delayMs), () {
      _goTimestamp = DateTime.now().millisecondsSinceEpoch;
      _hostStartMs ??= _goTimestamp;
      _ctx.broadcastState({
        'phase': 'go',
        'round': _currentRound,
        'goTime': _goTimestamp,
      });
    });
  }

  void _handleHostInput(GameMessage message) {
    final senderId = message.senderId;
    final reactionMs = message.payload['reactionMs'] as int? ?? 0;
    final falseStart = message.payload['falseStart'] as bool? ?? false;
    final round = message.payload['round'] as int? ?? _currentRound;

    final penalty = falseStart ? 500 : 0;
    final effectiveMs = reactionMs + penalty;

    _allReactions.putIfAbsent(senderId, () => []);
    // Only record if we haven't gotten this round yet
    if (_allReactions[senderId]!.length < round) {
      _allReactions[senderId]!.add(effectiveMs);
    }

    // Check if all players have responded for this round
    final playerCount = _ctx.room.players.length;
    final allResponded = _allReactions.values.every(
      (list) => list.length >= _currentRound,
    );

    if (allResponded || _allReactions.length >= playerCount) {
      if (_currentRound < _totalRounds) {
        _currentRound++;
        Timer(const Duration(seconds: 2), _hostStartRound);
      } else {
        _endGame();
      }
    }
  }

  void _endGame() {
    // Calculate average reaction for each player
    final scores = <String, int>{};
    String? winnerId;
    double bestAvg = double.infinity;

    for (final entry in _allReactions.entries) {
      final times = entry.value;
      final avg = times.isEmpty
          ? 9999.0
          : times.reduce((a, b) => a + b) / times.length;
      // Score: lower is better. Invert for scoreboard (higher = better).
      // Use 1000 - avg clamped to a minimum of 0.
      final score = max(0, (3000 - avg).round());
      scores[entry.key] = score;

      if (avg < bestAvg) {
        bestAvg = avg;
        winnerId = entry.key;
      }
    }

    // Check for ties
    final topScore = scores.values.isEmpty ? 0 : scores.values.reduce(max);
    final topPlayers = scores.entries
        .where((e) => e.value == topScore)
        .toList();
    if (topPlayers.length > 1) winnerId = null;

    final durationMs =
        DateTime.now().millisecondsSinceEpoch - (_hostStartMs ?? 0);

    final result = GameResult(
      gameId: ReactionGameFactory.gameId,
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
    _hostStartTimer?.cancel();
    _goTimer?.cancel();
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

class ReactionGameFactory extends MiniGameFactory {
  static const String gameId = 'reaction_roulette';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Reaction Roulette',
    description: 'Wait for green, then tap! Fastest reactions win. Best of 3.',
    emoji: '🟢',
    minPlayers: 2,
    maxPlayers: 8,
    durationSeconds: 30,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => ReactionGame(context);
}

// ---------------------------------------------------------------------------
// Game Widget
// ---------------------------------------------------------------------------

class _ReactionWidget extends StatefulWidget {
  const _ReactionWidget({required this.game});
  final ReactionGame game;

  @override
  State<_ReactionWidget> createState() => _ReactionWidgetState();
}

class _ReactionWidgetState extends State<_ReactionWidget> {
  String _phase = 'waiting'; // waiting, wait, go, tapped, tooEarly, end
  int _round = 1;
  int? _goTimestamp;
  int? _reactionMs;
  bool _tappedThisRound = false;
  final List<int?> _roundResults = []; // null = false start with penalty
  StreamSubscription<GameMessage>? _messageSub;

  @override
  void initState() {
    super.initState();
    _messageSub = widget.game._ctx.incomingMessages.listen(_onMessage);
  }

  void _onMessage(GameMessage message) {
    if (message.type == 'game.state') {
      final payload = message.payload;
      final phase = payload['phase'] as String?;

      if (phase == 'wait') {
        setState(() {
          _phase = 'wait';
          _round = payload['round'] as int? ?? _round;
          _tappedThisRound = false;
          _reactionMs = null;
          _goTimestamp = null;
        });
      } else if (phase == 'go') {
        setState(() {
          _phase = 'go';
          _round = payload['round'] as int? ?? _round;
          _goTimestamp = payload['goTime'] as int?;
        });
      } else if (phase == 'end') {
        setState(() => _phase = 'end');
      }
    }
  }

  void _onTap() {
    if (_tappedThisRound || _phase == 'end' || _phase == 'waiting') return;

    if (_phase == 'wait') {
      // False start!
      setState(() {
        _phase = 'tooEarly';
        _tappedThisRound = true;
        _roundResults.add(null); // marker for false start
      });
      widget.game._ctx.sendInput({
        'reactionMs': 500,
        'falseStart': true,
        'round': _round,
      });
    } else if (_phase == 'go') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final reaction = _goTimestamp != null ? now - _goTimestamp! : 999;
      setState(() {
        _phase = 'tapped';
        _tappedThisRound = true;
        _reactionMs = reaction;
        _roundResults.add(reaction);
      });
      widget.game._ctx.sendInput({
        'reactionMs': reaction,
        'falseStart': false,
        'round': _round,
      });
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (_phase) {
      case 'wait':
        return const Color(0xFFD32F2F); // Red
      case 'go':
        return const Color(0xFF388E3C); // Green
      case 'tooEarly':
        return const Color(0xFFE65100); // Orange
      case 'tapped':
        return AppColors.neonCyan;
      default:
        return AppColors.surface;
    }
  }

  String get _displayText {
    switch (_phase) {
      case 'waiting':
        return 'Get Ready...\nRound $_round of 3';
      case 'wait':
        return 'Wait...';
      case 'go':
        return 'TAP!';
      case 'tooEarly':
        return 'Too early! 🚫\n+500ms penalty';
      case 'tapped':
        return '${_reactionMs}ms';
      case 'end':
        return '🏁 Game Over!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _backgroundColor,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Round indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final isComplete = i < _roundResults.length;
                      final isCurrent = i == _round - 1;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isComplete
                              ? (_roundResults[i] == null
                                    ? AppColors.warning
                                    : AppColors.neonLime)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCurrent ? Colors.white : Colors.white38,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Main display
                Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _phase == 'tapped' ? 64 : 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    )
                    .animate(target: _phase == 'go' ? 1 : 0)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 150.ms,
                    ),
                if (_phase == 'tapped') ...[
                  const SizedBox(height: 12),
                  Text(
                    _getReactionComment(),
                    style: const TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                ],
                if (_phase == 'end') ...[
                  const SizedBox(height: 24),
                  _buildRoundSummary(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getReactionComment() {
    if (_reactionMs == null) return '';
    if (_reactionMs! < 200) return '⚡ Lightning fast!';
    if (_reactionMs! < 300) return '🔥 Great reflexes!';
    if (_reactionMs! < 400) return '👍 Not bad!';
    return '🐢 A bit slow...';
  }

  Widget _buildRoundSummary() {
    return Column(
      children: [
        for (int i = 0; i < _roundResults.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _roundResults[i] == null
                  ? 'Round ${i + 1}: False start (+500ms)'
                  : 'Round ${i + 1}: ${_roundResults[i]}ms',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
