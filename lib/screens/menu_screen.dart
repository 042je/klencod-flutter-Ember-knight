import 'package:flutter/material.dart';

import '../game/audio.dart';
import '../game/data.dart';
import '../game/game_screen.dart';
import '../game/save.dart';
import 'achievements_screen.dart';
import 'shop_screen.dart';

const TextStyle _mono = TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1030), Color(0xFF4A1F3D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                    child: Image.asset(
                      'assets/img/portrait.png',
                      width: 170,
                      height: 170,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 170, height: 170),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('EMBER KNIGHT',
                          style: _mono.copyWith(fontSize: 38, color: Colors.amber, letterSpacing: 3)),
                      const SizedBox(height: 4),
                      Text('Pixel Action RPG  -  Offline',
                          style: _mono.copyWith(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('Level ${gSave.level}    Gold ${gSave.gold}',
                          style: _mono.copyWith(fontSize: 14, color: Colors.amberAccent)),
                      const SizedBox(height: 10),
                      _menuButton('PLAY', () async {
                        await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StageSelectScreen()));
                        if (mounted) setState(() {});
                      }),
                      _menuButton('SHOP & UPGRADES', () async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ShopScreen()));
                        if (mounted) setState(() {});
                      }),
                      _menuButton('ACHIEVEMENTS  ${gSave.achievements.length}/${kAchList.length}', () async {
                        await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                        if (mounted) setState(() {});
                      }),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            gSave.sound = !gSave.sound;
                            Sfx.setEnabled(gSave.sound);
                          });
                          gSave.save();
                        },
                        icon: Icon(gSave.sound ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white70),
                        label: Text(gSave.sound ? 'Sound ON' : 'Sound OFF',
                            style: _mono.copyWith(fontSize: 12, color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 260,
        height: 42,
        child: ElevatedButton(
          onPressed: () {
            Sfx.play('click');
            onTap();
          },
          child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14101F),
      appBar: AppBar(
        title: const Text('Select stage'),
        backgroundColor: const Color(0xFF14101F),
      ),
      body: SafeArea(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(14),
          itemCount: kStages.length,
          itemBuilder: (context, i) {
            final s = kStages[i];
            final locked = i > gSave.unlockedStage;
            final boss = kEnemies[s.boss]!;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: locked
                    ? null
                    : () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => GameScreen(stageIndex: i)));
                        if (mounted) setState(() {});
                      },
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: locked ? Colors.white24 : Colors.amber, width: 2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(s.sky1).withAlpha(locked ? 60 : 255),
                        Color(s.sky2).withAlpha(locked ? 60 : 255),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: _mono.copyWith(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Boss: ${boss.name}', style: _mono.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Enemies: ${s.pool.map((e) => kEnemies[e]!.name).join(', ')}',
                          style: _mono.copyWith(fontSize: 11)),
                      const Spacer(),
                      Center(
                        child: Icon(locked ? Icons.lock : Icons.play_arrow,
                            color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
