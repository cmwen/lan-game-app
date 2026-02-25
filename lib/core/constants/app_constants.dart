// Core app constants — network, timing, player limits
class AppConstants {
  AppConstants._();

  // Network
  static const String serviceType = '_partypocket._tcp';
  static const int defaultPort = 0; // let OS pick
  static const int heartbeatIntervalMs = 2000;
  static const int pongTimeoutMs = 3000;
  static const int maxMissedPongs = 2;
  static const int reconnectWindowMs = 30000;
  static const int reconnectRetryMs = 3000;

  // Room
  static const int roomCodeLength = 4;
  static const String safeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  // Timing
  static const int countdownSeconds = 3;

  // Players
  static const int minPlayers = 1;
  static const int maxPlayers = 8;

  // Game loop
  static const int gameLoopTargetFps = 60;
  static const int gameLoopIntervalMs = 1000 ~/ gameLoopTargetFps; // ~16ms

  // Scoring
  static const int baseScoreForWin = 10;
  static const int baseScoreForParticipation = 1;
}
