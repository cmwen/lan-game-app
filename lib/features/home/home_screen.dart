import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../routing/app_router.dart';

/// Home screen with two big buttons: Host Game and Join Game.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(localPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMuted,
            ),
            tooltip: 'Settings',
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Title
              Text(
                    '🎮 Party Pocket',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.neonCyan,
                      shadows: [
                        Shadow(
                          color: AppColors.neonCyan.withAlpha(120),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.2, end: 0, duration: 400.ms),
              const SizedBox(height: 8),
              if (player != null)
                Text(
                  'Welcome, ${player.nickname}!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              const Spacer(flex: 2),
              // Host button
              SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (player == null) {
                          context.go(AppRoutes.nickname);
                        } else {
                          context.go(AppRoutes.host);
                        }
                      },
                      child: Text(
                        '🎮  Host Game',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, duration: 400.ms),
              const SizedBox(height: 20),
              // Join button
              SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonMagenta,
                        side: const BorderSide(
                          color: AppColors.neonMagenta,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (player == null) {
                          context.go(AppRoutes.nickname);
                        } else {
                          context.go(AppRoutes.join);
                        }
                      },
                      child: Text(
                        '🎯  Join Game',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.neonMagenta,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0, duration: 400.ms),
              const Spacer(flex: 3),
              // Settings / Change nickname
              TextButton(
                onPressed: () => context.go(AppRoutes.nickname),
                child: Text(
                  player == null ? 'Set Nickname' : 'Change Nickname',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
