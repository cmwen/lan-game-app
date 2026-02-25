import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/player.dart';

/// Keys used for SharedPreferences persistence.
class _PlayerKeys {
  static const id = 'player_id';
  static const nickname = 'player_nickname';
  static const avatarIndex = 'player_avatar_index';
}

/// Manages the local player identity.
///
/// On first use a UUID is generated and persisted. The player can set a
/// nickname (max 12 chars) and pick one of 8 avatar colours.
class PlayerNotifier extends Notifier<Player?> {
  @override
  Player? build() {
    // Kick off async load — state updates when ready.
    _loadFromPrefs();
    return null;
  }

  /// Load persisted player from SharedPreferences.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_PlayerKeys.id);
    final nickname = prefs.getString(_PlayerKeys.nickname);
    final avatarIndex = prefs.getInt(_PlayerKeys.avatarIndex) ?? 0;

    if (id != null && nickname != null && nickname.isNotEmpty) {
      state = Player(id: id, nickname: nickname, avatarIndex: avatarIndex);
    }
  }

  /// Set (or update) nickname and avatar colour.
  /// Generates a UUID on first call. Persists to SharedPreferences.
  Future<void> setProfile({
    required String nickname,
    required int avatarIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Reuse existing ID or generate a new one.
    final existingId = prefs.getString(_PlayerKeys.id);
    final id = existingId ?? const Uuid().v4();

    final trimmed = nickname.trim();
    final safeName = trimmed.length > 12 ? trimmed.substring(0, 12) : trimmed;

    await prefs.setString(_PlayerKeys.id, id);
    await prefs.setString(_PlayerKeys.nickname, safeName);
    await prefs.setInt(_PlayerKeys.avatarIndex, avatarIndex);

    state = Player(id: id, nickname: safeName, avatarIndex: avatarIndex);
  }

  /// Clear persisted data (for "reset identity" flows).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_PlayerKeys.id);
    await prefs.remove(_PlayerKeys.nickname);
    await prefs.remove(_PlayerKeys.avatarIndex);
    state = null;
  }
}

/// The local player on this device. `null` until a nickname is set.
final localPlayerProvider = NotifierProvider<PlayerNotifier, Player?>(
  PlayerNotifier.new,
);
