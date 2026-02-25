import 'package:flutter/widgets.dart';

import '../domain/entities/game_message.dart';
import '../domain/entities/game_result.dart';
import '../domain/entities/game_room.dart';
import '../domain/entities/player.dart';

// ---------------------------------------------------------------------------
// GameMetadata — static info shown in game browser and lobby selector
// ---------------------------------------------------------------------------
class GameMetadata {
  const GameMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.minPlayers,
    required this.maxPlayers,
    required this.durationSeconds,
  });

  /// Unique identifier used by the registry, e.g. `"shake_race"`.
  final String id;

  /// Human-readable title shown in the game picker.
  final String title;

  /// One-liner describing the game.
  final String description;

  /// Single emoji used as the game icon in lists and headers.
  final String emoji;

  /// Minimum number of players needed to start.
  final int minPlayers;

  /// Maximum concurrent players supported.
  final int maxPlayers;

  /// Approximate duration in seconds (shown as a hint before starting).
  final int durationSeconds;
}

// ---------------------------------------------------------------------------
// GameContext — injected by the shell; games use this to communicate
// ---------------------------------------------------------------------------
abstract class GameContext {
  /// The player on this device.
  Player get localPlayer;

  /// The current room state.
  GameRoom get room;

  /// Whether the local device is the host.
  bool get isHost;

  /// Stream of incoming [GameMessage]s relevant to this game.
  Stream<GameMessage> get incomingMessages;

  /// Client → host: send local player's input.
  void sendInput(Map<String, dynamic> payload);

  /// Host → all: push authoritative game state delta.
  void broadcastState(Map<String, dynamic> payload);

  /// Call when the game is over — shell navigates to results.
  void completeGame(GameResult result);
}

// ---------------------------------------------------------------------------
// MiniGame — the live game instance
// ---------------------------------------------------------------------------
abstract class MiniGame {
  /// Static metadata for this game.
  GameMetadata get metadata;

  /// Build the game's root widget. Fills the GameShellScreen body.
  Widget buildGameWidget(BuildContext context);

  /// Called when a [GameMessage] arrives from the network.
  void onMessage(GameMessage message);

  /// Clean up: cancel subscriptions, timers, sensors.
  void dispose();
}

// ---------------------------------------------------------------------------
// MiniGameFactory — creates a game instance and exposes its metadata
// ---------------------------------------------------------------------------
abstract class MiniGameFactory {
  /// Metadata for the game this factory creates.
  GameMetadata get metadata;

  /// Instantiate a game with the given [context].
  MiniGame create(GameContext context);
}
