import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../domain/entities/game_message.dart';
import '../domain/entities/game_room.dart';
import '../domain/entities/player.dart';

/// Manages the game room state for both host and guest.
class RoomNotifier extends Notifier<GameRoom?> {
  @override
  GameRoom? build() => null;

  // ─── Host operations ─────────────────────────────────────────────────────

  /// Create a new room with this player as host.
  void createRoom(Player host) {
    final code = _generateRoomCode();
    state = GameRoom(
      code: code,
      hostId: host.id,
      players: [host.copyWith(isHost: true)],
      state: RoomState.waiting,
    );
  }

  /// Add a player who just connected to the room.
  void addPlayer(Player player) {
    if (state == null) return;
    // Avoid duplicates
    final exists = state!.players.any((p) => p.id == player.id);
    if (exists) return;
    state = state!.copyWith(players: [...state!.players, player]);
  }

  /// Remove a player by ID (disconnect / kick).
  void removePlayer(String playerId) {
    if (state == null) return;
    state = state!.copyWith(
      players: state!.players.where((p) => p.id != playerId).toList(),
    );
  }

  /// Change the room lifecycle state.
  void setRoomState(RoomState roomState) {
    if (state == null) return;
    state = state!.copyWith(state: roomState);
  }

  /// Set the game that was selected by the host.
  void selectGame(String gameId) {
    if (state == null) return;
    state = state!.copyWith(currentGameId: gameId);
  }

  // ─── Guest operations ────────────────────────────────────────────────────

  /// Guest: set the room state received from the host.
  void setRoom(GameRoom room) {
    state = room;
  }

  /// Process an incoming network message and update room state accordingly.
  void handleMessage(GameMessage message) {
    switch (message.type) {
      case 'lobby.roomState':
        final room = GameRoom.fromJson(
          message.payload['room'] as Map<String, dynamic>,
        );
        state = room;
      case 'lobby.playerJoined':
        final player = Player.fromJson(
          message.payload['player'] as Map<String, dynamic>,
        );
        addPlayer(player);
      case 'lobby.playerLeft':
        final playerId = message.payload['playerId'] as String;
        removePlayer(playerId);
      case 'game.selected':
        final gameId = message.payload['gameId'] as String;
        selectGame(gameId);
        setRoomState(RoomState.countdown);
      case 'game.start':
        setRoomState(RoomState.inGame);
      case 'game.end':
        setRoomState(RoomState.results);
      default:
        break;
    }
  }

  /// Leave / tear down the room.
  void leaveRoom() {
    state = null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _generateRoomCode() {
    final rng = Random.secure();
    return String.fromCharCodes(
      List.generate(
        AppConstants.roomCodeLength,
        (_) => AppConstants.safeAlphabet.codeUnitAt(
          rng.nextInt(AppConstants.safeAlphabet.length),
        ),
      ),
    );
  }
}

/// The current game room. `null` when not in a room.
final roomProvider = NotifierProvider<RoomNotifier, GameRoom?>(
  RoomNotifier.new,
);
