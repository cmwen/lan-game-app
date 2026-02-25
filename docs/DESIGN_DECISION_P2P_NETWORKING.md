# Design Decision: P2P Networking Stack

**Status**: Accepted  
**Date**: 2025  
**Deciders**: Architecture Team  
**Relates to**: ARCHITECTURE_LAN_PARTY_GAME.md § ADR-001, ADR-002

---

## Context

The app needs real-time communication between 1–8 devices on the same WiFi network with zero internet dependency. We need:

1. **Discovery** — players find each other's games without typing IP addresses
2. **Communication** — fast, reliable, bidirectional message passing
3. **Resilience** — graceful disconnection handling in a party game context

---

## Option Analysis

### Discovery Layer

| Option | How it works | Android support | Reliability |
|---|---|---|---|
| **mDNS / NSD (Bonsoir)** | Multicast DNS, OS-level | ✅ Android NSD API | ✅ High |
| UDP Broadcast | Send to 255.255.255.255 | ✅ Works | ⚠️ Some routers block broadcast |
| QR Code / Manual IP | User scans/types IP | ✅ Works | ✅ Reliable, bad UX |
| Google Nearby Connections | BT + WiFi hybrid | ✅ Play Services | ⚠️ Requires Google Play Services |
| Bluetooth Classic | BT RFCOMM | ✅ Works | ⚠️ Pairing friction, limited range |

**Selected: Bonsoir (mDNS/NSD)**
- Zero-config — host broadcasts, clients discover automatically
- `bonsoir` pub.dev package is well-maintained, supports mDNS (Apple) and NSD (Android)
- TXT records in the service advertisement carry room metadata (code, players, version)
- No dependency on Google Play Services

### Communication Layer

| Option | Latency (LAN) | Reliability | Flutter support | Complexity |
|---|---|---|---|---|
| **WebSocket (TCP)** | ~2–5ms | ✅ Guaranteed delivery | ✅ `web_socket_channel` | Low |
| Raw UDP | ~0.5–2ms | ❌ Must implement ACK | `dart:io` RawDatagramSocket | High |
| TCP Sockets | ~2–5ms | ✅ Guaranteed | `dart:io` Socket | Medium |
| Google Nearby Connections | ~5–20ms | ✅ High | `nearby_connections` | Medium |
| Firebase RTDB | ~50–200ms | ✅ High | `firebase_database` | Low — but requires internet |

**Selected: WebSocket over TCP**

WebSocket gives us:
- Full-duplex communication (both sides can push at any time)
- Built-in framing (no length-prefix parsing)
- `dart:io` `HttpServer.bind()` creates the server on the host
- `web_socket_channel` wraps the client connection with a Dart `Stream`/`Sink`
- ~3ms round-trip on LAN — imperceptible for party games

**Rejected UDP** because:
- Party game inputs (taps, shakes) are event-based, not continuous streams
- Packet loss on LAN is <0.01% — retransmit overhead is negligible
- Custom framing + sequence numbers + ACK system = 400+ lines of protocol code with no user-visible benefit

---

## Implementation Design

### Host WebSocket Server

```dart
class WebSocketGameServer implements GameServer {
  HttpServer? _server;
  final Map<String, WebSocketConnection> _connections = {};
  final StreamController<GameMessage> _messageController = StreamController.broadcast();
  final StreamController<PlayerConnection> _connectionController = StreamController.broadcast();

  @override
  Future<void> start({required int port}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.transform(WebSocketTransformer()).listen((ws) {
      final connectionId = const Uuid().v4();
      _connections[connectionId] = WebSocketConnection(id: connectionId, ws: ws);
      
      ws.listen(
        (data) {
          final message = GameMessage.fromJson(jsonDecode(data as String));
          _messageController.add(message);
        },
        onDone: () => _handleDisconnect(connectionId),
        onError: (_) => _handleDisconnect(connectionId),
      );
      
      _connectionController.add(PlayerConnection(id: connectionId, ws: ws));
    });
  }

  @override
  Future<void> broadcast(GameMessage message) async {
    final encoded = jsonEncode(message.toJson());
    for (final conn in _connections.values) {
      conn.ws.add(encoded);
    }
  }

  @override
  Future<void> sendTo(String playerId, GameMessage message) async {
    _connections[playerId]?.ws.add(jsonEncode(message.toJson()));
  }

  void _handleDisconnect(String connectionId) {
    _connections.remove(connectionId);
    // Emit disconnect event for reconnection handling
    _messageController.add(GameMessage(
      type: 'system.playerDisconnected',
      fromPlayerId: 'system',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payload: {'connectionId': connectionId},
    ));
  }

  @override
  Future<void> stop() async {
    for (final conn in _connections.values) {
      await conn.ws.close();
    }
    await _server?.close();
  }
}
```

### Client WebSocket Connection

```dart
class WebSocketGameClient implements GameClient {
  WebSocketChannel? _channel;
  final StreamController<GameMessage> _messageController = StreamController.broadcast();

  @override
  Future<void> connect({required String host, required int port}) async {
    final uri = Uri.parse('ws://$host:$port');
    _channel = WebSocketChannel.connect(uri);
    
    _channel!.stream.listen(
      (data) {
        final message = GameMessage.fromJson(jsonDecode(data as String));
        _messageController.add(message);
      },
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
    );
  }

  void _onDisconnected() {
    _messageController.add(GameMessage(
      type: 'system.hostDisconnected',
      fromPlayerId: 'system',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payload: {},
    ));
  }

  @override
  Future<void> send(GameMessage message) async {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  @override
  Future<void> disconnect() async {
    await _channel?.sink.close();
  }
}
```

### Heartbeat System

```dart
class HeartbeatMonitor {
  static const _pingInterval = Duration(seconds: 2);
  static const _pongTimeout = Duration(seconds: 3);
  static const _maxMissedPongs = 2;
  
  final Map<String, int> _missedPongs = {};
  Timer? _pingTimer;
  
  /// Call on HOST to monitor all connected clients
  void startMonitoring(GameServer server) {
    _pingTimer = Timer.periodic(_pingInterval, (_) async {
      await server.broadcast(GameMessage(
        type: 'system.ping',
        fromPlayerId: 'host',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        payload: {},
      ));
      
      // Increment miss counter for all — reset on pong receipt
      for (final key in _missedPongs.keys.toList()) {
        _missedPongs[key] = (_missedPongs[key] ?? 0) + 1;
        if (_missedPongs[key]! >= _maxMissedPongs) {
          // Trigger player-disconnected flow
          _onPlayerUnresponsive(key);
        }
      }
    });
  }
  
  void recordPong(String playerId) {
    _missedPongs[playerId] = 0;
  }
  
  void dispose() => _pingTimer?.cancel();
}
```

---

## Consequences

### Positive
- **Simple mental model**: all state is on the host, clients are display terminals
- **No conflict resolution** needed
- **Easy to debug**: capture WebSocket frames with `websocat` or Charles Proxy
- **Extensible**: `NetworkTransport` interface allows swapping to Nearby Connections without changing game logic

### Negative / Trade-offs
- **Host is SPOF**: if host device dies, the session ends (mitigated by host promotion — future work)
- **TCP head-of-line blocking**: if one packet is lost (rare on LAN), all subsequent messages wait. For latency-critical use consider UDP in v2
- **No end-to-end encryption**: acceptable for a local party game where all players are in the same room

---

## Future Considerations

- **Bluetooth fallback**: if WiFi mDNS fails (captive portal hotel networks), fall back to Bluetooth RFCOMM via `flutter_bluetooth_serial`  
- **Nearby Connections**: Google's `nearby_connections` uses a WiFi + Bluetooth hybrid for discovery — viable alternative for v2 but requires Google Play Services
- **UDP for real-time games**: if profiling shows >10ms jitter causing UX problems, introduce UDP for game input messages only (keep WebSocket for lobby/state)
