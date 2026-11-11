// Static game data: weapons, skills, enemies, bosses and stages.
// Everything is original content written for this project.

class WeaponDef {
  final String id, name, desc;
  final double damage, reach, cooldown;
  final int cost;
  final int color; // slash colour (ARGB)
  final int rarity; // 0 common, 1 rare, 2 epic, 3 legendary
  const WeaponDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.damage,
    required this.reach,
    required this.cooldown,
    required this.cost,
    required this.color,
    this.rarity = 0,
  });
}

const List<String> kRarityNames = ['Common', 'Rare', 'Epic', 'Legendary'];
const List<int> kRarityColors = [0xFFBDBDBD, 0xFF64B5F6, 0xFFBA68C8, 0xFFFFB300];

const List<WeaponDef> kWeaponList = [
  WeaponDef(
      id: 'sword',
      name: 'Iron Sword',
      desc: 'Balanced blade.',
      damage: 10,
      reach: 46,
      cooldown: 0.35,
      cost: 0,
      color: 0xFFE0E0E0),
  WeaponDef(
      id: 'daggers',
      name: 'Twin Daggers',
      desc: 'Very fast, short reach.',
      damage: 6,
      reach: 34,
      cooldown: 0.17,
      cost: 250,
      color: 0xFF80DEEA),
  WeaponDef(
      id: 'spear',
      name: 'War Spear',
      desc: 'Long reach.',
      damage: 9,
      reach: 74,
      cooldown: 0.42,
      cost: 350,
      color: 0xFFFFE082,
      rarity: 1),
  WeaponDef(
      id: 'axe',
      name: 'Great Axe',
      desc: 'Slow but very heavy.',
      damage: 22,
      reach: 54,
      cooldown: 0.7,
      cost: 600,
      color: 0xFFFF8A65,
      rarity: 1),
  WeaponDef(
      id: 'katana',
      name: 'Moon Katana',
      desc: 'Fast and sharp.',
      damage: 14,
      reach: 54,
      cooldown: 0.26,
      cost: 1000,
      color: 0xFFB388FF,
      rarity: 2),
  WeaponDef(
      id: 'ember_blade',
      name: 'Ember Blade',
      desc: 'Forged in dragon fire.',
      damage: 20,
      reach: 62,
      cooldown: 0.3,
      cost: 2400,
      color: 0xFFFFAB40,
      rarity: 3),
];

final Map<String, WeaponDef> kWeapons = {
  for (final w in kWeaponList) w.id: w,
};

class SkillDef {
  final String id, name, desc, icon;
  final double mana, cooldown;
  final int unlockCost;
  const SkillDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.mana,
    required this.cooldown,
    required this.unlockCost,
  });
}

const List<SkillDef> kSkillList = [
  SkillDef(
      id: 'fireball',
      name: 'Fireball',
      desc: 'Piercing fire projectile.',
      icon: 'FIRE',
      mana: 18,
      cooldown: 1.0,
      unlockCost: 0),
  SkillDef(
      id: 'whirl',
      name: 'Whirlwind',
      desc: 'Hits everything around you.',
      icon: 'SPIN',
      mana: 28,
      cooldown: 3.0,
      unlockCost: 120),
  SkillDef(
      id: 'heal',
      name: 'Mend',
      desc: 'Restores health.',
      icon: 'HEAL',
      mana: 35,
      cooldown: 6.0,
      unlockCost: 150),
];

final Map<String, SkillDef> kSkills = {
  for (final s in kSkillList) s.id: s,
};

/// Roguelike perks: offered three at a time when you level up during a run.
class PerkDef {
  final String id, name, desc;
  const PerkDef(this.id, this.name, this.desc);
}

const List<PerkDef> kPerkList = [
  PerkDef('dmg', 'Sharpened Edge', '+15% damage'),
  PerkDef('haste', 'Swift Boots', '+10% move speed'),
  PerkDef('vigor', 'Iron Heart', '+25 max HP and heal 25'),
  PerkDef('crit', 'Eagle Eye', '+8% critical chance'),
  PerkDef('vamp', 'Vampiric Edge', 'Heal a little on every hit'),
  PerkDef('mana', 'Arcane Flow', '+60% mana regeneration'),
  PerkDef('rapid', 'Frenzy', '+12% attack speed'),
  PerkDef('multi', 'Twin Flames', 'Fireball fires extra shots'),
  PerkDef('guard', 'Stone Skin', '-12% damage taken'),
  PerkDef('burst', 'Shockwave', 'Combo finisher sends a shockwave'),
];

const int kMaxSkillLevel = 5;
const int kMaxStatLevel = 10;

class StatDef {
  final String id, name, desc;
  const StatDef(this.id, this.name, this.desc);
}

const List<StatDef> kStatList = [
  StatDef('hp', 'Vitality', '+20 max health per level'),
  StatDef('atk', 'Strength', '+12% damage per level'),
  StatDef('spd', 'Agility', '+5% move speed per level'),
  StatDef('crit', 'Precision', '+4% critical chance per level'),
];

int statCost(int level) => 50 + level * 45;
int skillCost(SkillDef s, int level) =>
    (s.unlockCost == 0 ? 100 : s.unlockCost) * (level + 1);

class EnemyDef {
  final String id, name, sprite;
  final double hp, dmg, speed, widthFactor;
  final int px, gold, xp;
  final bool flying, ranged, boss;
  final List<String> pattern;
  const EnemyDef({
    required this.id,
    required this.name,
    required this.sprite,
    required this.hp,
    required this.dmg,
    required this.speed,
    required this.px,
    required this.gold,
    required this.xp,
    this.widthFactor = 0.8,
    this.flying = false,
    this.ranged = false,
    this.boss = false,
    this.pattern = const [],
  });
}

const List<EnemyDef> kEnemyList = [
  EnemyDef(
      id: 'slime',
      name: 'Slime',
      sprite: 'slime',
      hp: 24,
      dmg: 8,
      speed: 40,
      px: 4,
      gold: 6,
      xp: 5),
  EnemyDef(
      id: 'bat',
      name: 'Cave Bat',
      sprite: 'bat',
      hp: 16,
      dmg: 7,
      speed: 85,
      px: 3,
      gold: 5,
      xp: 5,
      flying: true),
  EnemyDef(
      id: 'skeleton',
      name: 'Skeleton',
      sprite: 'skeleton',
      hp: 40,
      dmg: 12,
      speed: 55,
      px: 3,
      gold: 9,
      xp: 8),
  EnemyDef(
      id: 'archer',
      name: 'Goblin Archer',
      sprite: 'archer',
      hp: 30,
      dmg: 10,
      speed: 45,
      px: 3,
      gold: 10,
      xp: 9,
      ranged: true),
  EnemyDef(
      id: 'golem',
      name: 'Stone Golem',
      sprite: 'golem',
      hp: 110,
      dmg: 20,
      speed: 35,
      px: 4,
      gold: 22,
      xp: 20),
  // Bosses
  EnemyDef(
      id: 'slime_king',
      name: 'Slime King',
      sprite: 'slime_king',
      hp: 220,
      dmg: 14,
      speed: 50,
      px: 8,
      gold: 120,
      xp: 100,
      boss: true,
      pattern: ['jump', 'summon', 'jump', 'charge']),
  EnemyDef(
      id: 'bone_lord',
      name: 'Bone Lord',
      sprite: 'bone_lord',
      hp: 320,
      dmg: 18,
      speed: 60,
      px: 5,
      gold: 160,
      xp: 140,
      boss: true,
      pattern: ['charge', 'fan', 'summon', 'charge']),
  EnemyDef(
      id: 'goblin_chief',
      name: 'Goblin Chief',
      sprite: 'goblin_chief',
      hp: 420,
      dmg: 20,
      speed: 65,
      px: 5,
      gold: 200,
      xp: 180,
      boss: true,
      pattern: ['fan', 'charge', 'fan', 'summon']),
  EnemyDef(
      id: 'stone_titan',
      name: 'Stone Titan',
      sprite: 'stone_titan',
      hp: 600,
      dmg: 28,
      speed: 45,
      px: 6,
      gold: 260,
      xp: 240,
      boss: true,
      pattern: ['jump', 'charge', 'jump', 'fan']),
  EnemyDef(
      id: 'dragon',
      name: 'Ember Dragon',
      sprite: 'dragon',
      hp: 800,
      dmg: 26,
      speed: 70,
      px: 9,
      gold: 400,
      xp: 350,
      boss: true,
      flying: true,
      pattern: ['fan', 'charge', 'fan', 'summon']),
];

final Map<String, EnemyDef> kEnemies = {
  for (final e in kEnemyList) e.id: e,
};

class StageDef {
  final String name, boss;
  final double length;
  final List<String> pool;
  final int count;
  final int sky1, sky2, hill, ground, grass;
  const StageDef({
    required this.name,
    required this.boss,
    required this.length,
    required this.pool,
    required this.count,
    required this.sky1,
    required this.sky2,
    required this.hill,
    required this.ground,
    required this.grass,
  });
}

const List<StageDef> kStages = [
  StageDef(
      name: '1. Green Meadow',
      boss: 'slime_king',
      length: 2400,
      pool: ['slime', 'bat'],
      count: 14,
      sky1: 0xFF4FC3F7,
      sky2: 0xFFB3E5FC,
      hill: 0xFF66BB6A,
      ground: 0xFF6D4C41,
      grass: 0xFF43A047),
  StageDef(
      name: '2. Dark Cave',
      boss: 'bone_lord',
      length: 2800,
      pool: ['slime', 'bat', 'skeleton'],
      count: 17,
      sky1: 0xFF1A1426,
      sky2: 0xFF3B2F52,
      hill: 0xFF4A3B66,
      ground: 0xFF3E3A47,
      grass: 0xFF6A5F80),
  StageDef(
      name: '3. Goblin Fort',
      boss: 'goblin_chief',
      length: 3200,
      pool: ['skeleton', 'archer', 'bat'],
      count: 20,
      sky1: 0xFFFFB74D,
      sky2: 0xFFFFE0B2,
      hill: 0xFFA1887F,
      ground: 0xFF5D4037,
      grass: 0xFF8D6E63),
  StageDef(
      name: '4. Stone Ruins',
      boss: 'stone_titan',
      length: 3600,
      pool: ['golem', 'skeleton', 'archer'],
      count: 22,
      sky1: 0xFF78909C,
      sky2: 0xFFCFD8DC,
      hill: 0xFF90A4AE,
      ground: 0xFF546E7A,
      grass: 0xFF78909C),
  StageDef(
      name: "5. Dragon's Lair",
      boss: 'dragon',
      length: 4000,
      pool: ['golem', 'bat', 'archer', 'skeleton'],
      count: 26,
      sky1: 0xFF3E0F0F,
      sky2: 0xFFB23A1E,
      hill: 0xFF7B2D1A,
      ground: 0xFF2B1A17,
      grass: 0xFF8E3B22),
];

class AchDef {
  final String id, name, desc;
  final int reward; // gold, paid once
  const AchDef(this.id, this.name, this.desc, this.reward);
}

const List<AchDef> kAchList = [
  AchDef('first_blood', 'First Blood', 'Defeat your first enemy.', 20),
  AchDef('slayer100', 'Monster Hunter', 'Defeat 100 enemies.', 80),
  AchDef('slayer500', 'Legend Slayer', 'Defeat 500 enemies.', 250),
  AchDef('boss1', 'Boss Breaker', 'Defeat your first boss.', 60),
  AchDef('bossall', 'Dragon Slayer', 'Defeat all five bosses.', 400),
  AchDef('combo10', 'Combo Starter', 'Land a 10 hit combo.', 50),
  AchDef('combo25', 'Combo Master', 'Land a 25 hit combo.', 150),
  AchDef('checkpoint', 'Safe Haven', 'Reach a checkpoint.', 30),
  AchDef('perk5', 'Build Crafter', 'Pick 5 perks in one run.', 100),
  AchDef('perfect', 'Untouchable', 'Win a stage without taking damage.', 200),
  AchDef('rich', 'Treasure Hoarder', 'Hold 1000 gold at once.', 100),
  AchDef('collector', 'Armory', 'Own every weapon.', 300),
  AchDef('level10', 'Seasoned Knight', 'Reach level 10.', 150),
  AchDef('skillmax', 'Arcane Master', 'Max out one skill.', 200),
];

final Map<String, AchDef> kAch = {
  for (final a in kAchList) a.id: a,
};
