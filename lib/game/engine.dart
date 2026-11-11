import 'dart:math';
import 'dart:ui';

import 'data.dart';
import 'save.dart';
import 'sprites.dart';

enum GameState { playing, won, lost }

/// The world is drawn 270 units tall and scaled to the screen height.
const double kViewH = 270.0;
const double kGroundY = 228.0;

class Knight {
  static const double w = 30;
  static const double h = 48;
  double x = 80, y = kGroundY, vx = 0, vy = 0;
  int facing = 1;
  bool onGround = true;
  double hp, maxHp, mana, maxMana;
  double atkTimer = 0, slashTimer = 0, invuln = 0, dash = 0, dashCd = 0;
  double flash = 0, whirl = 0;
  Knight(this.maxHp, this.maxMana)
      : hp = maxHp,
        mana = maxMana;
}

class Enemy {
  final EnemyDef def;
  double x, y, vx = 0, vy = 0, hp, maxHp, w, h, dmg;
  int dir = -1;
  int cdir = 1;
  int patIdx = 0;
  double atkTimer = 0, flash = 0, stun = 0, special = 2.5, charge = 0;
  double t = 0, shoot = 1.5;
  bool dead = false;
  Enemy(this.def, this.x, this.y, this.w, this.h, double hpMul, double dmgMul)
      : hp = def.hp * hpMul,
        maxHp = def.hp * hpMul,
        dmg = def.dmg * dmgMul;
  bool get boss => def.boss;
}

class Proj {
  double x, y, vx, vy, dmg, life;
  final bool friendly;
  final int color;
  final double r;
  final bool pierce;
  final Set<Enemy> hitSet = {};
  Proj({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.dmg,
    required this.life,
    required this.friendly,
    required this.color,
    required this.r,
    required this.pierce,
  });
}

class Coin {
  double x, y, vy = -170, life = 14;
  final int value;
  Coin(this.x, this.y, this.value);
}

class Particle {
  double x, y, vx, vy, life, size;
  final double maxLife;
  final int color;
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size)
      : maxLife = life;
}

class Floater {
  final String text;
  double x, y, life = 0.8;
  final int color;
  Floater(this.text, this.x, this.y, this.color);
}

class _Spawn {
  final String id;
  final double x;
  bool done = false;
  _Spawn(this.id, this.x);
}

class GameWorld {
  final int stageIndex;
  final SaveData save;
  final StageDef stage;
  final Random rng;

  late final Knight hero;
  late final double atkMul, speedMul, critChance;
  late final double worldW;

  final List<Enemy> enemies = [];
  final List<Enemy> _incoming = [];
  final List<Proj> projs = [];
  final List<Coin> coins = [];
  final List<Particle> parts = [];
  final List<Floater> floats = [];
  final List<_Spawn> _spawns = [];
  final Map<String, double> skillCd = {};

  double viewW = 480;
  double camX = 0;
  double time = 0;
  double lockMin = 0;
  late double lockMax;

  GameState state = GameState.playing;
  double endTimer = 0;
  int kills = 0, goldEarned = 0, xpEarned = 0, rewardGold = 0;
  bool bossSpawned = false, bossDead = false;
  Enemy? bossRef;

  // Input, written by the on-screen controls.
  double moveAxis = 0;
  bool attackHeld = false;
  bool _jumpReq = false, _dashReq = false;

  GameWorld(this.stageIndex, this.save)
      : stage = kStages[stageIndex],
        rng = Random(stageIndex * 31 + 7) {
    final lv = save.level;
    final maxHp = 100.0 + 20 * save.stat('hp') + 5 * (lv - 1);
    hero = Knight(maxHp, 60);
    atkMul = 1 + 0.12 * save.stat('atk') + 0.03 * (lv - 1);
    speedMul = 1 + 0.05 * save.stat('spd');
    critChance = 0.05 + 0.04 * save.stat('crit');
    worldW = stage.length + 500;
    lockMax = worldW;
    final n = stage.count;
    for (var i = 0; i < n; i++) {
      final id = stage.pool[rng.nextInt(stage.pool.length)];
      final x = 520 + (stage.length - 950) * (i + rng.nextDouble() * 0.8) / n;
      _spawns.add(_Spawn(id, x));
    }
    _spawns.sort((a, b) => a.x.compareTo(b.x));
    for (final s in kSkillList) {
      skillCd[s.id] = 0;
    }
  }

  WeaponDef get weapon => kWeapons[save.weapon] ?? kWeapons['sword']!;

  // ---- input -------------------------------------------------------------
  void requestJump() => _jumpReq = true;
  void requestDash() => _dashReq = true;

  bool skillReady(String id) {
    final def = kSkills[id];
    if (def == null) return false;
    return save.skillLv(id) > 0 &&
        (skillCd[id] ?? 0) <= 0 &&
        hero.mana >= def.mana;
  }

  // ---- main update ---------------------------------------------------------
  void update(double dt) {
    if (state != GameState.playing) {
      endTimer += dt;
      _updateFx(dt);
      return;
    }
    time += dt;
    _updateHero(dt);
    _spawnLogic();
    enemies.addAll(_incoming);
    _incoming.clear();
    for (final e in enemies) {
      _updateEnemy(e, dt);
    }
    enemies.addAll(_incoming);
    _incoming.clear();
    _updateProj(dt);
    _updateCoins(dt);
    _updateFx(dt);
    enemies.removeWhere((e) => e.dead);
    if (state == GameState.playing && bossDead && enemies.isEmpty) {
      _finish(true);
    }
    _camera(dt);
  }

  void _camera(double dt) {
    final maxCam = max(0.0, lockMax - viewW);
    final target = (hero.x - viewW * 0.4).clamp(0.0, maxCam).toDouble();
    camX += (target - camX) * min(1.0, dt * 8);
  }

  // ---- hero ----------------------------------------------------------------
  void _updateHero(double dt) {
    final h = hero;
    h.atkTimer = max(0.0, h.atkTimer - dt);
    h.slashTimer = max(0.0, h.slashTimer - dt);
    h.invuln = max(0.0, h.invuln - dt);
    h.flash = max(0.0, h.flash - dt);
    h.whirl = max(0.0, h.whirl - dt);
    h.dashCd = max(0.0, h.dashCd - dt);
    h.mana = min(h.maxMana, h.mana + 7 * dt);
    for (final k in skillCd.keys.toList()) {
      skillCd[k] = max(0.0, (skillCd[k] ?? 0) - dt);
    }

    if (_dashReq && h.dashCd <= 0 && h.dash <= 0) {
      h.dash = 0.2;
      h.dashCd = 0.9;
      h.invuln = max(h.invuln, 0.25);
      _burst(h.x, h.y - 20, 0xFFFFFFFF, 6);
    }
    _dashReq = false;

    if (h.dash > 0) {
      h.dash -= dt;
      h.vx = h.facing * 420.0;
    } else {
      h.vx = moveAxis * 150 * speedMul;
      if (moveAxis != 0) h.facing = moveAxis > 0 ? 1 : -1;
    }
    if (_jumpReq && h.onGround) {
      h.vy = -430;
      h.onGround = false;
    }
    _jumpReq = false;
    h.vy += 1150 * dt;
    h.x += h.vx * dt;
    h.y += h.vy * dt;
    if (h.y >= kGroundY) {
      h.y = kGroundY;
      h.vy = 0;
      h.onGround = true;
    }
    h.x = h.x.clamp(lockMin + 15, lockMax - 15).toDouble();
    if (attackHeld && h.atkTimer <= 0) _attack();
  }

  void _attack() {
    final h = hero;
    final w = weapon;
    h.atkTimer = w.cooldown;
    h.slashTimer = 0.14;
    final far = h.x + h.facing * (w.reach + 8);
    final rect = Rect.fromLTRB(
        min(h.x, far), h.y - Knight.h - 14, max(h.x, far), h.y);
    for (final e in enemies) {
      if (e.dead) continue;
      final er = Rect.fromLTWH(e.x - e.w / 2, e.y - e.h, e.w, e.h);
      if (!rect.overlaps(er)) continue;
      final crit = rng.nextDouble() < critChance;
      final dmg = w.damage * atkMul * (crit ? 2 : 1) * (0.9 + rng.nextDouble() * 0.2);
      _hitEnemy(e, dmg, 150, 0.2, crit: crit);
    }
  }

  bool castSkill(String id) {
    if (state != GameState.playing) return false;
    if (!skillReady(id)) return false;
    final def = kSkills[id]!;
    final h = hero;
    final lv = save.skillLv(id);
    final pow = 1 + 0.35 * (lv - 1);
    h.mana -= def.mana;
    skillCd[id] = def.cooldown;
    switch (id) {
      case 'fireball':
        projs.add(Proj(
          x: h.x + h.facing * 20,
          y: h.y - 36,
          vx: h.facing * 380.0,
          vy: 0,
          dmg: 22 * pow * atkMul,
          life: 1.6,
          friendly: true,
          color: 0xFFFF7043,
          r: 9,
          pierce: true,
        ));
        break;
      case 'whirl':
        h.whirl = 0.35;
        for (final e in enemies) {
          if (e.dead) continue;
          final dx = e.x - h.x;
          final inY = e.y > h.y - Knight.h - 30 && e.y - e.h < h.y + 10;
          if (dx.abs() < 95 + e.w / 2 && inY) {
            _hitEnemy(e, 16 * pow * atkMul, 220 * (dx >= 0 ? 1 : -1) / h.facing, 0.3,
                crit: false);
          }
        }
        for (var i = 0; i < 18; i++) {
          final a = i / 18 * pi * 2;
          parts.add(Particle(h.x + cos(a) * 20, h.y - 24 + sin(a) * 20,
              cos(a) * 160, sin(a) * 160, 0.35, 0xFF81D4FA, 3));
        }
        break;
      case 'heal':
        final amount = h.maxHp * (0.25 + 0.05 * lv);
        h.hp = min(h.maxHp, h.hp + amount);
        floats.add(Floater('+${amount.round()}', h.x, h.y - 60, 0xFF69F0AE));
        _burst(h.x, h.y - 24, 0xFF69F0AE, 14, speed: 70);
        break;
    }
    return true;
  }

  void _hurtHero(double dmg, double fromX) {
    final h = hero;
    if (h.invuln > 0 || state != GameState.playing) return;
    h.hp -= dmg;
    h.invuln = 0.9;
    h.flash = 0.18;
    h.x += (h.x >= fromX ? 1 : -1) * 16.0;
    h.vy = -180;
    h.onGround = false;
    floats.add(Floater('-${dmg.round()}', h.x, h.y - 60, 0xFFFF5252));
    _burst(h.x, h.y - 24, 0xFFFF5252, 8);
    if (h.hp <= 0) {
      h.hp = 0;
      _finish(false);
    }
  }

  // ---- enemies -------------------------------------------------------------
  Enemy _make(String id, double x) {
    final def = kEnemies[id]!;
    final d = Sprites.dims(def.sprite);
    final h = d.height * def.px;
    final w = d.width * def.px * def.widthFactor;
    final y = def.flying
        ? (def.boss ? kGroundY - 60 : kGroundY - 45 - rng.nextDouble() * 25)
        : kGroundY;
    final hpMul = def.boss ? 1 + 0.1 * stageIndex : 1 + 0.3 * stageIndex;
    final dmgMul = 1 + 0.15 * stageIndex;
    return Enemy(def, x, y, w, h, hpMul, dmgMul);
  }

  void _spawnLogic() {
    final h = hero;
    for (final s in _spawns) {
      if (s.done) continue;
      if (s.x - h.x < viewW * 0.9) {
        s.done = true;
        _incoming.add(_make(s.id, s.x));
      }
    }
    if (!bossSpawned && h.x > stage.length - 260) {
      bossSpawned = true;
      lockMin = stage.length - 320;
      lockMax = stage.length + 380;
      final b = _make(stage.boss, stage.length + 220);
      bossRef = b;
      _incoming.add(b);
    }
  }

  double _approach(double cur, double target, double step) {
    if ((target - cur).abs() <= step) return target;
    return cur + (target > cur ? step : -step);
  }

  void _updateEnemy(Enemy e, double dt) {
    if (e.dead) return;
    e.t += dt;
    e.flash = max(0.0, e.flash - dt);
    final h = hero;
    final dx = h.x - e.x;
    final d = e.def;

    if (e.stun > 0) {
      e.stun -= dt;
      e.x += e.vx * dt;
      e.vx *= 0.9;
    } else {
      if (e.charge <= 0) e.dir = dx >= 0 ? 1 : -1;
      if (d.boss) {
        _bossAi(e, dt, dx);
      } else if (d.flying) {
        final ty = kGroundY - 45 + sin(e.t * 3 + e.x * 0.01) * 25;
        if (dx.abs() < 480) {
          e.x += e.dir * d.speed * dt;
          e.y = _approach(e.y, ty, 90 * dt);
        }
      } else if (d.ranged) {
        final ad = dx.abs();
        if (ad < 130) {
          e.x -= e.dir * d.speed * dt;
        } else if (ad > 230 && ad < 450) {
          e.x += e.dir * d.speed * dt;
        }
        e.shoot -= dt;
        if (e.shoot <= 0 && ad < 380) {
          e.shoot = 2.0;
          projs.add(Proj(
            x: e.x + e.dir * 14,
            y: e.y - e.h * 0.55,
            vx: e.dir * 230.0,
            vy: 0,
            dmg: e.dmg,
            life: 2.2,
            friendly: false,
            color: 0xFFFFE082,
            r: 4,
            pierce: false,
          ));
        }
      } else {
        if (dx.abs() < 420 && dx.abs() > 8) e.x += e.dir * d.speed * dt;
      }
    }

    if (!d.flying) {
      e.vy += 1150 * dt;
      e.y += e.vy * dt;
      if (e.y >= kGroundY) {
        e.y = kGroundY;
        e.vy = 0;
      }
    }
    if (d.boss) {
      e.x = e.x.clamp(lockMin + 20, lockMax - 20).toDouble();
    } else {
      e.x = e.x.clamp(0.0, worldW).toDouble();
    }

    // Contact damage.
    final er = Rect.fromLTWH(e.x - e.w / 2, e.y - e.h, e.w, e.h);
    final hr = Rect.fromLTWH(h.x - Knight.w / 2, h.y - Knight.h, Knight.w, Knight.h);
    if (er.overlaps(hr)) _hurtHero(e.dmg, e.x);
  }

  void _bossAi(Enemy e, double dt, double dx) {
    final d = e.def;
    if (e.charge > 0) {
      e.charge -= dt;
      e.x += e.cdir * d.speed * 3.2 * dt;
      return;
    }
    if (d.flying) {
      final ty = kGroundY - 50 + sin(e.t * 1.6) * 20;
      e.y = _approach(e.y, ty, 60 * dt);
      if (dx.abs() > 150) e.x += e.dir * d.speed * dt;
    } else {
      if (e.y < kGroundY - 2) {
        e.x += e.dir * d.speed * 1.8 * dt;
      } else if (dx.abs() > 50) {
        e.x += e.dir * d.speed * dt;
      }
    }
    e.special -= dt;
    if (e.special > 0) return;
    final low = e.hp < e.maxHp * 0.5;
    e.special = low ? 1.9 : 2.7;
    final pat = d.pattern[e.patIdx % d.pattern.length];
    e.patIdx++;
    switch (pat) {
      case 'charge':
        e.charge = 0.7;
        e.cdir = e.dir;
        break;
      case 'jump':
        if (!d.flying && e.y >= kGroundY - 1) e.vy = -520;
        break;
      case 'fan':
        final sx = e.x;
        final sy = e.y - e.h * 0.5;
        final tx = hero.x;
        final ty = hero.y - 30;
        final base = atan2(ty - sy, tx - sx);
        for (final off in const [-0.3, 0.0, 0.3]) {
          final a = base + off;
          projs.add(Proj(
            x: sx,
            y: sy,
            vx: cos(a) * 210,
            vy: sin(a) * 210,
            dmg: e.dmg * 0.7,
            life: 2.6,
            friendly: false,
            color: 0xFFFF6E40,
            r: 6,
            pierce: false,
          ));
        }
        break;
      case 'summon':
        for (var i = 0; i < 2; i++) {
          final m = _make(i == 0 ? 'slime' : 'bat', e.x + (i == 0 ? -70 : 70));
          m.hp = m.hp * 0.6;
          _incoming.add(m);
        }
        break;
    }
  }

  void _hitEnemy(Enemy e, double dmg, double kb, double stun,
      {required bool crit}) {
    if (e.dead) return;
    e.hp -= dmg;
    e.flash = 0.12;
    if (!e.boss) {
      e.vx = hero.facing * kb;
      e.stun = stun;
    }
    floats.add(Floater(dmg.round().toString(), e.x, e.y - e.h - 6,
        crit ? 0xFFFFEB3B : 0xFFFFFFFF));
    if (e.hp <= 0) _kill(e);
  }

  void _kill(Enemy e) {
    e.dead = true;
    kills++;
    xpEarned += e.def.xp;
    final n = e.boss ? 10 : 1 + rng.nextInt(2);
    final per = max(1, e.def.gold ~/ n);
    for (var i = 0; i < n; i++) {
      final c = Coin(e.x + (rng.nextDouble() - 0.5) * 30, e.y - e.h * 0.5, per);
      c.vy = -120 - rng.nextDouble() * 120;
      coins.add(c);
    }
    _burst(e.x, e.y - e.h * 0.5, e.boss ? 0xFFFFD54F : 0xFFFFFFFF,
        e.boss ? 40 : 10,
        speed: e.boss ? 200 : 110);
    if (e.boss) {
      bossDead = true;
      for (final o in enemies) {
        if (o != e && !o.dead) {
          o.dead = true;
          _burst(o.x, o.y - o.h * 0.5, 0xFFFFFFFF, 8);
        }
      }
    }
  }

  // ---- projectiles, coins, fx ------------------------------------------------
  void _updateProj(double dt) {
    for (final p in projs) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.y > kGroundY) p.life = 0;
      if (p.friendly) {
        for (final e in enemies) {
          if (e.dead || p.hitSet.contains(e)) continue;
          final hit = (p.x - e.x).abs() < e.w / 2 + p.r &&
              p.y > e.y - e.h - p.r &&
              p.y < e.y + p.r;
          if (hit) {
            p.hitSet.add(e);
            _hitEnemy(e, p.dmg, 120, 0.25, crit: false);
            if (!p.pierce) {
              p.life = 0;
              break;
            }
          }
        }
      } else if (hero.invuln <= 0 &&
          (p.x - hero.x).abs() < Knight.w / 2 + p.r &&
          p.y > hero.y - Knight.h - p.r &&
          p.y < hero.y + p.r) {
        _hurtHero(p.dmg, p.x);
        p.life = 0;
      }
    }
    projs.removeWhere((p) => p.life <= 0);
  }

  void _updateCoins(double dt) {
    for (final c in coins) {
      c.vy += 700 * dt;
      c.y += c.vy * dt;
      if (c.y > kGroundY) {
        c.y = kGroundY;
        c.vy = -c.vy * 0.35;
        if (c.vy.abs() < 40) c.vy = 0;
      }
      c.life -= dt;
      final dx = hero.x - c.x;
      final dy = (hero.y - 20) - c.y;
      if (dx.abs() < 60 && dy.abs() < 60) {
        c.x += dx.sign * 260 * dt;
      }
      if (dx.abs() < 18 && dy.abs() < 40) {
        goldEarned += c.value;
        c.life = -1;
        floats.add(Floater('+${c.value}', c.x, c.y - 14, 0xFFFFD54F));
      }
    }
    coins.removeWhere((c) => c.life <= 0);
  }

  void _burst(double x, double y, int color, int n, {double speed = 120}) {
    for (var i = 0; i < n; i++) {
      final a = rng.nextDouble() * pi * 2;
      final s = speed * (0.3 + rng.nextDouble());
      parts.add(Particle(x, y, cos(a) * s, sin(a) * s - 40,
          0.4 + rng.nextDouble() * 0.4, color, 2 + rng.nextDouble() * 3));
    }
  }

  void _updateFx(double dt) {
    for (final p in parts) {
      p.vy += 420 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
    }
    parts.removeWhere((p) => p.life <= 0);
    for (final f in floats) {
      f.y -= 30 * dt;
      f.life -= dt;
    }
    floats.removeWhere((f) => f.life <= 0);
  }

  // ---- end of stage ----------------------------------------------------------
  void _finish(bool won) {
    if (state != GameState.playing) return;
    state = won ? GameState.won : GameState.lost;
    endTimer = 0;
    final bonus = won ? 50 + 30 * stageIndex : 0;
    rewardGold = won ? goldEarned + bonus : goldEarned ~/ 2;
    save.gold += rewardGold;
    save.xp += xpEarned;
    if (won) {
      final next = min(stageIndex + 1, kStages.length - 1);
      save.unlockedStage = max(save.unlockedStage, next);
    }
    save.save();
  }
}
