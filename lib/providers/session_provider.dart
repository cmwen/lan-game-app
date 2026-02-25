import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/game_result.dart';
import '../domain/entities/session_score.dart';

/// Accumulates scores across multiple mini-game rounds in a party session.
class SessionNotifier extends Notifier<SessionScore> {
  @override
  SessionScore build() => const SessionScore();

  /// Append a game result and merge per-player scores into totals.
  void addResult(GameResult result) {
    state = state.addResult(result);
  }

  /// Reset the session (e.g. when starting a new party).
  void reset() {
    state = const SessionScore();
  }

  /// Sorted leaderboard: list of (playerId, totalScore) descending.
  List<MapEntry<String, int>> get leaderboard {
    final entries = state.totalScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

/// Cumulative session scores. Reset when the party ends.
final sessionProvider = NotifierProvider<SessionNotifier, SessionScore>(
  SessionNotifier.new,
);
