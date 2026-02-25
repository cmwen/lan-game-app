import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_room.dart';
import '../../games/game_registry.dart';
import '../../providers/network_provider.dart';
import '../../providers/room_provider.dart';
import '../../routing/app_router.dart';

/// Host picks a mini-game from the registry. Tapping a card broadcasts
/// the selection and navigates everyone to the countdown.
class GameSelectScreen extends ConsumerWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = GameRegistry.allMetadata;
    final room = ref.watch(roomProvider);
    final isHost =
        ref.read(networkProvider).isHost || room?.state == RoomState.waiting;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a Game')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: games.length,
            itemBuilder: (_, i) {
              final meta = games[i];
              return _GameCard(
                    metadata: meta,
                    onTap: isHost
                        ? () => _selectGame(context, ref, meta.id)
                        : null,
                  )
                  .animate()
                  .fadeIn(delay: (80 * i).ms, duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    delay: (80 * i).ms,
                    duration: 300.ms,
                  );
            },
          ),
        ),
      ),
    );
  }

  void _selectGame(BuildContext context, WidgetRef ref, String gameId) {
    // Update room
    ref.read(roomProvider.notifier).selectGame(gameId);
    ref.read(roomProvider.notifier).setRoomState(RoomState.countdown);

    // Broadcast to guests
    final networkNotifier = ref.read(networkProvider.notifier);
    networkNotifier.broadcast(
      GameMessage(
        type: 'game.selected',
        senderId: 'host',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: {'gameId': gameId},
      ),
    );

    // Navigate host to countdown
    context.go(AppRoutes.countdown);
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.metadata, this.onTap});

  final dynamic metadata;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metadata.emoji as String,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                metadata.title as String,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.neonCyan),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${metadata.minPlayers}–${metadata.maxPlayers} players',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                '~${metadata.durationSeconds}s',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                metadata.description as String,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
