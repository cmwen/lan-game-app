import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/network_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/session_provider.dart';
import '../../routing/app_router.dart';

/// Per-game results — shows the winner and player rankings for the latest round.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final room = ref.watch(roomProvider);
    final network = ref.watch(networkProvider);
    final isHost = network.isHost;

    // Get the latest game result.
    final lastResult = session.gameResults.isNotEmpty
        ? session.gameResults.last
        : null;
    final players = room?.players ?? [];

    // Sort players by their score this round (descending).
    final roundScores = lastResult?.playerScores ?? {};
    final sortedEntries = roundScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Find the winner
    final winnerId = lastResult?.winnerId ?? sortedEntries.firstOrNull?.key;
    final winnerPlayer = players.where((p) => p.id == winnerId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Winner celebration
              if (winnerPlayer != null) ...[
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 56),
                ).animate().scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 12),
                Text(
                  '${winnerPlayer.nickname} Wins!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.warning,
                    shadows: [
                      Shadow(
                        color: AppColors.warning.withAlpha(120),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              ] else ...[
                Text(
                  'Game Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Round Rankings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Player rankings
              Expanded(
                child: ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (_, i) {
                    final entry = sortedEntries[i];
                    final player = players
                        .where((p) => p.id == entry.key)
                        .firstOrNull;
                    final medal = i == 0
                        ? '🥇'
                        : i == 1
                        ? '🥈'
                        : i == 2
                        ? '🥉'
                        : '  ';

                    return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(medal, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: player != null
                                    ? AppColors.playerColors[player.avatarIndex]
                                    : AppColors.surfaceVariant,
                                radius: 18,
                                child: Text(
                                  player?.nickname.isNotEmpty == true
                                      ? player!.nickname[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(player?.nickname ?? entry.key),
                          trailing: Text(
                            '${entry.value} pts',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.neonCyan),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (150 * i).ms, duration: 300.ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.scoreboard),
                        child: const Text('Scoreboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isHost)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.gameSelect),
                          child: const Text('Next Game'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
