import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import '../models/shift.dart';

/// Loads and persists shifts and settings to on-device storage.
class Repository {
  static const _shiftsKey = 'shift_tracker.shifts.v1';
  static const _settingsKey = 'shift_tracker.settings.v1';

  final SharedPreferences _prefs;
  Repository(this._prefs);

  static Future<Repository> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Repository(prefs);
  }

  /// Re-read from disk (picks up changes made by the widget background isolate).
  Future<List<Shift>> reload() async {
    await _prefs.reload();
    return loadShifts();
  }

  List<Shift> loadShifts() {
    final raw = _prefs.getString(_shiftsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Shift.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveShifts(List<Shift> shifts) {
    final raw = jsonEncode(shifts.map((s) => s.toJson()).toList());
    return _prefs.setString(_shiftsKey, raw);
  }

  Settings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return Settings.defaults();
    return Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(Settings settings) {
    return _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
