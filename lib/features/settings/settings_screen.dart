import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../routing/app_router.dart';
import '../../services/network/websocket_game_server.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final ip = await WebSocketGameServer.getLocalIpAddress();
    if (mounted) setState(() => _localIp = ip);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDev = settings.developerMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Developer Mode toggle
            Card(
              child: SwitchListTile(
                title: const Text('Developer Mode'),
                subtitle: Text(
                  isDev
                      ? 'Allows testing with 1 player on a single device'
                      : 'Enable for single-device testing',
                  style: TextStyle(
                    color: isDev ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
                value: isDev,
                activeThumbColor: AppColors.neonCyan,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setDeveloperMode(v),
              ),
            ),
            const SizedBox(height: 16),
            // Network diagnostics card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wifi,
                          color: AppColors.neonCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Network Diagnostics',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Device IP: ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          _localIp ?? 'Loading...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.neonCyan,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // mDNS info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'mDNS Auto-Discovery',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'mDNS may not work on some home WiFi routers that block '
                      'multicast traffic between clients. If auto-discovery '
                      "fails, use the IP:port shown on the host's screen to "
                      'connect manually.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
