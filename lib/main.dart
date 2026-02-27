import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'games/game_registry.dart';
import 'games/hold_steady/hold_steady_game.dart';
import 'games/reaction/reaction_game.dart';
import 'games/shake_race/shake_race_game.dart';
import 'games/tap_frenzy/tap_frenzy_game.dart';
import 'games/tap_war/tap_war_game.dart';
import 'games/tilt_racer/tilt_racer_game.dart';
import 'providers/settings_provider.dart';
import 'routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register all available mini-games with the shell registry.
  _registerGames();

  runApp(const ProviderScope(child: PartyPocketApp()));
}

void _registerGames() {
  GameRegistry.register(ShakeRaceFactory());
  GameRegistry.register(TapWarFactory());
  GameRegistry.register(TapFrenzyFactory());
  GameRegistry.register(ReactionGameFactory());
  GameRegistry.register(HoldSteadyFactory());
  GameRegistry.register(TiltRacerFactory());
}

/// Root application widget — uses GoRouter for navigation.
class PartyPocketApp extends ConsumerStatefulWidget {
  const PartyPocketApp({super.key});

  @override
  ConsumerState<PartyPocketApp> createState() => _PartyPocketAppState();
}

class _PartyPocketAppState extends ConsumerState<PartyPocketApp> {
  @override
  void initState() {
    super.initState();
    ref.read(settingsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(ref);

    return MaterialApp.router(
      title: 'Party Pocket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
