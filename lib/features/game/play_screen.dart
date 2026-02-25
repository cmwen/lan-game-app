import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/entities/game_room.dart';
import '../../features/game_shell/game_context_impl.dart';
import '../../games/game_registry.dart';
import '../../games/mini_game_interface.dart';
import '../../providers/network_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/session_provider.dart';
import '../../routing/app_router.dart';

/// Loads the selected mini-game from the registry, provides [GameContext],
/// and wraps the game widget with a timer/header.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  MiniGame? _game;
  late final Stopwatch _stopwatch;
  Timer? _uiTimer;
  int _elapsedSeconds = 0;
  StreamSubscription<GameMessage>? _messageSub;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
      }
    });

    _initGame();
  }

  void _initGame() {
    final factory = GameRegistry.get(widget.gameId);
    if (factory == null) return;

    final player = ref.read(localPlayerProvider);
    final room = ref.read(roomProvider);
    final network = ref.read(networkProvider);
    if (player == null || room == null) return;

    final gameContext = GameContextImpl(
      localPlayer: player,
      room: room,
      isHost: network.isHost,
      messageStream: ref
          .read(networkProvider.notifier)
          .messages
          .where((m) => m.type.startsWith('game.')),
      onSendInput: (payload) {
        final msg = GameMessage(
          type: 'game.input',
          senderId: player.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: payload,
        );
        if (network.isHost) {
          ref.read(networkProvider.notifier).broadcast(msg);
        } else {
          ref.read(networkProvider.notifier).send(msg);
        }
      },
      onBroadcastState: (payload) {
        ref
            .read(networkProvider.notifier)
            .broadcast(
              GameMessage(
                type: 'game.state',
                senderId: player.id,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                payload: payload,
              ),
            );
      },
      onComplete: _onGameComplete,
    );

    _game = factory.create(gameContext);

    // Forward network messages to the game.
    _messageSub = ref.read(networkProvider.notifier).messages.listen((msg) {
      if (msg.type.startsWith('game.')) {
        _game?.onMessage(msg);
      }
      // Host ending the game
      if (msg.type == 'game.end') {
        _handleGameEnd(msg);
      }
    });
  }

  void _onGameComplete(GameResult result) {
    _stopwatch.stop();
    ref.read(sessionProvider.notifier).addResult(result);
    ref.read(roomProvider.notifier).setRoomState(RoomState.results);

    // Broadcast end to all players
    final network = ref.read(networkProvider);
    if (network.isHost) {
      ref
          .read(networkProvider.notifier)
          .broadcast(
            GameMessage(
              type: 'game.end',
              senderId: 'host',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              payload: result.toJson(),
            ),
          );
    }

    if (mounted) context.go(AppRoutes.results);
  }

  void _handleGameEnd(GameMessage msg) {
    final result = GameResult.fromJson(msg.payload);
    ref.read(sessionProvider.notifier).addResult(result);
    ref.read(roomProvider.notifier).setRoomState(RoomState.results);
    if (mounted) context.go(AppRoutes.results);
  }

  @override
  void dispose() {
    _game?.dispose();
    _messageSub?.cancel();
    _uiTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Game "${widget.gameId}" not found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    final meta = _game!.metadata;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header bar with game info and timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Text(meta.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    meta.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.neonLime,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_elapsedSeconds}s',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.neonLime),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Game widget
            Expanded(child: _game!.buildGameWidget(context)),
          ],
        ),
      ),
    );
  }
}
