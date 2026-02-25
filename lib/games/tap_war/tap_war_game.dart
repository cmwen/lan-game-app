import 'package:flutter/widgets.dart';

import '../../domain/entities/game_message.dart';
import '../../games/mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Tap War — tap your screen as fast as possible; most taps in 10 seconds wins
// ---------------------------------------------------------------------------
class TapWarGame extends MiniGame {
  TapWarGame(this._ctx);

  final GameContext _ctx;
  // ignore: unused_field
  final Map<String, int> _tapCounts = {};
  // ignore: unused_field
  final bool _gameOver = false;

  // ignore: unused_field
  static const Duration _gameDuration = Duration(seconds: 10);

  @override
  GameMetadata get metadata => TapWarFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) => const _TapWarPlaceholder();

  @override
  void onMessage(GameMessage message) {
    // Handle incoming tap events
    // if (message.payload['type'] == 'tap') {
    //   final pid = message.payload['playerId'] as String;
    //   _tapCounts[pid] = (_tapCounts[pid] ?? 0) + 1;
    // }
  }

  void onLocalTap() {
    _ctx.sendInput({'type': 'tap', 'playerId': _ctx.localPlayer.id});
  }

  @override
  void dispose() {}
}

class TapWarFactory extends MiniGameFactory {
  static const String gameId = 'tap_war';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Tap War',
    description: 'Tap as fast as you can! Most taps in 10 seconds wins.',
    emoji: '👊',
    minPlayers: 2,
    maxPlayers: 8,
    durationSeconds: 20,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => TapWarGame(context);
}

class _TapWarPlaceholder extends StatelessWidget {
  const _TapWarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '👊 TAP TAP TAP!\nImplementation pending',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, color: Color(0xFF00E5FF)),
      ),
    );
  }
}
