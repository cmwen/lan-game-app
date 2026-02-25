import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/interfaces/discovery_service.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/network_provider.dart';
import '../../routing/app_router.dart';

/// Screen to join a game — enter a 4-letter code, or pick from discovered rooms.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.initialCode});

  /// If navigating to /join/:code, the code is passed here for auto-join.
  final String? initialCode;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Start mDNS discovery.
    ref.read(discoveryProvider.notifier).startDiscovery();

    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      // Auto-join after build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinByCode(widget.initialCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    ref.read(discoveryProvider.notifier).stopDiscovery();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    if (value.length == 4) {
      _joinByCode(value.toUpperCase());
    }
  }

  Future<void> _joinByCode(String code) async {
    // For manual code entry, we don't have host/port info.
    // In a real app, the code would be resolved via discovery or a signalling
    // server. For now, we check discovered rooms for a match.
    final rooms = ref.read(discoveryProvider);
    final match = rooms.where(
      (r) => r.roomCode.toUpperCase() == code.toUpperCase(),
    );
    if (match.isNotEmpty) {
      await _joinRoom(match.first);
    } else {
      setState(
        () => _error =
            'Room "$code" not found nearby. Make sure the host is on the same Wi-Fi.',
      );
    }
  }

  Future<void> _joinRoom(DiscoveredRoom room) async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await ref
          .read(networkProvider.notifier)
          .connectToHost(host: room.host, port: room.port);
      if (mounted) context.go(AppRoutes.lobby);
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Failed to connect: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveredRooms = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Join Game'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Code entry
              Text(
                'Enter Room Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  letterSpacing: 12,
                  color: AppColors.neonCyan,
                ),
                decoration: const InputDecoration(
                  hintText: '_ _ _ _',
                  counterText: '',
                ),
                onChanged: _onCodeChanged,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_joining)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              // Discovered rooms header
              Row(
                children: [
                  const Icon(Icons.wifi_find, color: AppColors.neonMagenta),
                  const SizedBox(width: 8),
                  Text(
                    'Nearby Games',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (discoveredRooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                            'Searching for games nearby...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 1000.ms),
                    ],
                  ),
                ),
              // Discovered room list
              Expanded(
                child: ListView.builder(
                  itemCount: discoveredRooms.length,
                  itemBuilder: (_, i) {
                    final room = discoveredRooms[i];
                    return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.neonMagenta.withAlpha(
                                40,
                              ),
                              child: const Text(
                                '🎮',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text('Room ${room.roomCode}'),
                            subtitle: Text(
                              '${room.hostName} • ${room.currentPlayers}/${room.maxPlayers} players',
                            ),
                            trailing: room.isFull
                                ? Chip(
                                    label: const Text('Full'),
                                    backgroundColor: AppColors.error.withAlpha(
                                      30,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                            onTap: room.isFull ? null : () => _joinRoom(room),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (100 * i).ms, duration: 300.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
