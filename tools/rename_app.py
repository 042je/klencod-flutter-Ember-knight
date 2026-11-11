#!/usr/bin/env python3
"""Rename the template: python3 tools/rename_app.py --name my_game --id com.me.mygame --label "My Game"
--name  : Dart package name (lowercase, underscores)
--id    : Android package / applicationId (e.g. com.me.mygame)
--label : name shown under the app icon
"""
import argparse, os, re, shutil, sys

OLD_ID = "com.example.app"
OLD_NAME = "my_app"
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ap = argparse.ArgumentParser()
ap.add_argument("--name", required=True)
ap.add_argument("--id", required=True)
ap.add_argument("--label", required=True)
a = ap.parse_args()
if not re.fullmatch(r"[a-z][a-z0-9_]*", a.name): sys.exit("bad --name (lowercase letters, digits, _)")
if not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+", a.id): sys.exit("bad --id (like com.me.mygame)")

def sub(path, old, new):
    p = os.path.join(root, path)
    s = open(p, encoding="utf-8").read()
    open(p, "w", encoding="utf-8").write(s.replace(old, new))

sub("pubspec.yaml", f"name: {OLD_NAME}", f"name: {a.name}")
sub("android/app/build.gradle.kts", OLD_ID, a.id)
sub("android/app/src/main/AndroidManifest.xml", 'android:label="My App"', f'android:label="{a.label}"')

base = os.path.join(root, "android/app/src/main/kotlin")
old_dir = os.path.join(base, *OLD_ID.split("."))
new_dir = os.path.join(base, *a.id.split("."))
if old_dir != new_dir:
    os.makedirs(new_dir, exist_ok=True)
    f = os.path.join(old_dir, "MainActivity.kt")
    s = open(f, encoding="utf-8").read().replace(f"package {OLD_ID}", f"package {a.id}")
    open(os.path.join(new_dir, "MainActivity.kt"), "w", encoding="utf-8").write(s)
    os.remove(f)
    # remove now-empty old dirs
    d = old_dir
    while d != base and os.path.isdir(d) and not os.listdir(d):
        os.rmdir(d); d = os.path.dirname(d)
print("done. Now: flutter pub get && flutter build apk --release")
