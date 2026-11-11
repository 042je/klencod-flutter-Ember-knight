import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'achievements.dart';
import 'audio.dart';
import 'data.dart';
import 'engine.dart';
import 'render.dart';
import 'save.dart';

const TextStyle _mono = TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

/// A round on-screen button that reports press and release separately, so
/// several buttons can be held at the same time (multi-touch).
class HoldButton extends StatelessWidget {
  final String label;
  final double size;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool dim;

  const HoldButton({
    super.key,
    required this.label,
    required this.size,
    required this.color,
    required this.onDown,
    required this.onUp,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(dim ? 55 : 150),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _mono.copyWith(fontSize: size > 70 ? 14 : 11),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int stageIndex;
  const GameScreen({super.key, required this.stageIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late GameWorld world;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool paused = false;
  late int stageIndex;
  String? banner; // achievement banner text
  double bannerT = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    stageIndex = widget.stageIndex;
    world = GameWorld(stageIndex, gSave);
    _ticker = createTicker(_tick)..start();
    Sfx.music('bgm');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app pauses the game and the music.
    if (state != AppLifecycleState.resumed && world.state == GameState.playing && !paused) {
      _setPaused(true);
    }
  }

  void _setPaused(bool p) {
    setState(() => paused = p);
    if (p) {
      Sfx.pauseMusic();
    } else {
      Sfx.resumeMusic();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033).toDouble();
    _last = elapsed;
    if (!paused) world.update(dt);
    if (banner == null && Ach.pending.isNotEmpty) {
      banner = Ach.pending.removeAt(0);
      bannerT = 3.0;
    } else if (banner != null) {
      bannerT -= dt;
      if (bannerT <= 0) banner = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    world.settle(); // pay out a defeat that was waiting for a checkpoint decision
    Sfx.stopMusic();
    _ticker.dispose();
    super.dispose();
  }

  void _restart(int index) {
    world.settle();
    Sfx.music('bgm');
    setState(() {
      stageIndex = index;
      world = GameWorld(index, gSave);
      paused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, c) {
        final zoom = c.maxHeight / kViewH;
        world.viewW = c.maxWidth / zoom;
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GamePainter(world))),
          _hud(),
          ..._controls(),
          if (paused && world.state == GameState.playing) _pauseOverlay(),
          if (!paused && world.state == GameState.playing && world.choices.isNotEmpty)
            _perkOverlay(),
          if (banner != null) _banner(),
          if (world.state != GameState.playing && world.endTimer > 1.0) _resultOverlay(),
        ]);
      }),
    );
  }

  Widget _bar(double frac, Color color, double width) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.black54,
        border: Border.all(color: Colors.white54),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: frac.clamp(0.0, 1.0).toDouble(),
        child: Container(color: color),
      ),
    );
  }

  Widget _hud() {
    final h = world.hero;
    final boss = world.bossRef;
    return Positioned.fill(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Stack(children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HP ${h.hp.ceil()}/${h.maxHp.round()}', style: _mono.copyWith(fontSize: 11)),
                  _bar(h.hp / h.maxHp, Colors.redAccent, 160),
                  const SizedBox(height: 3),
                  _bar(h.mana / h.maxMana, Colors.lightBlueAccent, 160),
                  const SizedBox(height: 3),
                  Text('Checkpoint ${world.checkpointIdx + 1}/${world.checkpoints.length}',
                      style: _mono.copyWith(fontSize: 10, color: Colors.lightGreenAccent)),
                  Text('Gold ${world.goldEarned}   Lv ${gSave.level}   Run Lv ${world.perkLevel}',
                      style: _mono.copyWith(fontSize: 11, color: Colors.amber)),
                  if (world.hits >= 2)
                    Text('x${world.hits} HITS',
                        style: _mono.copyWith(fontSize: 15, color: Colors.yellowAccent)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(world.stage.name, style: _mono.copyWith(fontSize: 11)),
                  if (boss != null && !boss.dead && world.bossSpawned) ...[
                    const SizedBox(height: 2),
                    Text(boss.def.name, style: _mono.copyWith(fontSize: 11, color: Colors.orangeAccent)),
                    _bar(boss.hp / boss.maxHp, Colors.deepOrange, 240),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _controls() {
    final playing = world.state == GameState.playing;
    if (!playing) return const [];
    final skillIds = kSkillList.map((s) => s.id).toList();
    return [
      // Pause.
      Positioned(
        top: 6,
        right: 8,
        child: IconButton(
          onPressed: () => _setPaused(true),
          icon: const Icon(Icons.pause_circle_outline, color: Colors.white70, size: 34),
        ),
      ),
      // Movement.
      Positioned(
        left: 20,
        bottom: 24,
        child: HoldButton(
          label: '<',
          size: 72,
          color: Colors.blueGrey,
          onDown: () => world.moveAxis = -1,
          onUp: () {
            if (world.moveAxis < 0) world.moveAxis = 0;
          },
        ),
      ),
      Positioned(
        left: 108,
        bottom: 24,
        child: HoldButton(
          label: '>',
          size: 72,
          color: Colors.blueGrey,
          onDown: () => world.moveAxis = 1,
          onUp: () {
            if (world.moveAxis > 0) world.moveAxis = 0;
          },
        ),
      ),
      // Actions.
      Positioned(
        right: 20,
        bottom: 20,
        child: HoldButton(
          label: 'ATK',
          size: 84,
          color: Colors.redAccent,
          onDown: () => world.attackHeld = true,
          onUp: () => world.attackHeld = false,
        ),
      ),
      Positioned(
        right: 118,
        bottom: 30,
        child: HoldButton(
          label: 'JUMP',
          size: 66,
          color: Colors.greenAccent,
          onDown: world.requestJump,
          onUp: () {},
        ),
      ),
      Positioned(
        right: 40,
        bottom: 116,
        child: HoldButton(
          label: 'DASH',
          size: 56,
          color: Colors.purpleAccent,
          dim: world.hero.dashCd > 0,
          onDown: world.requestDash,
          onUp: () {},
        ),
      ),
      for (var i = 0; i < skillIds.length; i++)
        Positioned(
          right: 110.0 + i * 60,
          bottom: 106,
          child: HoldButton(
            label: kSkills[skillIds[i]]!.icon,
            size: 52,
            color: Colors.orangeAccent,
            dim: !world.skillReady(skillIds[i]),
            onDown: () => world.castSkill(skillIds[i]),
            onUp: () {},
          ),
        ),
    ];
  }

  Widget _panel(String title, Color titleColor, List<Widget> children) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(170),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: _mono.copyWith(fontSize: 30, color: titleColor)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 200,
        child: ElevatedButton(onPressed: onTap, child: Text(text)),
      ),
    );
  }

  Widget _banner() {
    return Positioned(
      top: 56,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(banner ?? '', style: _mono.copyWith(fontSize: 12, color: Colors.amber)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _perkOverlay() {
    return _panel('LEVEL UP!  Pick a perk', Colors.amber, [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < world.choices.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 150,
                height: 110,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2250),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => setState(() {
                    world.moveAxis = 0;
                    world.attackHeld = false;
                    world.choosePerk(i);
                  }),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(world.choices[i].name,
                          textAlign: TextAlign.center,
                          style: _mono.copyWith(fontSize: 13, color: Colors.amber)),
                      const SizedBox(height: 6),
                      Text(world.choices[i].desc,
                          textAlign: TextAlign.center,
                          style: _mono.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ]);
  }

  Widget _pauseOverlay() {
    return _panel('PAUSED', Colors.white, [
      _btn('Resume', () => _setPaused(false)),
      _btn(gSave.sound ? 'Sound: ON' : 'Sound: OFF', () {
        setState(() {
          gSave.sound = !gSave.sound;
          Sfx.setEnabled(gSave.sound);
        });
        gSave.save();
      }),
      _btn('Restart', () => _restart(stageIndex)),
      _btn('Quit to menu', () => Navigator.of(context).pop()),
    ]);
  }

  Widget _resultOverlay() {
    final won = world.state == GameState.won;
    final hasNext = won && stageIndex + 1 < kStages.length;
    return _panel(won ? 'VICTORY' : 'DEFEAT', won ? Colors.amber : Colors.redAccent, [
      Text('Gold +${world.rewardGold}   XP +${world.xpEarned}   Kills ${world.kills}',
          style: _mono.copyWith(fontSize: 13)),
      if (won && !hasNext)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('You cleared every stage!', style: _mono.copyWith(fontSize: 13, color: Colors.amber)),
        ),
      const SizedBox(height: 10),
      if (!won && world.canRespawn)
        _btn('Continue (checkpoint)', () => setState(() => world.respawn())),
      if (hasNext) _btn('Next stage', () => _restart(stageIndex + 1)),
      _btn(won ? 'Replay stage' : 'Try again', () => _restart(stageIndex)),
      _btn('Menu', () => Navigator.of(context).pop()),
    ]);
  }
}
