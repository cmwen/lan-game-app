/// The wire format for all network communication between host and clients.
///
/// Message type convention:  `<domain>.<action>`
///   - `lobby.join`, `lobby.roomState`, `lobby.playerJoined`, `lobby.playerLeft`
///   - `game.input`, `game.state`, `game.end`
///   - `system.ping`, `system.pong`, `system.playerDisconnected`
class GameMessage {
  const GameMessage({
    required this.type,
    required this.senderId,
    this.payload = const {},
    required this.timestamp,
  });

  /// Dot-separated message type, e.g. `"lobby.join"`, `"game.input"`.
  final String type;

  /// UUID of the player (or `"system"`) who sent this message.
  final String senderId;

  /// Arbitrary key-value data carried by the message.
  final Map<String, dynamic> payload;

  /// Unix epoch milliseconds when the message was created.
  final int timestamp;

  Map<String, dynamic> toJson() => {
    'type': type,
    'senderId': senderId,
    'payload': payload,
    'timestamp': timestamp,
  };

  factory GameMessage.fromJson(Map<String, dynamic> json) => GameMessage(
    type: json['type'] as String,
    senderId: json['senderId'] as String,
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    timestamp: json['timestamp'] as int,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameMessage &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          senderId == other.senderId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(type, senderId, timestamp);

  @override
  String toString() =>
      'GameMessage(type: $type, sender: $senderId, ts: $timestamp)';
}
