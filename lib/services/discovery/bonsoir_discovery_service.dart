// Bonsoir-based service discovery for finding and advertising game rooms.
// Implements [DiscoveryService] from domain/interfaces/discovery_service.dart.
//
// Requires: bonsoir: ^6.x in pubspec.yaml
// Android permission: android.permission.CHANGE_WIFI_MULTICAST_STATE

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/interfaces/discovery_service.dart';

class BonsoirDiscoveryService implements DiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  final _roomsController = StreamController<List<DiscoveredRoom>>.broadcast();
  final _knownRooms = <String, DiscoveredRoom>{}; // key = serviceName

  // Track broadcast params for potential re-broadcast
  String? _lastRoomCode;
  String? _lastHostName;
  int? _lastPort;
  int? _lastMaxPlayers;

  // ─── HOST ─────────────────────────────────────────────────────────────────

  @override
  Future<void> startBroadcast({
    required String roomCode,
    required String hostName,
    required int port,
    required int maxPlayers,
    int currentPlayers = 1,
  }) async {
    _lastRoomCode = roomCode;
    _lastHostName = hostName;
    _lastPort = port;
    _lastMaxPlayers = maxPlayers;

    final service = BonsoirService(
      name: 'PartyPocket-$roomCode',
      type: AppConstants.serviceType,
      port: port,
      attributes: {
        'roomCode': roomCode,
        'hostName': hostName,
        'maxPlayers': maxPlayers.toString(),
        'currentPlayers': currentPlayers.toString(),
        'gameVersion': '1.0.0',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  @override
  Future<void> updatePlayerCount(int count) async {
    // Bonsoir does not support live TXT record updates on Android NSD.
    // Workaround: stop and restart broadcast with updated attributes.
    if (_lastRoomCode == null) return;
    await stopBroadcast();
    await startBroadcast(
      roomCode: _lastRoomCode!,
      hostName: _lastHostName!,
      port: _lastPort!,
      maxPlayers: _lastMaxPlayers!,
      currentPlayers: count,
    );
  }

  @override
  Future<void> stopBroadcast() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  // ─── CLIENT ───────────────────────────────────────────────────────────────

  @override
  Future<void> startDiscovery() async {
    _discovery = BonsoirDiscovery(type: AppConstants.serviceType);
    await _discovery!.initialize();
    _discovery!.eventStream!.listen(_onDiscoveryEvent);
    await _discovery!.start();
  }

  void _onDiscoveryEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceResolvedEvent():
        final svc = event.service;
        final attrs = svc.attributes;
        _knownRooms[svc.name] = DiscoveredRoom(
          roomCode: attrs['roomCode'] ?? svc.name,
          hostName: attrs['hostName'] ?? 'Unknown',
          host: svc.host ?? '',
          port: svc.port,
          currentPlayers: int.tryParse(attrs['currentPlayers'] ?? '1') ?? 1,
          maxPlayers: int.tryParse(attrs['maxPlayers'] ?? '8') ?? 8,
          gameVersion: attrs['gameVersion'] ?? '?',
        );
        _roomsController.add(List.unmodifiable(_knownRooms.values));
      case BonsoirDiscoveryServiceLostEvent():
        _knownRooms.remove(event.service.name);
        _roomsController.add(List.unmodifiable(_knownRooms.values));
      default:
        break;
    }
  }

  @override
  Stream<List<DiscoveredRoom>> get discoveredRooms => _roomsController.stream;

  @override
  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    _discovery = null;
    _knownRooms.clear();
  }

  @override
  void dispose() {
    _broadcast?.stop();
    _discovery?.stop();
    _roomsController.close();
  }
}
