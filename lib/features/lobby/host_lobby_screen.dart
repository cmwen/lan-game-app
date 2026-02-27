import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_room.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/settings_provider.dart';
import '../../routing/app_router.dart';

/// Host lobby — shows room code, QR, player list, and start button.
///
/// On mount the host:
///   1. Creates a [GameRoom] via [RoomNotifier]
///   2. Starts a [WebSocketGameServer] via [NetworkNotifier]
///   3. Broadcasts the room via [DiscoveryNotifier]
class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupHost();
  }

  Future<void> _setupHost() async {
    try {
      final player = ref.read(localPlayerProvider);
      if (player == null) {
        setState(() {
          _error = 'No player profile found';
          _initializing = false;
        });
        return;
      }

      // 1. Create room
      ref.read(roomProvider.notifier).createRoom(player);
      final room = ref.read(roomProvider);
      if (room == null) {
        setState(() {
          _error = 'Failed to create room';
          _initializing = false;
        });
        return;
      }

      // 2. Start WebSocket server
      final port = await ref.read(networkProvider.notifier).startServer();

      // 3. Start mDNS broadcast
      await ref
          .read(discoveryProvider.notifier)
          .startBroadcast(
            roomCode: room.code,
            hostName: player.nickname,
            port: port,
          );

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initializing = false;
        });
      }
    }
  }

  Future<void> _tearDown() async {
    await ref.read(discoveryProvider.notifier).stopBroadcast();
    await ref.read(networkProvider.notifier).disconnect();
    ref.read(roomProvider.notifier).leaveRoom();
  }

  void _startGame() {
    context.go(AppRoutes.gameSelect);
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final players = room?.players ?? [];
    final network = ref.watch(networkProvider);
    final isDev = ref.watch(settingsProvider).developerMode;

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Creating Room...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _tearDown();
                  context.go(AppRoutes.home);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final roomCode = room?.code ?? '----';
    final canStart = isDev ? players.isNotEmpty : players.length >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _tearDown();
          if (context.mounted) context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _tearDown();
              if (context.mounted) context.go(AppRoutes.home);
            },
          ),
          title: const Text('Host Lobby'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                if (isDev) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      '⚠️ Developer Mode — 1 player allowed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Room code
                Text(
                  'ROOM CODE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                      roomCode,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.neonCyan,
                        letterSpacing: 12,
                        shadows: [
                          Shadow(
                            color: AppColors.neonCyan.withAlpha(150),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                    ),
                const SizedBox(height: 16),
                // QR code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: roomCode,
                    version: QrVersions.auto,
                    size: 120,
                  ),
                ),
                const SizedBox(height: 8),
                // Manual connection info
                if (network.hostIp != null && network.port != null)
                  GestureDetector(
                    onTap: () {
                      final info = '${network.hostIp}:${network.port}';
                      Clipboard.setData(ClipboardData(text: info));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $info to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Manual connection info',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${network.hostIp} : ${network.port}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.neonCyan,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Player list header
                Row(
                  children: [
                    Text(
                      'Players (${players.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (!canStart)
                      Text(
                            'Waiting for players...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 800.ms),
                  ],
                ),
                const SizedBox(height: 8),
                // Player list
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
                // Start button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: canStart ? _startGame : null,
                    child: Text(
                      canStart
                          ? '🚀  Start Game'
                          : isDev
                          ? 'Waiting for host to join...'
                          : 'Need at least 2 players',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
