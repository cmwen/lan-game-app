/// Result produced when a mini-game finishes. Consumed by the session
/// scoreboard to accumulate totals across rounds.
class GameResult {
  const GameResult({
    required this.gameId,
    required this.playerScores,
    this.winnerId,
    required this.durationMs,
  });

  /// The registry ID of the game that was played, e.g. `"shake_race"`.
  final String gameId;

  /// Maps each player's UUID to the score they earned this round.
  final Map<String, int> playerScores;

  /// UUID of the winning player, or `null` for a draw / no winner.
  final String? winnerId;

  /// How long the game lasted in milliseconds.
  final int durationMs;

  GameResult copyWith({
    String? gameId,
    Map<String, int>? playerScores,
    String? winnerId,
    int? durationMs,
  }) {
    return GameResult(
      gameId: gameId ?? this.gameId,
      playerScores: playerScores ?? this.playerScores,
      winnerId: winnerId ?? this.winnerId,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'playerScores': playerScores,
    if (winnerId != null) 'winnerId': winnerId,
    'durationMs': durationMs,
  };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    gameId: json['gameId'] as String,
    playerScores: (json['playerScores'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    winnerId: json['winnerId'] as String?,
    durationMs: json['durationMs'] as int,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResult &&
          runtimeType == other.runtimeType &&
          gameId == other.gameId &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(gameId, durationMs);

  @override
  String toString() =>
      'GameResult(gameId: $gameId, winner: $winnerId, durationMs: $durationMs)';
}
