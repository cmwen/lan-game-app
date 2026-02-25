import 'package:flutter/material.dart';
import '../../games/game_registry.dart';

/// Hosts the currently active mini-game widget.
///
/// Responsibilities:
///   - Instantiate the correct [MiniGame] via [GameRegistry]
///   - Create [GameContextImpl] and wire up network callbacks
///   - Start [GameLoopController] if host
///   - Navigate to results when [GameContext.onGameComplete] fires
class GameShellScreen extends StatefulWidget {
  const GameShellScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameShellScreen> createState() => _GameShellScreenState();
}

class _GameShellScreenState extends State<GameShellScreen> {
  // TODO: inject via Riverpod ref
  // final _game = GameRegistry.get(widget.gameId)?.create(context);

  @override
  Widget build(BuildContext context) {
    final factory = GameRegistry.get(widget.gameId);

    if (factory == null) {
      return Scaffold(
        body: Center(child: Text('Unknown game: ${widget.gameId}')),
      );
    }

    // TODO: wire up GameContextImpl with actual providers
    return const Scaffold(
      body: Center(child: Text('Game Shell — TODO: wire up GameContextImpl')),
    );
  }
}
