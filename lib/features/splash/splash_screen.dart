import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../routing/app_router.dart';

/// Full-screen splash with animated "Party Pocket" neon title.
/// Auto-navigates to /home after 1.5 seconds.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji logo
            const Text('🎉', style: TextStyle(fontSize: 72)).animate().scale(
              begin: const Offset(0.3, 0.3),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 16),
            // Title with neon glow
            Text(
                  'Party Pocket',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.neonCyan,
                    shadows: [
                      Shadow(
                        color: AppColors.neonCyan.withAlpha(180),
                        blurRadius: 30,
                      ),
                      Shadow(
                        color: AppColors.neonMagenta.withAlpha(100),
                        blurRadius: 60,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),
            const SizedBox(height: 12),
            Text(
              'LAN Party Games',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
