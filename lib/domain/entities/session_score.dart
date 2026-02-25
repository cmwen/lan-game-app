import 'game_result.dart';

/// Cumulative scores across all rounds in a party session.
///
/// Updated after each mini-game completes.
class SessionScore {
  const SessionScore({
    this.totalScores = const {},
    this.gameResults = const [],
  });

  /// Maps each player's UUID to their cumulative point total.
  final Map<String, int> totalScores;

  /// Ordered list of results for each game played so far.
  final List<GameResult> gameResults;

  /// Returns a new [SessionScore] with the given [result] appended and
  /// its per-player scores merged into [totalScores].
  SessionScore addResult(GameResult result) {
    final updated = Map<String, int>.from(totalScores);
    for (final entry in result.playerScores.entries) {
      updated[entry.key] = (updated[entry.key] ?? 0) + entry.value;
    }
    return SessionScore(
      totalScores: Map.unmodifiable(updated),
      gameResults: List.unmodifiable([...gameResults, result]),
    );
  }

  /// Player UUID with the highest cumulative score, or `null` if empty.
  String? get leaderId {
    if (totalScores.isEmpty) return null;
    return totalScores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  SessionScore copyWith({
    Map<String, int>? totalScores,
    List<GameResult>? gameResults,
  }) {
    return SessionScore(
      totalScores: totalScores ?? this.totalScores,
      gameResults: gameResults ?? this.gameResults,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalScores': totalScores,
    'gameResults': gameResults.map((r) => r.toJson()).toList(),
  };

  factory SessionScore.fromJson(Map<String, dynamic> json) => SessionScore(
    totalScores: (json['totalScores'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    gameResults: (json['gameResults'] as List<dynamic>)
        .map((e) => GameResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  String toString() =>
      'SessionScore(games: ${gameResults.length}, scores: $totalScores)';
}
