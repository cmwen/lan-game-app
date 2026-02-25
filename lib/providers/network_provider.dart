import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/game_message.dart';
import '../domain/entities/player.dart';
import '../services/network/websocket_game_client.dart';
import '../services/network/websocket_game_server.dart';
import 'player_provider.dart';
import 'room_provider.dart';

/// Encapsulates the current network role (host or guest) and connection state.
class NetworkState {
  const NetworkState({
    this.isHost = false,
    this.isConnected = false,
    this.hostIp,
    this.port,
    this.error,
  });

  final bool isHost;
  final bool isConnected;
  final String? hostIp;
  final int? port;
  final String? error;

  NetworkState copyWith({
    bool? isHost,
    bool? isConnected,
    String? hostIp,
    int? port,
    String? error,
  }) {
    return NetworkState(
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      hostIp: hostIp ?? this.hostIp,
      port: port ?? this.port,
      error: error,
    );
  }
}

/// Manages the WebSocket server (host) or client (guest) lifecycle.
///
/// Host flow: [startServer] → broadcasts via discovery → accepts connections.
/// Guest flow: [connectToHost] → receives room updates.
class NetworkNotifier extends Notifier<NetworkState> {
  WebSocketGameServer? _server;
  WebSocketGameClient? _client;

  StreamSubscription<GameMessage>? _messageSub;
  StreamSubscription<dynamic>? _connectionSub;

  WebSocketGameServer? get server => _server;
  WebSocketGameClient? get client => _client;

  /// Incoming network message stream (for games and lobby).
  final _messageController = StreamController<GameMessage>.broadcast();
  Stream<GameMessage> get messages => _messageController.stream;

  @override
  NetworkState build() => const NetworkState();

  // ─── Host ──────────────────────────────────────────────────────────────────

  /// Start a WebSocket server and return the bound port.
  Future<int> startServer() async {
    _server = WebSocketGameServer();
    final port = await _server!.start();
    final ip = await WebSocketGameServer.getLocalIpAddress();

    // Listen for messages from connected clients.
    _messageSub = _server!.allMessages.listen(_onServerMessage);

    // Listen for new connections — ask joining players to identify.
    _connectionSub = _server!.playerConnections.listen((_) {
      // Broadcast current room state to all when a new socket connects.
      final room = ref.read(roomProvider);
      if (room != null) {
        _server!.broadcast(
          GameMessage(
            type: 'lobby.roomState',
            senderId: 'system',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            payload: {'room': room.toJson()},
          ),
        );
      }
    });

    state = state.copyWith(
      isHost: true,
      isConnected: true,
      hostIp: ip,
      port: port,
    );
    return port;
  }

  void _onServerMessage(GameMessage message) {
    // Forward to the room provider for lobby updates.
    if (message.type.startsWith('lobby.')) {
      ref.read(roomProvider.notifier).handleMessage(message);

      // If a player is joining, add them and re-broadcast room state.
      if (message.type == 'lobby.join') {
        final player = Player.fromJson(
          message.payload['player'] as Map<String, dynamic>,
        );
        ref.read(roomProvider.notifier).addPlayer(player);

        final room = ref.read(roomProvider);
        if (room != null) {
          _server!.broadcast(
            GameMessage(
              type: 'lobby.roomState',
              senderId: 'system',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              payload: {'room': room.toJson()},
            ),
          );
        }
      }
    }
    _messageController.add(message);
  }

  /// Broadcast a [GameMessage] to all connected clients (host only).
  Future<void> broadcast(GameMessage message) async {
    await _server?.broadcast(message);
  }

  // ─── Guest ─────────────────────────────────────────────────────────────────

  /// Connect to a host at [host]:[port].
  Future<void> connectToHost({required String host, required int port}) async {
    final player = ref.read(localPlayerProvider);
    if (player == null) return;

    _client = WebSocketGameClient(localPlayerId: player.id);
    try {
      await _client!.connect(host: host, port: port);

      _messageSub = _client!.messages.listen(_onClientMessage);

      // Send join message to the host.
      await _client!.send(
        GameMessage(
          type: 'lobby.join',
          senderId: player.id,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: {'player': player.toJson()},
        ),
      );

      state = state.copyWith(
        isHost: false,
        isConnected: true,
        hostIp: host,
        port: port,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _onClientMessage(GameMessage message) {
    // Forward lobby messages to room provider.
    if (message.type.startsWith('lobby.') || message.type.startsWith('game.')) {
      ref.read(roomProvider.notifier).handleMessage(message);
    }
    _messageController.add(message);
  }

  /// Send a message to the host (guest only).
  Future<void> send(GameMessage message) async {
    await _client?.send(message);
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  /// Disconnect and tear down all network resources.
  Future<void> disconnect() async {
    await _messageSub?.cancel();
    _messageSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;

    await _server?.stop();
    _server = null;

    _client?.dispose();
    _client = null;

    state = const NetworkState();
  }
}

/// Provides the network layer (server/client) for the current session.
final networkProvider = NotifierProvider<NetworkNotifier, NetworkState>(
  NetworkNotifier.new,
);
