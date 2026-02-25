# LAN Party Game App — System Architecture

**Status**: Proposed  
**Last Updated**: 2025  
**Target Platform**: Android (Flutter 3.x / Dart 3.x)  
**Scope**: 1–8 players, same WiFi, local-first, no internet required

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [P2P Networking Layer](#2-p2p-networking-layer)
3. [App Shell Architecture](#3-app-shell-architecture)
4. [Mini-Game Framework](#4-mini-game-framework)
5. [State Management](#5-state-management)
6. [Key Technical Decisions](#6-key-technical-decisions)
7. [Package Recommendations](#7-package-recommendations)
8. [Folder Structure](#8-folder-structure)
9. [Data Flow Diagrams](#9-data-flow-diagrams)
10. [Architectural Decision Records](#10-architectural-decision-records)

---

## 1. Architecture Overview

### Pattern: Feature-Scoped Clean Architecture + Riverpod

Pure "Clean Architecture" (full domain/data/presentation triplication) is too heavy for a party game. Instead, we use a **pragmatic hybrid**:

- **Feature Modules** — each feature (lobby, game shell, each mini-game) is a self-contained folder
- **Clean layers within networking** — a proper Repository + DataSource split where the network complexity demands it
- **Riverpod everywhere** for state — no raw `setState`, no BLoC boilerplate
- **Shared contracts** — abstract interfaces define the boundary between the app shell and mini-games

```
┌──────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                   │
│  GoRouter  │  Screens  │  Widgets  │  Riverpod UI     │
├──────────────────────────────────────────────────────┤
│                  APPLICATION LAYER                    │
│  GameOrchestrator │ LobbyController │ GameRegistry    │
├──────────────────────────────────────────────────────┤
│                   DOMAIN LAYER                        │
│  Entities: Room, Player, GameMessage, GameResult      │
│  Interfaces: MiniGame, NetworkTransport               │
├──────────────────────────────────────────────────────┤
│                    DATA LAYER                         │
│  NetworkService (WebSocket) │ DiscoveryService (mDNS) │
│  StorageService (prefs)     │ SensorService           │
└──────────────────────────────────────────────────────┘
```

### Why Not BLoC?
BLoC excels at complex event-driven flows with strict separation, but the overhead of Events/States/Blocs for every small interaction in a party game is costly. Riverpod's `Notifier` + `AsyncNotifier` provides the same rigor with less ceremony, better compile-time safety, and excellent testability.

### Why Not GetX?
GetX couples routing, DI, and state into one opinionated framework, creating hidden dependencies. For a multi-developer team adding new mini-games, explicit contracts via Riverpod + GoRouter are safer.

---

## 2. P2P Networking Layer

### Protocol Stack

```
┌───────────────────┐
│   Game Messages   │  JSON-encoded GameMessage structs
├───────────────────┤
│    WebSocket      │  Full-duplex, low-latency on LAN (~1–3ms)
├───────────────────┤
│    TCP / HTTP     │  dart:io HttpServer on Host
├───────────────────┤
│   WiFi / LAN      │  Same AP, no internet needed
└───────────────────┘

Discovery layer (separate):
┌───────────────────┐
│     Bonsoir       │  mDNS / NSD  (zero-config service discovery)
└───────────────────┘
```

### Why WebSocket over UDP?
| Concern | WebSocket (TCP) | UDP |
|---|---|---|
| Reliability | Built-in retransmit | Manual ACK needed |
| LAN latency | ~1–5ms — acceptable for party games | ~0.5–2ms |
| Complexity | Simple dart:io HttpServer | Custom socket + framing |
| Ordered delivery | Yes | Must implement sequence numbers |
| Flutter support | `web_socket_channel` (official) | `dart:io` RawDatagramSocket (low-level) |

**Verdict**: WebSocket is the right call. Sub-5ms round-trip on LAN is imperceptible for party games (not twitch shooters). UDP is only worth it if benchmarks prove otherwise — that's a future optimisation.

### Host/Client Model

```
HOST DEVICE                          CLIENT DEVICES
──────────────                       ──────────────
1. Start WS Server (:4242)
2. Broadcast via Bonsoir ──mDNS──►  3. Discover via Bonsoir
                                     4. Connect WebSocket
5. Accept connection, assign ID ◄──  5. Send JoinRequest
6. Maintain player registry
7. Broadcast game state ──WS──────►  8. Render from state
8. Receive inputs ◄────WS──────────  7. Send inputs
```

**Host is authoritative**: All game state lives on the host. Clients are "thin" — they send inputs and render state. This avoids conflict resolution entirely.

### NetworkTransport Interface

```dart
/// Abstract transport — swap WebSocket for bluetooth/nearby later
abstract interface class NetworkTransport {
  Stream<GameMessage> get incomingMessages;
  Future<void> send(GameMessage message);
  Future<void> close();
}

/// Host-side: manages N client connections
abstract interface class GameServer {
  Future<void> start({required int port});
  Stream<PlayerConnection> get playerConnections;
  Stream<GameMessage> get allMessages;
  Future<void> broadcast(GameMessage message);
  Future<void> sendTo(String playerId, GameMessage message);
  Future<void> stop();
}

/// Client-side: single connection to host
abstract interface class GameClient {
  Future<void> connect({required String host, required int port});
  Stream<GameMessage> get messages;
  Future<void> send(GameMessage message);
  Future<void> disconnect();
}
```

### Message Protocol

Every message over the wire is a `GameMessage`:

```dart
@freezed
class GameMessage with _$GameMessage {
  const factory GameMessage({
    required String type,          // e.g. 'lobby.playerJoined', 'game.stateUpdate'
    required String fromPlayerId,
    String? toPlayerId,            // null = broadcast
    required int timestampMs,
    required Map<String, dynamic> payload,
  }) = _GameMessage;

  factory GameMessage.fromJson(Map<String, dynamic> json) =>
      _$GameMessageFromJson(json);
}
```

**Message type naming convention**: `<domain>.<action>`  
Examples: `lobby.join`, `lobby.playerReady`, `lobby.startGame`,  
`game.stateUpdate`, `game.input`, `game.end`, `system.ping`, `system.pong`

### Service Discovery Flow

```dart
// HOST: Broadcast the game room via mDNS
final service = BonsoirService(
  name: 'PartyGame-${roomCode}',     // human-readable room name
  type: '_partygame._tcp',
  port: 4242,
  attributes: {
    'hostName': playerName,
    'gameVersion': '1.0.0',
    'maxPlayers': '8',
    'currentPlayers': '1',
  },
);
final broadcast = BonsoirBroadcast(service: service);
await broadcast.initialize();
await broadcast.start();

// CLIENT: Discover rooms on local network
final discovery = BonsoirDiscovery(type: '_partygame._tcp');
await discovery.initialize();
discovery.eventStream!.listen((event) {
  if (event is BonsoirDiscoveryServiceResolvedEvent) {
    // event.service.host  = IP address
    // event.service.port  = WebSocket port
    // event.service.attributes = room metadata
  }
});
await discovery.start();
```

### Disconnection Handling

```
Strategy: Heartbeat + Graceful Degradation

Host: pings all clients every 2 seconds (system.ping)
Client: must respond with system.pong within 3 seconds
         
If client misses 2 consecutive pongs:
  → Mark player as DISCONNECTED
  → Notify remaining players
  → If in lobby: remove player slot
  → If in game: AI fills in (no-op) or game pauses with 5s rejoin window

If HOST disconnects:
  → Detect via WebSocket onDone / onError
  → Show "Host lost" dialog
  → Offer: "Try to rejoin" (30s window) or "Return to menu"
  → One client can be promoted to host (reconnect all to new host)
```

### Latency Budget for Real-Time Games

```
WiFi LAN round-trip:      ~2–5ms
Dart WebSocket overhead:  ~1–2ms  
Riverpod state update:    ~1ms
Flutter frame budget:     16ms (60fps)
─────────────────────────────────
Available for game logic: ~8–10ms per frame  ✓
```

For games with tight timing (button mashing, reaction time):
- Timestamp all inputs with `DateTime.now().millisecondsSinceEpoch`
- Host adjudicates with a **±50ms tolerance window**
- Display results with client-reported timestamps, host-verified order

---

## 3. App Shell Architecture

### Navigation Structure (GoRouter)

```
/ (AppShell — ShellRoute, persistent bottom nav)
├── /home             HomeScreen       (game browser / featured)
├── /host             HostSetupScreen  (create room)
├── /join             JoinScreen       (scan/browse rooms)  
├── /lobby/:roomCode  LobbyScreen      (waiting room)
│   └── /lobby/:roomCode/settings  LobbySettingsScreen
├── /game/:gameId     GameShellScreen  (active mini-game)
│   └── /game/:gameId/results  ResultsScreen
├── /scores           ScoreboardScreen (session totals)
└── /settings         SettingsScreen
```

```dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/host', builder: (_, __) => const HostSetupScreen()),
        GoRoute(path: '/join', builder: (_, __) => const JoinScreen()),
        GoRoute(
          path: '/lobby/:roomCode',
          builder: (_, state) => LobbyScreen(
            roomCode: state.pathParameters['roomCode']!,
          ),
        ),
        GoRoute(
          path: '/game/:gameId',
          builder: (_, state) => GameShellScreen(
            gameId: state.pathParameters['gameId']!,
          ),
        ),
        GoRoute(path: '/scores', builder: (_, __) => const ScoreboardScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
```

### Lobby / Room System

```
Room Entity
──────────────────────────────────────────
roomCode:       String (6-char, e.g. "XQRT42")
hostPlayerId:   String
players:        List<Player>
status:         RoomStatus (waiting|countdown|inGame|results)
selectedGameId: String?
settings:       RoomSettings (maxPlayers, allowSpectators, etc.)

Player Entity
──────────────────────────────────────────
id:             String (UUID)
name:           String
avatarIndex:    int
isHost:         bool
isReady:        bool
connectionStatus: ConnectionStatus (connected|reconnecting|disconnected)
score:          int  (session total)
```

**Lobby state machine**:
```
WAITING ──[all ready]──► COUNTDOWN (3s) ──► IN_GAME ──► RESULTS ──► WAITING
                              │                  │
                         [host cancels]    [host picks next]
                              ▼
                           WAITING
```

### Mini-Game Plugin/Registry System

Games are registered at app startup. Adding a new game = implementing the `MiniGame` interface + registering it. No changes to shell code.

```dart
// Shell discovers games through the registry — never imports them directly
class GameRegistry {
  static final Map<String, MiniGameFactory> _games = {};

  static void register(String id, MiniGameFactory factory) {
    _games[id] = factory;
  }

  static MiniGameFactory? get(String id) => _games[id];
  static List<GameMetadata> get allGames =>
      _games.values.map((f) => f.metadata).toList();
}

// Register all games at app startup (in main.dart or app.dart)
void registerGames() {
  GameRegistry.register('shake_race',    ShakeRaceGame.factory);
  GameRegistry.register('tap_war',       TapWarGame.factory);
  GameRegistry.register('tilt_maze',     TiltMazeGame.factory);
  GameRegistry.register('quick_draw',    QuickDrawGame.factory);
}
```

---

## 4. Mini-Game Framework

### MiniGame Contract (Abstract Interface)

Every mini-game **must** implement this interface. The shell calls these methods — games never reach into shell internals.

```dart
/// Immutable metadata — used in game browser, lobby selector
class GameMetadata {
  final String id;              // 'shake_race'
  final String title;           // 'Shake Race'
  final String description;     // '...first to 100 shakes wins!'
  final String iconAsset;       // 'assets/icons/shake_race.png'
  final int minPlayers;         // 2
  final int maxPlayers;         // 8
  final Duration estimatedDuration; // Duration(seconds: 45)
  final List<HardwareRequirement> hardware; // [HardwareRequirement.accelerometer]
  final GameDifficulty difficulty;
}

/// The live game context injected by the shell
abstract interface class GameContext {
  String get localPlayerId;
  List<Player> get players;
  bool get isHost;

  // Networking — games use these, never raw WebSocket
  Future<void> broadcastInput(Map<String, dynamic> input);
  Future<void> broadcastStateUpdate(Map<String, dynamic> state); // host only
  Stream<GameMessage> get gameMessages;

  // Shell callbacks
  void onGameComplete(GameResult result);
  void onGameError(String message);
}

/// Factory for creating a game instance  
abstract interface class MiniGameFactory {
  GameMetadata get metadata;
  MiniGame create(GameContext context);
}

/// The game itself
abstract interface class MiniGame {
  /// Called once when game screen is pushed
  Future<void> initialize();

  /// The game's root widget — fills the game screen
  Widget buildUI();

  /// Host only: tick is called every ~16ms by the shell game loop
  /// Return updated game state to broadcast, or null if no update needed
  Map<String, dynamic>? hostTick(Duration elapsed);

  /// Called when game is popped (cleanup: cancel timers, sensors, etc.)
  Future<void> dispose();
}
```

### Game Result & Score Feed-Back

```dart
@freezed
class GameResult with _$GameResult {
  const factory GameResult({
    required String gameId,
    required DateTime completedAt,
    required List<PlayerResult> playerResults,
    Map<String, dynamic>? gameSpecificData, // leaderboard, stats, etc.
  }) = _GameResult;
}

@freezed
class PlayerResult with _$PlayerResult {
  const factory PlayerResult({
    required String playerId,
    required int rank,           // 1 = winner
    required int scoreEarned,    // points added this round
    String? label,               // "Fastest!", "Most shakes"
  }) = _PlayerResult;
}
```

**Score flow**: `game.onGameComplete(result)` → `GameOrchestrator` updates session `PlayerScore` totals in `SessionNotifier` → Shell navigates to `/game/:id/results` → shows podium → host picks next game → back to lobby.

### Example Mini-Game Implementation

```dart
class ShakeRaceGame implements MiniGame {
  final GameContext _ctx;
  StreamSubscription? _accelSub;
  StreamSubscription? _messageSub;
  final Map<String, int> _shakeCounts = {};
  static const int _targetShakes = 100;

  ShakeRaceGame(this._ctx);

  @override
  Future<void> initialize() async {
    for (final p in _ctx.players) _shakeCounts[p.id] = 0;

    // Local player listens to accelerometer
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 20.0) {
        _ctx.broadcastInput({'type': 'shake', 'playerId': _ctx.localPlayerId});
      }
    });

    // Host and clients both listen for shake inputs
    _messageSub = _ctx.gameMessages.listen(_onMessage);
  }

  void _onMessage(GameMessage msg) {
    if (msg.payload['type'] == 'shake') {
      final pid = msg.payload['playerId'] as String;
      _shakeCounts[pid] = (_shakeCounts[pid] ?? 0) + 1;
      if (_ctx.isHost && _shakeCounts[pid]! >= _targetShakes) {
        _endGame(winnerId: pid);
      }
    }
  }

  void _endGame({required String winnerId}) {
    final sorted = _shakeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final results = sorted.indexed.map((entry) {
      final (rank, kv) = entry;
      return PlayerResult(
        playerId: kv.key,
        rank: rank + 1,
        scoreEarned: _ctx.players.length - rank,
      );
    }).toList();
    _ctx.onGameComplete(GameResult(
      gameId: 'shake_race',
      completedAt: DateTime.now(),
      playerResults: results,
    ));
  }

  @override
  Widget buildUI() => ShakeRaceScreen(shakeCounts: _shakeCounts);

  @override
  Map<String, dynamic>? hostTick(Duration elapsed) => null; // event-driven, no tick needed

  @override
  Future<void> dispose() async {
    await _accelSub?.cancel();
    await _messageSub?.cancel();
  }

  static MiniGameFactory get factory => _ShakeRaceFactory();
}
```

---

## 5. State Management

### Riverpod Provider Hierarchy

```
ProviderScope (root)
│
├── localPlayerProvider          — Player (from SharedPreferences: name, avatar)
├── networkServerProvider        — GameServer? (null when client)  
├── networkClientProvider        — GameClient? (null when host)
│
├── roomProvider                 — Room? (current room state)
├── sessionNotifierProvider      — SessionState (session scores, game history)
│
├── discoveryProvider            — List<DiscoveredRoom> (scan results)
│
└── activeGameProvider           — MiniGame? (currently running game)
```

**Key Notifiers**:

```dart
// Room state — synchronized from network messages
@riverpod
class RoomNotifier extends _$RoomNotifier {
  @override
  Room? build() => null;

  void applyMessage(GameMessage message) {
    switch (message.type) {
      case 'lobby.roomState':
        state = Room.fromJson(message.payload);
      case 'lobby.playerJoined':
        state = state?.copyWith(
          players: [...state!.players, Player.fromJson(message.payload)],
        );
      case 'lobby.playerLeft':
        state = state?.copyWith(
          players: state!.players
              .where((p) => p.id != message.payload['playerId'])
              .toList(),
        );
      // ... etc
    }
  }
}

// Session scores — persisted across mini-games
@riverpod
class SessionNotifier extends _$SessionNotifier {
  @override
  SessionState build() => SessionState.empty();

  void applyGameResult(GameResult result) {
    final updated = Map<String, int>.from(state.scores);
    for (final pr in result.playerResults) {
      updated[pr.playerId] = (updated[pr.playerId] ?? 0) + pr.scoreEarned;
    }
    state = state.copyWith(
      scores: updated,
      completedGames: [...state.completedGames, result],
    );
  }
}
```

### State Update Flow (Host-Authoritative)

```
CLIENT                         HOST
──────                         ────
User action
   │
[GameMessage: input] ─────────►
                               Apply to game state
                               Run game logic
                               ◄───── [GameMessage: stateUpdate] (broadcast)
Riverpod state updated
Widget rebuilds
```

---

## 6. Key Technical Decisions

### Decision 1: Data Serialization — `freezed` + `json_serializable`

All game entities use `freezed` for:
- Immutable value objects with `copyWith`
- Pattern matching on sealed classes (message types)
- Auto-generated `==` and `hashCode`
- `json_serializable` for network serialization

```dart
@freezed
sealed class LobbyEvent with _$LobbyEvent {
  const factory LobbyEvent.playerJoined(Player player) = PlayerJoined;
  const factory LobbyEvent.playerLeft(String playerId) = PlayerLeft;
  const factory LobbyEvent.gameStarting(String gameId) = GameStarting;
}

// Pattern match in UI:
switch (event) {
  case PlayerJoined(:final player) => showJoinToast(player.name),
  case PlayerLeft(:final playerId) => removePlayerCard(playerId),
  case GameStarting(:final gameId) => navigateToGame(gameId),
}
```

### Decision 2: Dependency Injection — `get_it`

`get_it` as service locator for singleton services (NetworkServer, NetworkClient, StorageService). Riverpod providers depend on `get_it` singletons, keeping providers lean.

```dart
final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  getIt.registerLazySingleton<GameServer>(() => WebSocketGameServer());
  getIt.registerLazySingleton<GameClient>(() => WebSocketGameClient());
  getIt.registerLazySingleton<DiscoveryService>(() => BonsoirDiscoveryService());
  getIt.registerLazySingleton<SensorService>(() => SensorServiceImpl());
}
```

### Decision 3: Host/Client Role — Determined at Runtime

A single app build handles both roles. The player who taps "Host Game" becomes the server; everyone else is a client. Host gets extra responsibilities but no separate code path — the `isHost` flag on the `GameContext` gates host-only behaviour.

### Decision 4: WebSocket Server Port — Dynamic with mDNS Advertisement

Do **not** hardcode port 4242 in release. Host picks a random available port, advertises it via Bonsoir attributes. Clients read the port from the discovered service — no manual IP entry.

### Decision 5: Disconnection Recovery

```
Host disconnects → 30-second rejoin window
  → All clients show "Reconnecting..." spinner
  → Auto-retry WebSocket connect every 3 seconds
  → If host returns: resume from last broadcast state
  → After 30s timeout: promote lowest-ID connected client to host

Client disconnects mid-game:
  → Host marks player GHOST (greyed out in UI)
  → Their inputs are ignored
  → Scoring: they receive 0 for that round
  → Can rejoin in lobby for next round
```

### Decision 6: Game Loop for Host

The shell runs a simple game loop only on the host:

```dart
class GameLoopController {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final MiniGame _game;
  final GameContext _ctx;
  
  void start() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      _elapsed += const Duration(milliseconds: 16);
      final update = _game.hostTick(_elapsed);
      if (update != null) {
        _ctx.broadcastStateUpdate(update);
      }
    });
  }
  
  void stop() => _timer?.cancel();
}
```

---

## 7. Package Recommendations

### Core Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `^2.6.x` | State management |
| `riverpod_annotation` | `^2.6.x` | Code generation for providers |
| `go_router` | `^14.x` | Declarative navigation |
| `freezed` | `^2.5.x` | Immutable data classes |
| `freezed_annotation` | `^2.4.x` | Annotations for freezed |
| `json_serializable` | `^6.8.x` | JSON serialization |
| `get_it` | `^8.x` | Dependency injection / service locator |

### Networking

| Package | Version | Purpose |
|---|---|---|
| `bonsoir` | `^6.x` | mDNS/NSD service discovery (find rooms on LAN) |
| `web_socket_channel` | `^3.x` | WebSocket client (players connect to host) |
| `dart:io` `HttpServer` | built-in | WebSocket server on host device |
| `uuid` | `^4.x` | Generate player IDs and room codes |

### Device Hardware

| Package | Version | Purpose |
|---|---|---|
| `sensors_plus` | `^6.x` | Accelerometer, gyroscope (shake, tilt games) |
| `vibration` | `^2.x` | Haptic feedback (win/lose feedback) |
| `camera` | `^0.11.x` | Camera-based games (optional) |
| `permission_handler` | `^11.x` | Runtime permissions (microphone, camera) |

### Audio & Visual

| Package | Version | Purpose |
|---|---|---|
| `audioplayers` | `^6.x` | Sound effects, background music |
| `lottie` | `^3.x` | Animated celebrations/icons |
| `flutter_animate` | `^4.x` | Micro-animations, screen transitions |

### Game Engine (for physics-heavy mini-games)

| Package | Version | Purpose |
|---|---|---|
| `flame` | `^1.x` | 2D game engine (only for games needing it) |

> **Note on Flame**: Don't use Flame as the entire app's framework. Use it only within specific mini-game widgets that need physics, sprite rendering, or a tight game loop. The app shell stays pure Flutter.

### Storage & Persistence

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | `^2.5.x` | Player name, avatar, settings |
| `path_provider` | `^2.1.x` | File paths (if saving replays) |

### Developer Experience

| Package | Version | Purpose |
|---|---|---|
| `build_runner` | `^2.4.x` | Code generation (freezed, riverpod_annotation) |
| `flutter_lints` | `^6.x` | Lint rules |
| `mocktail` | `^1.x` | Mocking for tests |

### Minimum `pubspec.yaml` additions

```yaml
dependencies:
  # State
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Navigation
  go_router: ^14.3.0
  
  # Data
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # DI
  get_it: ^8.0.3
  
  # Networking
  bonsoir: ^6.1.1
  web_socket_channel: ^3.0.1
  uuid: ^4.5.1
  
  # Hardware
  sensors_plus: ^6.1.0
  vibration: ^2.1.0
  permission_handler: ^11.3.1
  
  # UI & Audio
  audioplayers: ^6.1.0
  lottie: ^3.1.3
  flutter_animate: ^4.5.2

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.3
  flutter_lints: ^6.0.0
  mocktail: ^1.0.4
```

---

## 8. Folder Structure

```
lib/
├── main.dart                         # Entry point: setup DI, register games, run app
├── app.dart                          # MaterialApp.router + ProviderScope root
│
├── core/                             # Framework-level shared code
│   ├── constants/
│   │   ├── app_constants.dart        # Port range, timeouts, max players
│   │   └── game_constants.dart       # Service type string, room code length
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData (dark party-game aesthetic)
│   │   ├── app_colors.dart
│   │   └── app_typography.dart
│   ├── utils/
│   │   ├── room_code_generator.dart  # 6-char alphanumeric codes
│   │   └── network_utils.dart        # Get local IP address helper
│   └── extensions/
│       └── context_extensions.dart
│
├── domain/                           # Pure Dart — no Flutter imports
│   ├── entities/
│   │   ├── player.dart               # @freezed Player entity
│   │   ├── room.dart                 # @freezed Room entity
│   │   ├── game_message.dart         # @freezed wire message
│   │   ├── game_result.dart          # @freezed result + PlayerResult
│   │   └── session_state.dart        # @freezed session-wide score state
│   └── interfaces/
│       ├── network_transport.dart    # abstract interface NetworkTransport
│       ├── game_server.dart          # abstract interface GameServer
│       ├── game_client.dart          # abstract interface GameClient
│       └── discovery_service.dart   # abstract interface DiscoveryService
│
├── services/                         # Concrete service implementations
│   ├── network/
│   │   ├── websocket_game_server.dart  # dart:io HttpServer + WebSocket
│   │   ├── websocket_game_client.dart  # web_socket_channel client
│   │   └── message_codec.dart          # JSON encode/decode GameMessage
│   ├── discovery/
│   │   └── bonsoir_discovery_service.dart
│   ├── storage/
│   │   └── shared_prefs_storage.dart
│   └── sensors/
│       └── sensor_service.dart       # sensors_plus wrapper
│
├── features/
│   │
│   ├── home/                         # Game browser / main menu
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       ├── game_card.dart
│   │       └── featured_game_banner.dart
│   │
│   ├── lobby/                        # Host setup + player waiting room
│   │   ├── providers/
│   │   │   ├── room_notifier.dart         # @riverpod RoomNotifier
│   │   │   └── discovery_notifier.dart    # @riverpod DiscoveryNotifier
│   │   ├── host_setup_screen.dart
│   │   ├── join_screen.dart
│   │   ├── lobby_screen.dart
│   │   └── widgets/
│   │       ├── player_card.dart
│   │       ├── room_code_display.dart
│   │       ├── game_selector.dart
│   │       └── ready_button.dart
│   │
│   ├── game_shell/                   # Orchestrates active mini-game
│   │   ├── providers/
│   │   │   ├── active_game_notifier.dart  # @riverpod ActiveGameNotifier
│   │   │   └── session_notifier.dart      # @riverpod SessionNotifier
│   │   ├── game_shell_screen.dart         # Hosts game widget + HUD
│   │   ├── game_context_impl.dart         # Implements GameContext interface
│   │   ├── game_loop_controller.dart      # Host-only 60Hz tick timer
│   │   └── widgets/
│   │       ├── game_hud.dart              # Score overlay during game
│   │       └── countdown_overlay.dart     # 3-2-1 start animation
│   │
│   ├── results/                      # Post-game results screen
│   │   ├── results_screen.dart
│   │   └── widgets/
│   │       ├── podium_widget.dart
│   │       └── score_delta_card.dart
│   │
│   ├── scoreboard/                   # Session-wide leaderboard
│   │   └── scoreboard_screen.dart
│   │
│   └── settings/
│       └── settings_screen.dart
│
├── games/                            # Mini-game modules
│   ├── game_registry.dart            # GameRegistry + registerGames()
│   ├── mini_game_interface.dart      # MiniGame, MiniGameFactory, GameContext, GameMetadata
│   │
│   ├── shake_race/
│   │   ├── shake_race_game.dart      # Implements MiniGame
│   │   ├── shake_race_factory.dart   # Implements MiniGameFactory
│   │   └── shake_race_screen.dart    # Game UI widget
│   │
│   ├── tap_war/
│   │   ├── tap_war_game.dart
│   │   ├── tap_war_factory.dart
│   │   └── tap_war_screen.dart
│   │
│   ├── tilt_maze/
│   │   ├── tilt_maze_game.dart
│   │   └── tilt_maze_screen.dart     # Uses Flame for physics
│   │
│   └── quick_draw/
│       ├── quick_draw_game.dart
│       └── quick_draw_screen.dart
│
└── shared/                           # Shared UI components
    ├── widgets/
    │   ├── player_avatar.dart
    │   ├── neon_button.dart
    │   ├── loading_spinner.dart
    │   └── error_dialog.dart
    └── animations/
        └── celebration_overlay.dart

test/
├── unit/
│   ├── domain/
│   │   └── room_test.dart
│   ├── services/
│   │   ├── websocket_server_test.dart
│   │   └── bonsoir_discovery_test.dart
│   └── games/
│       └── shake_race_game_test.dart
├── widget/
│   ├── lobby/
│   │   └── lobby_screen_test.dart
│   └── games/
│       └── shake_race_screen_test.dart
└── integration/
    └── full_game_flow_test.dart      # 2-device emulator integration test

assets/
├── icons/                            # Game icons (PNG)
├── audio/
│   ├── sfx/                          # Sound effects
│   └── music/                        # Background tracks
└── animations/                       # Lottie JSON files
```

---

## 9. Data Flow Diagrams

### Starting a Game Session

```
Host                      Network Layer              Clients
─────                     ─────────────              ───────
[Tap "Host"]
  │
[HostSetupScreen]
  │ configure name/game
  │
[RoomNotifier.createRoom]
  ├──► WebSocketGameServer.start(port: N)
  └──► BonsoirBroadcast.start(port: N, attrs: {roomCode, ...})
                                │
                                │ mDNS advertisement
                                │◄────────────────── BonsoirDiscovery.start()
                                │                    [DiscoveryNotifier updates]
                                │                    [JoinScreen shows room]
                                │
                         [Client taps room]
                                │◄────────────────── WebSocketGameClient.connect(host, port)
                                │
WebSocketGameServer.onConnect   │
  └──► assign playerId          │
  └──► broadcast lobby.roomState──────────────────►  [RoomNotifier.applyMessage]
                                                     [LobbyScreen rebuilds]
```

### In-Game State Update (Host-Authoritative)

```
Client                    WebSocket                  Host
──────                    ─────────                  ────
Sensor event (shake)
  │
[ShakeRaceGame._accelSub]
  │ ctx.broadcastInput({type:'shake'})
  │──────────────────────────────────►  [WebSocketGameServer]
                                           │ msg → allMessages stream
                                           │
                                        [ShakeRaceGame._onMessage]
                                           │ _shakeCounts[pid]++
                                           │
                                        if winner:
                                           │ ctx.onGameComplete(result)
                                           │────────────────────────────►
                                           │     [GameShellScreen]
                                        broadcast game.end payload
  ◄──────────────────────────────────    │
[RoomNotifier] state update              │
[Results navigation triggered]           │
```

---

## 10. Architectural Decision Records

### ADR-001: WebSocket over UDP for game messaging
- **Status**: Accepted  
- **Decision**: Use `dart:io` `WebSocketTransformer` on host, `web_socket_channel` on clients  
- **Rationale**: LAN latency (<5ms) is acceptable for party games. WebSocket eliminates need for custom framing, ordering, and retransmit logic. Reduces implementation risk significantly.  
- **Rejected**: Raw UDP — would require custom framing, sequence numbers, reordering buffer, retransmit with ACK. Net latency saving of ~2ms does not justify 3–4x implementation complexity.

### ADR-002: Bonsoir for service discovery (not hardcoded IP)
- **Status**: Accepted  
- **Decision**: `bonsoir` package using mDNS/NSD  
- **Rationale**: Players should never type an IP address. mDNS (Bonjour) gives zero-config discovery, works on Android (NSD API) without root, and `bonsoir` is the best-maintained Flutter wrapper.  
- **Rejected**: QR code IP sharing — requires camera permission, slower UX. UDP broadcast — works but is less reliable on networks that block broadcast.

### ADR-003: Host-authoritative game state
- **Status**: Accepted  
- **Decision**: All game logic runs on the host. Clients send inputs; host sends state deltas.  
- **Rationale**: Eliminates conflict resolution. Simplest correctness model. On a LAN the latency penalty (~5ms) is imperceptible vs. the complexity of distributed consensus.  
- **Rejected**: Peer-to-peer state (all clients compute state independently and reconcile) — requires CRDT or OT, massively complex, overkill for party games.

### ADR-004: Riverpod over BLoC
- **Status**: Accepted  
- **Decision**: `flutter_riverpod` with `riverpod_annotation` code generation  
- **Rationale**: BLoC is well-suited for strict event sourcing. Riverpod's `Notifier` provides equivalent structure with less boilerplate. Compile-time safety via code generation. Better suited for real-time state that arrives from both UI events and network messages simultaneously.  
- **Rejected**: BLoC — verbose for this use case. Provider — lacks compile-time checks. GetX — couples routing/DI/state, bad for modular game additions.

### ADR-005: Mini-game plugin pattern via interface + registry
- **Status**: Accepted  
- **Decision**: `MiniGame` abstract interface + `GameRegistry` service locator  
- **Rationale**: New games can be added in isolation (one folder, one registration call). Shell code has zero knowledge of specific game implementations. Enables independent testing of each game module.  
- **Rejected**: Direct imports in shell — tight coupling, requires shell changes per game. Flutter's Platform Channels — overkill, not needed for Dart-only games.

### ADR-006: Flame only for physics-heavy games
- **Status**: Accepted  
- **Decision**: Flame as opt-in dependency within a specific game's Widget, not as the app framework  
- **Rationale**: Flame is excellent for 2D physics/sprites but imposes significant architectural constraints if used app-wide. Party game UI (lobbies, menus) is standard Flutter Material. Mixing Flame app-level with Flutter widgets is problematic.  
- **Trade-off**: Games using Flame have a slightly different internal structure. Mitigated by `FlameGameWrapper` helper widget that adapts a `FlameGame` to the `MiniGame` interface.

---

## Appendix: Android Permissions Required

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>

<!-- For mDNS (NSD) - required by Bonsoir on Android -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- For sensor-based games -->
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="false"/>
<uses-feature android:name="android.hardware.sensor.gyroscope" android:required="false"/>

<!-- For camera-based games (optional) -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>

<!-- For audio -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

---

*Architecture designed for the LAN Party Game App. Revisit ADRs when adding Bluetooth/Nearby Connections support or expanding to iOS.*
