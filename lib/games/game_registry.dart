import 'mini_game_interface.dart';

/// Central registry of all available mini-games.
///
/// The app shell uses [GameRegistry] to list games and launch them.
/// It never imports game implementations directly — only through this registry.
///
/// To add a new game:
///   1. Create your game folder under `lib/games/your_game/`
///   2. Implement [MiniGame] and [MiniGameFactory]
///   3. Call `GameRegistry.register(YourGameFactory())` in `main()`.
class GameRegistry {
  GameRegistry._();

  static final Map<String, MiniGameFactory> _registry = {};

  /// Register a game factory under its unique [id].
  static void register(MiniGameFactory factory) {
    assert(
      !_registry.containsKey(factory.metadata.id),
      'Game "${factory.metadata.id}" is already registered.',
    );
    _registry[factory.metadata.id] = factory;
  }

  /// Look up a factory by game ID. Returns null if not found.
  static MiniGameFactory? get(String id) => _registry[id];

  /// All registered game metadata, sorted by title.
  static List<GameMetadata> get allMetadata {
    return _registry.values.map((f) => f.metadata).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  /// Whether a game with [id] is registered.
  static bool has(String id) => _registry.containsKey(id);

  /// Create a [MiniGame] instance for the given [gameId] using [context].
  ///
  /// Returns `null` if the game is not registered.
  static MiniGame? createGame(String gameId, GameContext context) {
    final factory = _registry[gameId];
    return factory?.create(context);
  }
}
