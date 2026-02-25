import 'package:flutter/widgets.dart';

import '../../domain/entities/game_message.dart';
import '../../games/mini_game_interface.dart';

// ---------------------------------------------------------------------------
// Shake Race — first player to shake their phone 100 times wins
// ---------------------------------------------------------------------------
// This is a skeleton demonstrating the MiniGame contract.
// Full implementation requires: sensors_plus, dart:math

class ShakeRaceGame extends MiniGame {
  ShakeRaceGame(this._ctx);

  // ignore: unused_field
  final GameContext _ctx;

  @override
  GameMetadata get metadata => ShakeRaceFactory.meta;

  @override
  Widget buildGameWidget(BuildContext context) {
    return const _ShakeRacePlaceholder();
  }

  @override
  void onMessage(GameMessage message) {
    // Handle incoming shake events from other players
    // if (message.payload['type'] == 'shake') {
    //   final pid = message.payload['playerId'] as String;
    //   _shakeCounts[pid] = (_shakeCounts[pid] ?? 0) + 1;
    //   if (_ctx.isHost && _shakeCounts[pid]! >= _targetShakes) _endGame(pid);
    // }
  }

  @override
  void dispose() {
    // _accelSub?.cancel();
  }
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------
class ShakeRaceFactory extends MiniGameFactory {
  static const String gameId = 'shake_race';

  static const GameMetadata meta = GameMetadata(
    id: gameId,
    title: 'Shake Race',
    description: 'First to shake their phone 100 times wins! Go go go!',
    emoji: '📳',
    minPlayers: 2,
    maxPlayers: 8,
    durationSeconds: 45,
  );

  @override
  GameMetadata get metadata => meta;

  @override
  MiniGame create(GameContext context) => ShakeRaceGame(context);
}

// ---------------------------------------------------------------------------
// Placeholder UI
// ---------------------------------------------------------------------------
class _ShakeRacePlaceholder extends StatelessWidget {
  const _ShakeRacePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '📳 SHAKE!\nImplementation pending',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, color: Color(0xFF00E5FF)),
      ),
    );
  }
}
