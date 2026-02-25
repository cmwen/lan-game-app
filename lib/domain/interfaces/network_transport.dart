import '../entities/game_message.dart';

// ---------------------------------------------------------------------------
// NetworkTransport — lowest-level abstraction over a single connection
// ---------------------------------------------------------------------------
abstract interface class NetworkTransport {
  /// Incoming messages from the remote end
  Stream<GameMessage> get incomingMessages;

  /// Send a message to the remote end
  Future<void> send(GameMessage message);

  /// Close the connection
  Future<void> close();

  /// True if the connection is currently open
  bool get isConnected;
}

// ---------------------------------------------------------------------------
// GameServer — host-side: manages N client connections
// ---------------------------------------------------------------------------
abstract interface class GameServer {
  /// Start listening on [port]. Pass 0 to let the OS pick a free port.
  Future<int> start({int port = 0});

  /// Actual port the server bound to (useful when port was 0)
  int get boundPort;

  /// Emits each new client connection as it arrives
  Stream<PlayerConnection> get playerConnections;

  /// All messages from all connected clients
  Stream<GameMessage> get allMessages;

  /// Send [message] to every connected client
  Future<void> broadcast(GameMessage message);

  /// Send [message] to a specific client by their connection ID
  Future<void> sendTo(String connectionId, GameMessage message);

  /// Gracefully close all connections and stop the server
  Future<void> stop();

  bool get isRunning;
}

class PlayerConnection {
  final String id;
  final dynamic
  socket; // WebSocket — typed as dynamic to avoid dart:io import here
  const PlayerConnection({required this.id, required this.socket});
}

// ---------------------------------------------------------------------------
// GameClient — client-side: single connection to the host
// ---------------------------------------------------------------------------
abstract interface class GameClient {
  /// Connect to host at [host]:[port]
  Future<void> connect({required String host, required int port});

  /// Stream of messages from the host
  Stream<GameMessage> get messages;

  /// Send a message to the host
  Future<void> send(GameMessage message);

  /// Disconnect from the host
  Future<void> disconnect();

  bool get isConnected;
}
