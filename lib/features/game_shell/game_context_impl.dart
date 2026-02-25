import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/player.dart';
import '../../games/mini_game_interface.dart';

/// Concrete implementation of [GameContext] used by [GameShellScreen].
///
/// Bridges the shell (networking, navigation, session) with the mini-game
/// instance. The game never touches GoRouter or Riverpod directly.
class GameContextImpl implements GameContext {
  GameContextImpl({
    required this.localPlayer,
    required this.room,
    required this.isHost,
    required Stream<GameMessage> messageStream,
    required void Function(Map<String, dynamic>) onSendInput,
    required void Function(Map<String, dynamic>) onBroadcastState,
    required void Function(GameResult) onComplete,
  }) : incomingMessages = messageStream,
       _onSendInput = onSendInput,
       _onBroadcastState = onBroadcastState,
       _onComplete = onComplete;

  @override
  final Player localPlayer;

  @override
  final GameRoom room;

  @override
  final bool isHost;

  @override
  final Stream<GameMessage> incomingMessages;

  final void Function(Map<String, dynamic>) _onSendInput;
  final void Function(Map<String, dynamic>) _onBroadcastState;
  final void Function(GameResult) _onComplete;

  @override
  void sendInput(Map<String, dynamic> payload) => _onSendInput(payload);

  @override
  void broadcastState(Map<String, dynamic> payload) {
    assert(isHost, 'Only the host should call broadcastState');
    _onBroadcastState(payload);
  }

  @override
  void completeGame(GameResult result) => _onComplete(result);
}
