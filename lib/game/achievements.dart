import 'audio.dart';
import 'data.dart';
import 'save.dart';

/// Unlocks achievements and queues a banner for the game screen.
class Ach {
  /// Banner texts waiting to be shown.
  static final List<String> pending = [];

  static bool unlock(String id) {
    final def = kAch[id];
    if (def == null || gSave.achievements.contains(id)) return false;
    gSave.achievements.add(id);
    gSave.gold += def.reward;
    pending.add('${def.name}  +${def.reward}g');
    Sfx.play('ach');
    gSave.save();
    return true;
  }

  /// Checks every achievement that depends on saved totals.
  static void checkProgress() {
    final s = gSave;
    if (s.totalKills >= 1) unlock('first_blood');
    if (s.totalKills >= 100) unlock('slayer100');
    if (s.totalKills >= 500) unlock('slayer500');
    if (s.bosses.isNotEmpty) unlock('boss1');
    if (s.bosses.length >= 5) unlock('bossall');
    if (s.bestCombo >= 10) unlock('combo10');
    if (s.bestCombo >= 25) unlock('combo25');
    if (s.gold >= 1000) unlock('rich');
    if (s.owned.length >= kWeaponList.length) unlock('collector');
    if (s.level >= 10) unlock('level10');
    if (s.skills.values.any((lv) => lv >= kMaxSkillLevel)) unlock('skillmax');
  }
}
