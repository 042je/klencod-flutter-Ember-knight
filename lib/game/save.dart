import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Player progress. Stored locally on the device only (no network).
class SaveData {
  static const String _key = 'save_v1';

  int gold = 0;
  int xp = 0;
  int unlockedStage = 0;
  String weapon = 'sword';
  Set<String> owned = {'sword'};
  Map<String, int> skills = {'fireball': 1, 'whirl': 0, 'heal': 0};
  Map<String, int> stats = {'hp': 0, 'atk': 0, 'spd': 0, 'crit': 0};

  SaveData();

  int get level => 1 + xp ~/ 150;
  int skillLv(String id) => skills[id] ?? 0;
  int stat(String id) => stats[id] ?? 0;

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'xp': xp,
        'unlockedStage': unlockedStage,
        'weapon': weapon,
        'owned': owned.toList(),
        'skills': skills,
        'stats': stats,
      };

  factory SaveData.fromJson(Map<String, dynamic> j) {
    final s = SaveData();
    s.gold = (j['gold'] as num?)?.toInt() ?? 0;
    s.xp = (j['xp'] as num?)?.toInt() ?? 0;
    s.unlockedStage = (j['unlockedStage'] as num?)?.toInt() ?? 0;
    if (s.unlockedStage < 0) s.unlockedStage = 0;
    if (s.unlockedStage > kStages.length - 1) {
      s.unlockedStage = kStages.length - 1;
    }
    final w = j['weapon'];
    if (w is String && kWeapons.containsKey(w)) s.weapon = w;
    final o = j['owned'];
    if (o is List) {
      s.owned = o.map((e) => e.toString()).toSet();
    }
    s.owned.add('sword');
    if (!s.owned.contains(s.weapon)) s.weapon = 'sword';
    final sk = j['skills'];
    if (sk is Map) {
      sk.forEach((k, v) {
        if (v is num) s.skills[k.toString()] = v.toInt();
      });
    }
    final st = j['stats'];
    if (st is Map) {
      st.forEach((k, v) {
        if (v is num) s.stats[k.toString()] = v.toInt();
      });
    }
    return s;
  }

  static Future<SaveData> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return SaveData();
      return SaveData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SaveData();
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(toJson()));
    } catch (_) {
      // Saving is best effort; the game keeps working without it.
    }
  }
}

/// The single save slot, loaded in main() before the UI starts.
late SaveData gSave;
