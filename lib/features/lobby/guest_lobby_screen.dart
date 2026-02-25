import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../providers/network_provider.dart';
import '../../providers/room_provider.dart';
import '../../routing/app_router.dart';

/// Guest lobby — shows room info and player list while waiting for host to start.
class GuestLobbyScreen extends ConsumerWidget {
  const GuestLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final players = room?.players ?? [];
    final roomCode = room?.code ?? '----';

    // Listen for state transitions driven by the host.
    ref.listen<GameRoom?>(roomProvider, (prev, next) {
      if (next == null) return;
      if (next.state == RoomState.countdown && next.currentGameId != null) {
        context.go(AppRoutes.countdown);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await ref.read(networkProvider.notifier).disconnect();
          ref.read(roomProvider.notifier).leaveRoom();
          if (context.mounted) context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await ref.read(networkProvider.notifier).disconnect();
              ref.read(roomProvider.notifier).leaveRoom();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
          title: const Text('Lobby'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Room code
                Text(
                  'ROOM',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roomCode,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                // Player list
                Row(
                  children: [
                    Text(
                      'Players (${players.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (_, i) {
                      final p = players[i];
                      return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.playerColors[p.avatarIndex],
                              child: Text(
                                p.nickname.isNotEmpty
                                    ? p.nickname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(p.nickname),
                            trailing: p.isHost
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'HOST',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: AppColors.neonCyan),
                                    ),
                                  )
                                : null,
                          )
                          .animate()
                          .fadeIn(delay: (100 * i).ms, duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
                // Waiting indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child:
                      Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Waiting for host to start...',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 1000.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
