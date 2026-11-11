import 'package:flutter/material.dart';

import '../game/data.dart';
import '../game/save.dart';

const TextStyle _mono = TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  void _commit() {
    gSave.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF14101F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14101F),
          title: Text('Shop    Gold ${gSave.gold}    Lv ${gSave.level}'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Upgrades'),
            Tab(text: 'Weapons'),
            Tab(text: 'Skills'),
          ]),
        ),
        body: TabBarView(children: [
          _upgrades(),
          _weapons(),
          _skills(),
        ]),
      ),
    );
  }

  Widget _row({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Card(
      color: const Color(0xFF241B38),
      child: ListTile(
        title: Text(title, style: _mono.copyWith(fontSize: 14)),
        subtitle: Text(subtitle, style: _mono.copyWith(fontSize: 11, color: Colors.white70)),
        trailing: trailing,
      ),
    );
  }

  Widget _buyButton(String label, bool enabled, VoidCallback onTap) {
    return ElevatedButton(onPressed: enabled ? onTap : null, child: Text(label));
  }

  Widget _upgrades() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final s in kStatList)
          Builder(builder: (context) {
            final lv = gSave.stat(s.id);
            final maxed = lv >= kMaxStatLevel;
            final cost = statCost(lv);
            return _row(
              title: '${s.name}  (Lv $lv/$kMaxStatLevel)',
              subtitle: s.desc,
              trailing: maxed
                  ? const Text('MAX', style: TextStyle(color: Colors.amber))
                  : _buyButton('$cost g', gSave.gold >= cost, () {
                      gSave.gold -= cost;
                      gSave.stats[s.id] = lv + 1;
                      _commit();
                    }),
            );
          }),
      ],
    );
  }

  Widget _weapons() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final w in kWeaponList)
          Builder(builder: (context) {
            final owned = gSave.owned.contains(w.id);
            final equipped = gSave.weapon == w.id;
            final stats =
                '${w.desc}  DMG ${w.damage.round()}  Reach ${w.reach.round()}  Speed ${(1 / w.cooldown).toStringAsFixed(1)}/s';
            Widget trailing;
            if (equipped) {
              trailing = const Text('EQUIPPED', style: TextStyle(color: Colors.amber));
            } else if (owned) {
              trailing = _buyButton('Equip', true, () {
                gSave.weapon = w.id;
                _commit();
              });
            } else {
              trailing = _buyButton('${w.cost} g', gSave.gold >= w.cost, () {
                gSave.gold -= w.cost;
                gSave.owned.add(w.id);
                gSave.weapon = w.id;
                _commit();
              });
            }
            return _row(title: w.name, subtitle: stats, trailing: trailing);
          }),
      ],
    );
  }

  Widget _skills() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final s in kSkillList)
          Builder(builder: (context) {
            final lv = gSave.skillLv(s.id);
            final maxed = lv >= kMaxSkillLevel;
            final cost = skillCost(s, lv);
            final label = lv == 0 ? 'Unlock $cost g' : 'Upgrade $cost g';
            return _row(
              title: '${s.name}  (Lv $lv/$kMaxSkillLevel)',
              subtitle: '${s.desc}  Mana ${s.mana.round()}  Cooldown ${s.cooldown.toStringAsFixed(1)}s',
              trailing: maxed
                  ? const Text('MAX', style: TextStyle(color: Colors.amber))
                  : _buyButton(label, gSave.gold >= cost, () {
                      gSave.gold -= cost;
                      gSave.skills[s.id] = lv + 1;
                      _commit();
                    }),
            );
          }),
      ],
    );
  }
}
