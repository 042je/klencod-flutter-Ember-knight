#!/usr/bin/env python3
"""Synthesises every sound used by the game into assets/audio/*.wav (no external files, fully original).
Run: python3 tools/gen_audio.py   (needs numpy)"""
import os, wave
import numpy as np

SR = 22050
rng = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)

def t(d): return np.arange(int(SR * d)) / SR
def midi(n): return 440.0 * 2 ** ((n - 69) / 12)

def osc(kind, freq, d, duty=0.5):
    x = t(d)
    ph = np.cumsum(np.broadcast_to(freq, x.shape)) / SR  # supports sweeps
    ph = ph % 1.0
    if kind == 'sq': return np.where(ph < duty, 1.0, -1.0)
    if kind == 'tri': return 4 * np.abs(ph - 0.5) - 1
    if kind == 'saw': return 2 * ph - 1
    if kind == 'noise': return rng.uniform(-1, 1, x.shape)
    raise ValueError(kind)

def env(d, a=0.005, r=0.1, curve=2.0):
    x = t(d); n = len(x)
    e = np.ones(n)
    na = max(1, int(a * SR)); e[:na] = np.linspace(0, 1, na)
    nr = max(1, min(n, int(r * SR))); e[-nr:] *= np.linspace(1, 0, nr) ** curve
    return e

def sweep(f0, f1, d): return np.linspace(f0, f1, int(SR * d))
def fit(x, n):
    return np.pad(x, (0, max(0, n - len(x))))[:n]
def mix(*parts):
    n = max(len(p) for p in parts)
    return sum(fit(p, n) for p in parts)
def seq(*parts): return np.concatenate(parts)
def lp(x, k):  # crude low-pass (moving average)
    k = max(1, int(k)); return np.convolve(x, np.ones(k) / k, mode='same')

def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype('<i2').tobytes())

def note(kind, n, d, vol=1.0, duty=0.5, r=None):
    return osc(kind, midi(n), d, duty) * env(d, 0.004, r if r is not None else d * 0.6) * vol

# ---------------- sound effects ----------------
d = .12; save('slash', lp(osc('noise', 0, d), 6) * env(d, .002, .1) * 1.5 + osc('sq', sweep(900, 300, d), d, .25) * env(d, .002, .1) * .3)
d = .22; save('slash2', lp(osc('noise', 0, d), 10) * env(d, .002, .2) * 1.6 + osc('saw', sweep(500, 90, d), d) * env(d, .002, .2) * .5)
d = .10; save('hit', mix(osc('noise', 0, d) * env(d, .001, .09) * .8, osc('sq', sweep(220, 70, d), d, .5) * env(d, .001, .09)))
d = .18; save('crit', mix(osc('noise', 0, d) * env(d, .001, .1) * .6, osc('sq', sweep(220, 70, .1), .1) * env(.1, .001, .09), seq(np.zeros(int(.03 * SR)), osc('sq', midi(88), .15, .25) * env(.15, .001, .14) * .7)))
d = .16; save('jump', osc('sq', sweep(260, 620, d), d, .25) * env(d, .003, .12))
d = .20; save('dash', lp(osc('noise', 0, d), 14) * env(d, .03, .16) * 2.0)
d = .32; save('fire', mix(lp(osc('noise', 0, d), 5) * env(d, .005, .3) * .8, osc('saw', sweep(700, 150, d), d) * env(d, .005, .3) * .5))
d = .40; wob = 1 + .15 * np.sin(2 * np.pi * 14 * t(d)); save('whirl', mix(osc('saw', sweep(200, 520, d) * wob, d) * env(d, .02, .3) * .5, lp(osc('noise', 0, d), 8) * env(d, .02, .3)))
save('heal', seq(*[note('tri', n, .09, 1, r=.08) for n in (72, 76, 79, 84)]))
save('coin', seq(note('sq', 83, .06, .8, .25, .05), note('sq', 88, .16, .8, .25, .15)))
d = .30; save('hurt', osc('saw', sweep(400, 90, d), d) * env(d, .002, .28) + osc('noise', 0, d) * env(d, .001, .1) * .4)
d = .34; save('die', mix(lp(osc('noise', 0, d), 4) * env(d, .002, .3), osc('sq', sweep(400, 60, d), d, .5) * env(d, .002, .3) * .6))
d = 1.0; save('boss', mix(osc('saw', sweep(90, 45, d) * (1 + .05 * np.sin(2 * np.pi * 9 * t(d))), d) * env(d, .05, .8) * .8, lp(osc('noise', 0, d), 12) * env(d, .05, .8) * 1.1))
save('levelup', seq(*[note('sq', n, .1, .8, .25, .09) for n in (60, 64, 67)], note('sq', 72, .3, .8, .25, .28)))
save('pick', seq(note('tri', 76, .07, 1, r=.06), note('tri', 83, .14, 1, r=.13)))
save('checkpoint', seq(note('tri', 67, .1, 1, r=.09), note('tri', 72, .1, 1, r=.09), note('tri', 79, .3, 1, r=.28)))
save('ach', seq(*[note('sq', n, .09, .7, .25, .08) for n in (72, 76, 79)], mix(note('sq', 84, .4, .7, .25, .38), note('sq', 79, .4, .5, .5, .38))))
save('win', seq(*[note('sq', n, .14, .7, .25, .12) for n in (60, 64, 67, 72)], mix(note('sq', 76, .6, .7, .25, .55), note('sq', 67, .6, .6, .5, .55), note('tri', 52, .6, .9, r=.55))))
save('lose', seq(*[note('saw', n, .22, .7, r=.2) for n in (64, 62, 59)], note('saw', 52, .6, .8, r=.58)))
d = .05; save('click', osc('sq', midi(84), d, .5) * env(d, .001, .045))

# ---------------- music ----------------
def song(bpm, chords, melody_seed, lead_oct=12, lead='sq', dens=0.75, hat=True, bars_rep=1):
    beat = 60.0 / bpm; step = beat / 2  # 8th notes
    r = np.random.default_rng(melody_seed)
    total_steps = len(chords) * 8 * bars_rep
    n = int(total_steps * step * SR) + SR
    out = np.zeros(n)
    def put(sig, at):
        i = int(at * SR); out[i:i + len(sig)] += sig[:max(0, n - i)] if i < n else 0
    s = 0
    for rep in range(bars_rep):
        for root, quality in chords:
            third = 3 if quality == 'm' else 4
            tones = [root, root + third, root + 7]
            scale = [root + k for k in (0, 3, 5, 7, 10)] if quality == 'm' else [root + k for k in (0, 2, 4, 7, 9)]
            for bar_step in range(8):
                at = s * step
                # bass on beats
                if bar_step % 2 == 0:
                    put(note('tri', root - 24 + (12 if bar_step in (4, 6) else 0), step * 1.9, .9, r=step * 1.5), at)
                # arpeggio pad
                put(note('sq', tones[bar_step % 3] + 12, step * .9, .22, .125, r=step * .7), at)
                # lead melody
                if r.random() < dens:
                    nt = scale[r.integers(0, len(scale))] + lead_oct + 12
                    dur = step * (2 if r.random() < .35 else 1)
                    put(note(lead, nt, dur * .95, .4, .25, r=dur * .8), at)
                if hat and bar_step % 2 == 1:
                    put(lp(osc('noise', 0, .05), 2) * env(.05, .001, .045) * .25, at)
                s += 1
    L = int(total_steps * step * SR)
    tail = out[L:L + int(.0 * SR)]
    return out[:L]

# field theme: A minor, Am F C G (x2 bars)
bgm = song(112, [(57, 'm'), (53, 'M'), (60, 'M'), (55, 'M')] * 2, 11, 0, 'sq', .7)
save('bgm', bgm, .55)
# boss theme: faster, D minor / Bb / C / A
boss = song(150, [(50, 'm'), (46, 'M'), (48, 'M'), (45, 'M')] * 2, 23, 0, 'saw', .9)
save('bgm_boss', boss, .5)
print('written to', OUT)
