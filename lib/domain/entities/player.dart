/// An individual player in a game room.
///
/// Pure Dart — no Flutter imports. Immutable with manual copyWith.
class Player {
  const Player({
    required this.id,
    required this.nickname,
    this.avatarIndex = 0,
    this.isHost = false,
  }) : assert(avatarIndex >= 0 && avatarIndex <= 7);

  /// Unique UUID for this player.
  final String id;

  /// Player-chosen display name.
  final String nickname;

  /// Index (0–7) into the preset avatar colour palette.
  final int avatarIndex;

  /// Whether this player is the room host.
  final bool isHost;

  Player copyWith({
    String? id,
    String? nickname,
    int? avatarIndex,
    bool? isHost,
  }) {
    return Player(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'avatarIndex': avatarIndex,
    'isHost': isHost,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    avatarIndex: json['avatarIndex'] as int? ?? 0,
    isHost: json['isHost'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nickname == other.nickname &&
          avatarIndex == other.avatarIndex &&
          isHost == other.isHost;

  @override
  int get hashCode => Object.hash(id, nickname, avatarIndex, isHost);

  @override
  String toString() =>
      'Player(id: $id, nickname: $nickname, avatar: $avatarIndex, host: $isHost)';
}
