import 'package:flutter/material.dart';

import '../game/data.dart';
import '../game/save.dart';

const TextStyle _mono = TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final done = gSave.achievements.length;
    return Scaffold(
      backgroundColor: const Color(0xFF14101F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14101F),
        title: Text('Achievements  $done/${kAchList.length}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(
                'Kills ${gSave.totalKills}    Best combo ${gSave.bestCombo}    Bosses ${gSave.bosses.length}/5',
                style: _mono.copyWith(fontSize: 12, color: Colors.white70),
              ),
            ),
            for (final a in kAchList) _tile(a, gSave.achievements.contains(a.id)),
          ],
        ),
      ),
    );
  }

  Widget _tile(AchDef a, bool got) {
    return Card(
      color: got ? const Color(0xFF2E2250) : const Color(0xFF1C162C),
      child: ListTile(
        leading: Icon(got ? Icons.emoji_events : Icons.lock_outline,
            color: got ? Colors.amber : Colors.white38),
        title: Text(a.name,
            style: _mono.copyWith(fontSize: 14, color: got ? Colors.amber : Colors.white70)),
        subtitle: Text(a.desc, style: _mono.copyWith(fontSize: 11, color: Colors.white60)),
        trailing: Text('+${a.reward}g',
            style: _mono.copyWith(fontSize: 12, color: got ? Colors.amber : Colors.white38)),
      ),
    );
  }
}
