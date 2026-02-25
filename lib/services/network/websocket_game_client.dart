// WebSocket client implementation for players joining a game room.
// Uses dart:io WebSocket — no additional packages needed.
//
// Features:
//   • Connects to host IP:port via WebSocket
//   • Sends and receives GameMessage
//   • Responds to heartbeat pings with pongs
//   • Emits a Stream<GameMessage> of incoming messages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/game_message.dart';
import '../../domain/interfaces/network_transport.dart';

class WebSocketGameClient implements GameClient {
  WebSocket? _socket;
  final _messageController = StreamController<GameMessage>.broadcast();
  bool _connected = false;

  /// The player ID to use as `senderId` for auto-pong responses.
  final String localPlayerId;

  WebSocketGameClient({required this.localPlayerId});

  @override
  bool get isConnected => _connected;

  @override
  Stream<GameMessage> get messages => _messageController.stream;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> connect({required String host, required int port}) async {
    final uri = 'ws://$host:$port';
    _socket = await WebSocket.connect(uri);
    _connected = true;

    _socket!.listen(
      _onData,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _socket?.close();
    _socket = null;
  }

  // ─── Messaging ──────────────────────────────────────────────────────────────

  @override
  Future<void> send(GameMessage message) async {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(message.toJson()));
    }
  }

  // ─── Internal ───────────────────────────────────────────────────────────────

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = GameMessage.fromJson(json);

      // Auto-respond to heartbeat pings
      if (msg.type == 'system.ping') {
        send(
          GameMessage(
            type: 'system.pong',
            senderId: localPlayerId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        return;
      }

      _messageController.add(msg);
    } catch (_) {
      // Malformed message — ignore
    }
  }

  void _onDisconnected() {
    _connected = false;
    if (!_messageController.isClosed) {
      _messageController.add(
        GameMessage(
          type: 'system.hostDisconnected',
          senderId: 'system',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  /// Close the client and release resources.
  void dispose() {
    _connected = false;
    _socket?.close();
    _messageController.close();
  }
}
