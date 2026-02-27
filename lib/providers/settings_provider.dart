import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool developerMode;
  const SettingsState({this.developerMode = false});
  SettingsState copyWith({bool? developerMode}) =>
      SettingsState(developerMode: developerMode ?? this.developerMode);
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyDeveloperMode = 'developer_mode';

  @override
  SettingsState build() => const SettingsState();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      developerMode: prefs.getBool(_keyDeveloperMode) ?? false,
    );
  }

  Future<void> setDeveloperMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDeveloperMode, v);
    state = state.copyWith(developerMode: v);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
