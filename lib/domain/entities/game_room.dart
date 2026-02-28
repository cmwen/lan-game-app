import 'player.dart';

/// The current lifecycle state of a game room.
enum RoomState { waiting, countdown, inGame, results }

/// A game room that players join before and during a play session.
///
/// The 4-letter [code] is generated from the safe alphabet
/// `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (excludes O, 0, I, 1, L to avoid
/// confusion when read aloud).
class GameRoom {
  const GameRoom({
    required this.code,
    required this.hostId,
    this.players = const [],
    this.state = RoomState.waiting,
    this.currentGameId,
  });

  /// 4-letter room code (safe alphabet, no O/0/I/1/L).
  final String code;

  /// UUID of the host player.
  final String hostId;

  /// All players currently in the room (including the host).
  final List<Player> players;

  /// Current room lifecycle state.
  final RoomState state;

  /// The registry ID of the game currently selected / in progress.
  final String? currentGameId;

  /// Alphabet used for room code generation (no O, 0, I, 1, L).
  static const String safeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  GameRoom copyWith({
    String? code,
    String? hostId,
    List<Player>? players,
    RoomState? state,
    String? currentGameId,
  }) {
    return GameRoom(
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      state: state ?? this.state,
      currentGameId: currentGameId ?? this.currentGameId,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'hostId': hostId,
    'players': players.map((p) => p.toJson()).toList(),
    'state': state.name,
    if (currentGameId != null) 'currentGameId': currentGameId,
  };

  factory GameRoom.fromJson(Map<String, dynamic> json) => GameRoom(
    code: json['code'] as String,
    hostId: json['hostId'] as String,
    players: (json['players'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList(),
    state: RoomState.values.byName(json['state'] as String),
    currentGameId: json['currentGameId'] as String?,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameRoom) return false;
    if (code != other.code ||
        hostId != other.hostId ||
        state != other.state ||
        currentGameId != other.currentGameId ||
        players.length != other.players.length) {
      return false;
    }
    for (var i = 0; i < players.length; i++) {
      if (players[i] != other.players[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(code, hostId, state, currentGameId, players.length);

  @override
  String toString() =>
      'GameRoom(code: $code, host: $hostId, players: ${players.length}, state: ${state.name})';
}
