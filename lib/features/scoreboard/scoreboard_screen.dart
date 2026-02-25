import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/session_provider.dart';
import '../../routing/app_router.dart';

/// Cumulative leaderboard across all rounds in the session.
class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final room = ref.watch(roomProvider);
    final network = ref.watch(networkProvider);
    final isHost = network.isHost;
    final players = room?.players ?? [];

    // Sorted leaderboard
    final entries = session.totalScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Scoreboard')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '🏆 Leaderboard',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: AppColors.warning),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                '${session.gameResults.length} game${session.gameResults.length == 1 ? '' : 's'} played',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Leaderboard list
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No scores yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (_, i) {
                          final entry = entries[i];
                          final player = players
                              .where((p) => p.id == entry.key)
                              .firstOrNull;

                          final isLeader = i == 0;
                          final medal = i == 0
                              ? '🥇'
                              : i == 1
                              ? '🥈'
                              : i == 2
                              ? '🥉'
                              : '#${i + 1}';

                          return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isLeader
                                      ? AppColors.warning.withAlpha(20)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isLeader
                                      ? Border.all(
                                          color: AppColors.warning.withAlpha(
                                            80,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        medal,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: player != null
                                          ? AppColors.playerColors[player
                                                .avatarIndex]
                                          : AppColors.surfaceVariant,
                                      radius: 20,
                                      child: Text(
                                        player?.nickname.isNotEmpty == true
                                            ? player!.nickname[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.background,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        player?.nickname ?? entry.key,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${entry.value}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: isLeader
                                                ? AppColors.warning
                                                : AppColors.neonCyan,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'pts',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (100 * i).ms, duration: 300.ms)
                              .slideX(begin: 0.05, end: 0);
                        },
                      ),
              ),
              // Bottom actions
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (isHost)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.gameSelect),
                          child: const Text('Play Again'),
                        ),
                      ),
                    if (isHost) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _endSession(context, ref),
                        child: const Text('End Session'),
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

  void _endSession(BuildContext context, WidgetRef ref) {
    ref.read(sessionProvider.notifier).reset();
    ref.read(discoveryProvider.notifier).stopBroadcast();
    ref.read(networkProvider.notifier).disconnect();
    ref.read(roomProvider.notifier).leaveRoom();
    context.go(AppRoutes.home);
  }
}
