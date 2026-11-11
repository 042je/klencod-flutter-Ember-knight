import 'dart:math';

import 'package:flutter/material.dart';

import 'engine.dart';
import 'sprites.dart';

/// Draws the whole game world. Everything is drawn in world units and scaled
/// so that the view is always [kViewH] units tall.
class GamePainter extends CustomPainter {
  final GameWorld world;
  GamePainter(this.world);

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = size.height / kViewH;
    final viewW = size.width / zoom;
    final st = world.stage;
    canvas.save();
    canvas.scale(zoom);

    // Sky.
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(st.sky1), Color(st.sky2)],
      ).createShader(Rect.fromLTWH(0, 0, viewW, kViewH));
    canvas.drawRect(Rect.fromLTWH(0, 0, viewW, kViewH), sky);

    // Parallax hills.
    final hill = Paint()..color = Color(st.hill);
    final off = -(world.camX * 0.3) % 260;
    for (double x = off - 260; x < viewW + 260; x += 260) {
      final p = Path()
        ..moveTo(x, kGroundY)
        ..lineTo(x + 130, kGroundY - 90)
        ..lineTo(x + 260, kGroundY)
        ..close();
      canvas.drawPath(p, hill);
    }
    final hill2 = Paint()..color = Color(st.hill).withAlpha(150);
    final off2 = -(world.camX * 0.55) % 180;
    for (double x = off2 - 180; x < viewW + 180; x += 180) {
      canvas.drawCircle(Offset(x + 90, kGroundY + 10), 55, hill2);
    }

    // Ground.
    canvas.drawRect(
        Rect.fromLTWH(0, kGroundY, viewW, kViewH - kGroundY), Paint()..color = Color(st.ground));
    canvas.drawRect(
        Rect.fromLTWH(0, kGroundY, viewW, 6), Paint()..color = Color(st.grass));
    final tile = Paint()..color = const Color(0x22000000);
    final toff = -world.camX % 32;
    for (double x = toff - 32; x < viewW + 32; x += 32) {
      canvas.drawRect(Rect.fromLTWH(x, kGroundY + 14, 16, 8), tile);
      canvas.drawRect(Rect.fromLTWH(x + 16, kGroundY + 30, 16, 8), tile);
    }

    // World layer.
    canvas.save();
    canvas.translate(-world.camX, 0);

    // Boss arena markers.
    if (world.bossSpawned) {
      final wall = Paint()..color = const Color(0x55FFFFFF);
      canvas.drawRect(Rect.fromLTWH(world.lockMin - 6, 0, 4, kGroundY), wall);
      canvas.drawRect(Rect.fromLTWH(world.lockMax + 2, 0, 4, kGroundY), wall);
    }

    for (var i = 0; i < world.checkpoints.length; i++) {
      final cx = world.checkpoints[i];
      final active = i <= world.checkpointIdx;
      canvas.drawRect(Rect.fromLTWH(cx - 1.5, kGroundY - 54, 3, 54), Paint()..color = const Color(0xFFB0BEC5));
      final flag = Path()
        ..moveTo(cx + 1.5, kGroundY - 54)
        ..lineTo(cx + 26, kGroundY - 45)
        ..lineTo(cx + 1.5, kGroundY - 36)
        ..close();
      canvas.drawPath(flag, Paint()..color = active ? const Color(0xFF69F0AE) : const Color(0xFF78909C));
    }

    for (final c in world.coins) {
      if (c.heart) {
        canvas.drawCircle(Offset(c.x, c.y - 6), 6, Paint()..color = const Color(0xFFE53935));
        final cross = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromLTWH(c.x - 1.5, c.y - 10, 3, 8), cross);
        canvas.drawRect(Rect.fromLTWH(c.x - 4, c.y - 7.5, 8, 3), cross);
        continue;
      }
      canvas.drawCircle(Offset(c.x, c.y - 4), 4, Paint()..color = const Color(0xFFFFC107));
      canvas.drawCircle(Offset(c.x - 1, c.y - 5), 1.5, Paint()..color = const Color(0xFFFFF8E1));
    }

    for (final e in world.enemies) {
      if (e.dead) continue;
      Sprites.draw(canvas, e.def.sprite, e.x, e.y, e.def.px,
          flip: e.dir < 0, flash: e.flash > 0);
      if (!e.boss && e.hp < e.maxHp) {
        const bw = 28.0;
        final by = e.y - e.h - 8;
        canvas.drawRect(Rect.fromLTWH(e.x - bw / 2, by, bw, 3), Paint()..color = const Color(0xFF3E2723));
        canvas.drawRect(
            Rect.fromLTWH(e.x - bw / 2, by, bw * (e.hp / e.maxHp).clamp(0.0, 1.0).toDouble(), 3),
            Paint()..color = const Color(0xFFEF5350));
      }
    }

    // Hero.
    final h = world.hero;
    final blink = h.invuln > 0 && ((world.time * 20).floor() % 2 == 0);
    final String frame;
    if (h.slashTimer > 0) {
      frame = 'hero_atk';
    } else if (!h.onGround) {
      frame = 'hero_jump';
    } else if (h.vx.abs() > 1) {
      frame = (world.time * 10).floor() % 2 == 0 ? 'hero_run1' : 'hero_run2';
    } else {
      frame = 'hero';
    }
    Sprites.draw(canvas, frame, h.x, h.y, 3,
        flip: h.facing < 0, flash: h.flash > 0, alpha: blink ? 0.45 : 1);

    // Weapon slash.
    if (h.slashTimer > 0) {
      final w = world.weapon;
      final prog = 1 - h.slashTimer / h.slashDur;
      final fin = h.comboStep == 3;
      final reach = w.reach * (fin ? 1.3 : 1.0);
      final center = Offset(h.x + h.facing * reach * 0.35, h.y - 26);
      final rect = Rect.fromCenter(center: center, width: reach * 1.5, height: fin ? 70 : 56);
      final start = h.facing > 0 ? -1.1 : pi - 1.1;
      final sp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fin ? 8 : 5
        ..strokeCap = StrokeCap.round
        ..color = Color(w.color).withAlpha((255 * (1 - prog * 0.6)).round());
      canvas.drawArc(rect, start, 0.4 + 1.8 * prog, false, sp);
    }
    if (h.whirl > 0) {
      final r = 95 * (1 - h.whirl / 0.35) + 10;
      canvas.drawCircle(
          Offset(h.x, h.y - 24),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xCC81D4FA));
    }

    for (final p in world.projs) {
      final paint = Paint()..color = Color(p.color);
      canvas.drawCircle(Offset(p.x, p.y), p.r, paint);
      canvas.drawCircle(Offset(p.x, p.y), p.r * 0.5, Paint()..color = const Color(0xCCFFFFFF));
    }

    for (final p in world.parts) {
      final a = (255 * (p.life / p.maxLife)).clamp(0.0, 255.0).toInt();
      canvas.drawRect(Rect.fromLTWH(p.x, p.y, p.size, p.size), Paint()..color = Color(p.color).withAlpha(a));
    }

    for (final f in world.floats) {
      final a = (255 * (f.life / 0.8)).clamp(0.0, 255.0).toInt();
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: Color(f.color).withAlpha(a),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x - tp.width / 2, f.y));
    }

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
