import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/game_message.dart';
import '../../providers/network_provider.dart';
import '../../providers/room_provider.dart';
import '../../routing/app_router.dart';

/// Full-screen animated countdown: 3… 2… 1… GO!
/// Auto-navigates to the play screen when finished.
class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_count > 1) {
        setState(() => _count--);
      } else {
        _timer?.cancel();
        _onCountdownDone();
      }
    });
  }

  void _onCountdownDone() {
    final room = ref.read(roomProvider);
    final gameId = room?.currentGameId;

    // Host broadcasts game.start
    final network = ref.read(networkProvider);
    if (network.isHost) {
      ref
          .read(networkProvider.notifier)
          .broadcast(
            GameMessage(
              type: 'game.start',
              senderId: 'host',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              payload: {'gameId': gameId ?? ''},
            ),
          );
    }

    if (mounted && gameId != null) {
      context.go('${AppRoutes.play}/$gameId');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _count > 0 ? '$_count' : 'GO!';
    final color = _count > 0 ? AppColors.neonCyan : AppColors.neonLime;

    return Scaffold(
      body: Center(
        // Use a unique key so flutter_animate replays on each value change.
        child:
            Text(
                  label,
                  key: ValueKey(label),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 120,
                    color: color,
                    shadows: [
                      Shadow(color: color.withAlpha(180), blurRadius: 40),
                      Shadow(color: color.withAlpha(100), blurRadius: 80),
                    ],
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(2.5, 2.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: 300.ms),
      ),
    );
  }
}
