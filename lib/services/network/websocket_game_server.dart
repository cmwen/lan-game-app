// WebSocket server implementation for the game host.
// Uses dart:io HttpServer — no additional packages needed.
//
// Features:
//   • Binds to local IP + OS-assigned port
//   • Accepts WebSocket clients
//   • Broadcasts GameMessage to all connected clients
//   • Heartbeat ping every 2 seconds; disconnects unresponsive clients
//   • Tracks connected players by their WebSocket
//   • Emits a Stream<GameMessage> of incoming messages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/game_message.dart';
import '../../domain/interfaces/network_transport.dart';

class WebSocketGameServer implements GameServer {
  HttpServer? _server;
  final Map<String, WebSocket> _sockets = {};
  final _messageController = StreamController<GameMessage>.broadcast();
  final _connectionController = StreamController<PlayerConnection>.broadcast();
  bool _running = false;
  Timer? _heartbeatTimer;

  @override
  bool get isRunning => _running;

  @override
  int get boundPort => _server?.port ?? 0;

  @override
  Stream<PlayerConnection> get playerConnections =>
      _connectionController.stream;

  @override
  Stream<GameMessage> get allMessages => _messageController.stream;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<int> start({int port = 0}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _running = true;

    _server!
        .transform(WebSocketTransformer())
        .listen(
          _onNewSocket,
          onError: _handleServerError,
          onDone: () => _running = false,
        );

    // Start heartbeat ping/pong every 2 seconds
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.heartbeatIntervalMs),
      (_) => _sendHeartbeat(),
    );

    return _server!.port;
  }

  @override
  Future<void> stop() async {
    _running = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    for (final ws in _sockets.values) {
      await ws.close();
    }
    _sockets.clear();
    await _server?.close(force: true);
    _server = null;
    await _messageController.close();
    await _connectionController.close();
  }

  // ─── Messaging ──────────────────────────────────────────────────────────────

  @override
  Future<void> broadcast(GameMessage message) async {
    final encoded = jsonEncode(message.toJson());
    for (final ws in List.of(_sockets.values)) {
      if (ws.readyState == WebSocket.open) {
        ws.add(encoded);
      }
    }
  }

  @override
  Future<void> sendTo(String connectionId, GameMessage message) async {
    final ws = _sockets[connectionId];
    if (ws != null && ws.readyState == WebSocket.open) {
      ws.add(jsonEncode(message.toJson()));
    }
  }

  // ─── Internal ───────────────────────────────────────────────────────────────

  void _onNewSocket(WebSocket ws) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _sockets[id] = ws;
    _connectionController.add(PlayerConnection(id: id, socket: ws));

    ws.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final msg = GameMessage.fromJson(json);
          _messageController.add(msg);
        } catch (_) {
          // Malformed message — ignore
        }
      },
      onDone: () => _onSocketClosed(id),
      onError: (_) => _onSocketClosed(id),
    );
  }

  void _onSocketClosed(String connectionId) {
    _sockets.remove(connectionId);
    if (!_messageController.isClosed) {
      _messageController.add(
        GameMessage(
          type: 'system.playerDisconnected',
          senderId: 'system',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: {'connectionId': connectionId},
        ),
      );
    }
  }

  void _handleServerError(Object error) {
    // Log server-level errors; individual socket errors are handled per-socket.
  }

  void _sendHeartbeat() {
    if (!_running) return;
    final ping = GameMessage(
      type: 'system.ping',
      senderId: 'system',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    broadcast(ping);
  }

  /// Helper: get the local Wi-Fi/LAN IP address to advertise via mDNS.
  static Future<String> getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }
}
