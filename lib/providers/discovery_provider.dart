import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/interfaces/discovery_service.dart';
import '../services/discovery/bonsoir_discovery_service.dart';

/// Wraps [BonsoirDiscoveryService] so the lobby screens can discover rooms
/// on the local network via mDNS.
class DiscoveryNotifier extends Notifier<List<DiscoveredRoom>> {
  BonsoirDiscoveryService? _service;
  StreamSubscription<List<DiscoveredRoom>>? _sub;

  @override
  List<DiscoveredRoom> build() => const [];

  BonsoirDiscoveryService get service {
    _service ??= BonsoirDiscoveryService();
    return _service!;
  }

  /// Start scanning for nearby rooms.
  Future<void> startDiscovery() async {
    _service ??= BonsoirDiscoveryService();
    _sub = _service!.discoveredRooms.listen((rooms) {
      state = rooms;
    });
    await _service!.startDiscovery();
  }

  /// Stop scanning.
  Future<void> stopDiscovery() async {
    await _sub?.cancel();
    _sub = null;
    await _service?.stopDiscovery();
  }

  /// Start broadcasting this host room on the network.
  Future<void> startBroadcast({
    required String roomCode,
    required String hostName,
    required int port,
    int maxPlayers = 8,
    int currentPlayers = 1,
  }) async {
    _service ??= BonsoirDiscoveryService();
    await _service!.startBroadcast(
      roomCode: roomCode,
      hostName: hostName,
      port: port,
      maxPlayers: maxPlayers,
      currentPlayers: currentPlayers,
    );
  }

  /// Update broadcast player count.
  Future<void> updatePlayerCount(int count) async {
    await _service?.updatePlayerCount(count);
  }

  /// Stop broadcasting.
  Future<void> stopBroadcast() async {
    await _service?.stopBroadcast();
  }

  /// Clean up all resources.
  void cleanup() {
    _sub?.cancel();
    _service?.dispose();
    _service = null;
  }
}

/// Discovered rooms on the LAN.
final discoveryProvider =
    NotifierProvider<DiscoveryNotifier, List<DiscoveredRoom>>(
      DiscoveryNotifier.new,
    );
