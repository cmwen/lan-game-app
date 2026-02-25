// DiscoveredRoom — metadata about a room found via mDNS discovery
class DiscoveredRoom {
  final String roomCode;
  final String hostName;
  final String host; // IP address
  final int port;
  final int currentPlayers;
  final int maxPlayers;
  final String gameVersion;

  const DiscoveredRoom({
    required this.roomCode,
    required this.hostName,
    required this.host,
    required this.port,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.gameVersion,
  });

  bool get isFull => currentPlayers >= maxPlayers;
}

// ---------------------------------------------------------------------------
// DiscoveryService — find and advertise game rooms on the local network
// ---------------------------------------------------------------------------
abstract interface class DiscoveryService {
  // --- HOST ---

  /// Broadcast this device as a game host on the local network
  Future<void> startBroadcast({
    required String roomCode,
    required String hostName,
    required int port,
    required int maxPlayers,
    int currentPlayers = 1,
  });

  /// Update the player count in the mDNS advertisement
  Future<void> updatePlayerCount(int count);

  /// Stop broadcasting (call when game ends or host leaves)
  Future<void> stopBroadcast();

  // --- CLIENT ---

  /// Start scanning for nearby game rooms
  Future<void> startDiscovery();

  /// Live stream of discovered rooms — emits on found/updated/lost
  Stream<List<DiscoveredRoom>> get discoveredRooms;

  /// Stop scanning
  Future<void> stopDiscovery();

  void dispose();
}
