# Flutter template (Android) — lessons learned

Use this as the starting point for every new app. It already builds on the Klencod IDE CI
(Flutter stable 3.47.x, Java 17).

## Start a new app
1. Copy this folder.
2. `python3 tools/rename_app.py --name my_game --id com.me.mygame --label "My Game"`
3. Put images in `assets/img/`, sounds in `assets/audio/`, write code in `lib/`.
4. `flutter pub get` then `flutter build apk --release`.

## Why the folder looks like this
- `android/` is committed on purpose. The IDE's CI runs only `flutter pub get` + `flutter build apk`,
  it never runs `flutter create` and ignores any extra workflow file. Without `android/` the build fails with
  "android/app/build.gradle not found".
- `gradlew` and `gradle-wrapper.jar` are NOT needed in the repo: Flutter injects them at build time.
- `android/local.properties` is NOT committed: Flutter creates it on `pub get`.

## Versions that work (Flutter 3.47.2)
- AGP 8.11.1  (`android/settings.gradle.kts`)  — Flutter 3.47 rejects anything below 8.11.1.
- Gradle 8.14 (`android/gradle/wrapper/gradle-wrapper.properties`) — Flutter warns it wants 9.1+ "soon" (warning only).
- Kotlin 2.2.20 (`android/settings.gradle.kts`) — do NOT use the `kotlinOptions { }` block (removed in Kotlin 2.2).
- Java 17 (`compileOptions` in `android/app/build.gradle.kts`).
- `audioplayers ^6.x` (5.x is too old for this toolchain). Now enabled in pubspec.yaml.

## If a build fails
Read the error, it names the exact minimum version it wants. Raise only that one file:
- "AGP ... lower than minimum X"      -> `settings.gradle.kts` (com.android.application version)
- "Gradle ... at least X"            -> `gradle-wrapper.properties` (distributionUrl)
- Kotlin errors                      -> `settings.gradle.kts` (org.jetbrains.kotlin.android version)
- Dart compile errors                -> the error shows file + line in `lib/`.

## Release signing
`release` is signed with the debug key so it installs for testing. For the Play Store create a real keystore.

## Ember Knight (game added on top of this template)
- `lib/main.dart`          entry point: landscape + immersive, loads sprites and the save, runs `MyApp`.
- `lib/game/data.dart`     weapons, skills, enemies, bosses, stages, upgrade costs.
- `lib/game/engine.dart`   game loop logic: movement, combat, AI, bosses, projectiles, coins, win/lose.
- `lib/game/render.dart`   CustomPainter that draws the world.
- `lib/game/sprites.dart`  pixel art defined as character maps, rasterised once (no image assets).
- `lib/game/game_screen.dart` HUD, touch controls, pause and result overlays.
- `lib/game/save.dart`     local progress via `shared_preferences` (fully offline).
- `lib/screens/`           main menu, stage select, shop.
Changes to the template: `shared_preferences` enabled in pubspec.yaml, Android orientation set to
`sensorLandscape`, app label set to "Ember Knight". Not yet compiled: run `flutter pub get` and
`flutter analyze` first and fix anything it reports.

## Ember Knight update 2
- App icon: `android/app/src/main/res/mipmap-*/ic_launcher.png` (pixel portrait). Menu portrait: `assets/img/portrait.png`.
- Build pitfall: a file named `res/drawable/ic_launcher.png` made `mergeReleaseResources` fail (AAPT could not compile it).
  The launcher icon lives only in `mipmap-*`; never add an icon to `drawable/`.
- New: 3-hit combo (3rd hit is a heavy finisher), hit counter, roguelike perks chosen on run level-up
  (`kPerkList` in data.dart, applied in engine.dart), heart pickups, weapon rarity + 2 new weapons,
  hero run/jump/attack frames (lavender hero palette).
- Still not compiled here: run the CI build and fix any Dart error it prints (file + line).

## Ember Knight update 3
- Sound: `lib/game/audio.dart` (`Sfx`). 20 effects + 2 music loops in `assets/audio/*.wav`, synthesised by
  `python3 tools/gen_audio.py` (needs numpy; only re-run if you want to change sounds). Errors in audio are swallowed
  so the game never crashes because of sound. Sound on/off is saved (menu + pause screen).
- Checkpoints: 2 flags per stage (34% and 67%). Reaching one heals 30%. After a defeat, "Continue (checkpoint)" respawns
  there (boss fight: at the arena entrance). Rewards of a defeat are paid only when you give up (`settle()`).
- Achievements: 14 in `kAchList` (data.dart), logic in `lib/game/achievements.dart`, screen in
  `lib/screens/achievements_screen.dart`. Each pays gold once and shows a banner in game.
- If the build fails on audioplayers (Gradle/Kotlin message), comment it out in pubspec.yaml and make `Sfx` methods no-ops.
- `android/app/build.gradle.kts` deletes `res/drawable/ic_launcher.png` at configuration time, so that stray file can no longer break the build.
- A valid `res/drawable/ic_launcher.png` is shipped on purpose: if the repo already holds a broken file with that name
  (e.g. a JPEG saved with a .png extension), uploading this zip overwrites it with a file AAPT can compile.
