import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/countdown/countdown_screen.dart';
import '../features/game/play_screen.dart';
import '../features/game_select/game_select_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lobby/guest_lobby_screen.dart';
import '../features/lobby/host_lobby_screen.dart';
import '../features/lobby/join_screen.dart';
import '../features/nickname/nickname_screen.dart';
import '../features/results/results_screen.dart';
import '../features/scoreboard/scoreboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers/player_provider.dart';

/// Named route constants for type-safe navigation.
class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const nickname = '/nickname';
  static const host = '/host';
  static const join = '/join';
  static const lobby = '/lobby';
  static const gameSelect = '/game-select';
  static const countdown = '/countdown';
  static const play = '/play';
  static const results = '/results';
  static const scoreboard = '/scoreboard';
  static const settings = '/settings';
}

/// Creates the [GoRouter] using Riverpod [ref] for redirect logic.
GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final player = ref.read(localPlayerProvider);
      final hasNickname = player != null && player.nickname.isNotEmpty;
      final location = state.matchedLocation;

      // Allow splash, nickname, and settings without a profile.
      if (location == AppRoutes.splash ||
          location == AppRoutes.nickname ||
          location == AppRoutes.settings) {
        return null;
      }

      // Redirect to nickname screen if profile is not yet set.
      if (!hasNickname && location != AppRoutes.nickname) {
        return AppRoutes.nickname;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.nickname,
        builder: (context, state) => const NicknameScreen(),
      ),
      GoRoute(
        path: AppRoutes.host,
        builder: (context, state) => const HostLobbyScreen(),
      ),
      GoRoute(
        path: AppRoutes.join,
        builder: (context, state) => const JoinScreen(),
        routes: [
          GoRoute(
            path: ':code',
            builder: (context, state) =>
                JoinScreen(initialCode: state.pathParameters['code']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (context, state) => const GuestLobbyScreen(),
      ),
      GoRoute(
        path: AppRoutes.gameSelect,
        builder: (context, state) => const GameSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.countdown,
        builder: (context, state) => const CountdownScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.play}/:gameId',
        builder: (context, state) =>
            PlayScreen(gameId: state.pathParameters['gameId']!),
      ),
      GoRoute(
        path: AppRoutes.results,
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.scoreboard,
        builder: (context, state) => const ScoreboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
