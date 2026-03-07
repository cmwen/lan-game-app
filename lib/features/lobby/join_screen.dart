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
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _joining = false;
  String? _error;
  String? _manualError;

  @override
  void initState() {
    super.initState();
    ref.read(discoveryProvider.notifier).startDiscovery();

    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInput(widget.initialCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _ipController.dispose();
    _portController.dispose();
    ref.read(discoveryProvider.notifier).stopDiscovery();
    super.dispose();
  }

  /// Parse input that may be a room code, `CODE@IP:PORT`, or `IP:PORT`.
  void _handleInput(String value) {
    // Format: CODE@IP:PORT (from QR code)
    final qrMatch = RegExp(
      r'^([A-Z0-9]{4})@(.+):(\d+)$',
    ).firstMatch(value.trim().toUpperCase());
    if (qrMatch != null) {
      final ip = value.trim().split('@')[1].split(':')[0]; // preserve case
      final port = int.tryParse(qrMatch.group(3)!);
      if (port != null) {
        _connectDirectly(ip, port);
        return;
      }
    }

    // Format: IP:PORT (manual paste)
    final ipPortMatch = RegExp(
      r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)$',
    ).firstMatch(value.trim());
    if (ipPortMatch != null) {
      final ip = ipPortMatch.group(1)!;
      final port = int.tryParse(ipPortMatch.group(2)!);
      if (port != null) {
        _connectDirectly(ip, port);
        return;
      }
    }

    // Plain 4-char room code
    if (value.length == 4) {
      _joinByCode(value.toUpperCase());
    }
  }

  void _onCodeChanged(String value) {
    _handleInput(value);
  }

  Future<void> _joinByCode(String code) async {
    final rooms = ref.read(discoveryProvider);
    final match = rooms.where(
      (r) => r.roomCode.toUpperCase() == code.toUpperCase(),
    );
    if (match.isNotEmpty) {
      await _joinRoom(match.first);
    } else {
      setState(
        () => _error =
            'Room "$code" not found nearby. Paste the full connection info '
            '(CODE@IP:PORT) from the host screen, or connect manually below.',
      );
    }
  }

  Future<void> _connectDirectly(String ip, int port) async {
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await ref
          .read(networkProvider.notifier)
          .connectToHost(host: ip, port: port);
      if (mounted) context.go(AppRoutes.lobby);
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Failed to connect to $ip:$port — $e';
        });
      }
    }
  }

  Future<void> _refreshDiscovery() async {
    await ref.read(discoveryProvider.notifier).stopDiscovery();
    await ref.read(discoveryProvider.notifier).startDiscovery();
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

  Future<void> _connectManually() async {
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();
    if (ip.isEmpty || portText.isEmpty) {
      setState(() => _manualError = 'Enter both IP address and port.');
      return;
    }
    final port = int.tryParse(portText);
    if (port == null) {
      setState(() => _manualError = 'Port must be a number.');
      return;
    }
    setState(() {
      _joining = true;
      _manualError = null;
    });
    try {
      await ref
          .read(networkProvider.notifier)
          .connectToHost(host: ip, port: port);
      if (mounted) context.go(AppRoutes.lobby);
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _manualError = 'Failed to connect: $e';
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
                'Enter Room Code or Connection Info',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  letterSpacing: 8,
                  color: AppColors.neonCyan,
                ),
                decoration: const InputDecoration(
                  hintText: 'CODE or CODE@IP:PORT',
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
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              // Discovered rooms header
              Row(
                children: [
                  const Icon(Icons.wifi_find, color: AppColors.neonMagenta),
                  const SizedBox(width: 8),
                  Text(
                    'Nearby Games',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                    tooltip: 'Refresh',
                    onPressed: _refreshDiscovery,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (discoveredRooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
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
                child: ListView(
                  children: [
                    ...List.generate(discoveredRooms.length, (i) {
                      final room = discoveredRooms[i];
                      return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.neonMagenta
                                    .withAlpha(40),
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
                                      backgroundColor: AppColors.error
                                          .withAlpha(30),
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
                    }),
                    // Manual connect expansion tile
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.lan_outlined,
                          color: AppColors.textMuted,
                        ),
                        title: Text(
                          'Connect Manually',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _ipController,
                                  decoration: const InputDecoration(
                                    labelText: 'IP Address',
                                    hintText: '192.168.1.x',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _portController,
                                  decoration: const InputDecoration(
                                    labelText: 'Port',
                                    hintText: '12345',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                if (_manualError != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _manualError!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _joining ? null : _connectManually,
                                  child: const Text('Connect'),
                                ),
                              ],
                            ),
                          ),
                        ],
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
