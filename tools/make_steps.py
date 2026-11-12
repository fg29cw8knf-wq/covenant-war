#!/usr/bin/env python3
"""Footsteps (12 November, Gary: "Do the footsteps").

Writes four takes of one footfall on each kind of ground to
assets/sfx/step_<ground>.wav, step_<ground>_2.wav ... (Sfx picks a take at
random, and moves its pitch and loudness a little each time): snow, grass,
dirt, wood, stone, and (later the same day) the inn's stairs and the river's
shallows. Built from nothing, as the creature voices are
(tools/make_cries.py, whose tools these use): shaped noise, a thump, a
knock. A recording saved under the same name is used instead.

    python3 tools/make_steps.py            every ground
    python3 tools/make_steps.py snow       only that
    python3 tools/make_steps.py --out /tmp/steps

Needs numpy and scipy.
"""
import os
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_cries as mc  # noqa: E402
from make_cries import SR, band, lowpass, highpass, env, n_of, norm, place, formants  # noqa: E402

TAKES = 4
LOUD_WIN = 0.08      # a step is short: its loudest twelfth of a second is what's levelled
LOUD = 0.2
PEAK = 0.8


def grains(secs, per_sec, r, decay=0.997):
    """Many tiny separate crackles (snow giving, grit turning), not a hiss."""
    n = n_of(secs)
    x = np.zeros(n)
    at = 0
    while at < n:
        x[at] = r.uniform(0.3, 1.0) * r.choice([-1.0, 1.0])
        at += max(1, int(SR / r.uniform(per_sec * 0.5, per_sec * 1.6)))
    return signal.lfilter([1.0], [1.0, -decay], x)


def thump(r, hz_from, hz_to, secs, fall=22.0):
    """The weight coming down: a low note falling."""
    t = np.arange(n_of(secs)) / SR
    hz = np.interp(t, [0, secs], [hz_from * r.uniform(0.9, 1.1), hz_to])
    return np.sin(2 * np.pi * np.cumsum(hz) / SR) * np.exp(-t * fall)


def snow(r):
    """Cold snow packing under a boot: a creaking crunch, a soft weight under it."""
    secs = r.uniform(0.2, 0.26)
    n = n_of(secs)
    crunch = band(grains(secs, r.uniform(520, 760), r, 0.9), 700, 4200) * env(secs, 0.06, 0.34, 0.6, 1.5)
    # the squeak of dry snow: a narrow band that rises as it packs
    t = np.arange(n) / SR
    mid = np.interp(t, [0, secs], [r.uniform(850, 1000), r.uniform(1350, 1650)])
    squeak = np.zeros(n)
    raw = r.standard_normal(n)
    for k in range(4):
        a, b = int(n * k / 4), int(n * (k + 1) / 4)
        c = float(np.mean(mid[a:b]))
        squeak[a:b] = band(raw, c * 0.86, c * 1.16)[a:b]
    squeak = squeak * env(secs, 0.15, 0.3, 0.55, 1.3)
    soft = band(r.standard_normal(n), 300, 1800) * env(secs, 0.04, 0.2, 0.76, 2.0)
    under = thump(r, 150, 90, 0.07, 30.0)
    return place([(0.0, norm(crunch) * 0.9 + norm(squeak) * 0.4 + norm(soft) * 0.45), (0.004, under * 0.14)])


def grass(r):
    """Grass brushed and pressed: a soft swish over a softer weight."""
    secs = r.uniform(0.15, 0.2)
    n = n_of(secs)
    swish = band(r.standard_normal(n), 1700, 6500) * env(secs, 0.22, 0.2, 0.58, 1.4)
    blades = band(grains(secs, r.uniform(240, 380), r, 0.8), 2500, 8000) * env(secs, 0.15, 0.3, 0.55)
    under = thump(r, 140, 85, 0.06, 32.0)
    return place([(0.0, norm(swish) * 0.75 + norm(blades) * 0.35), (0.012, under * 0.18)])


def dirt(r):
    """Packed earth: a dull thud, grit turning under the sole."""
    under = thump(r, 175, 95, 0.08, 24.0)
    secs = r.uniform(0.09, 0.13)
    # (the body of it where a phone's small speaker can still say it)
    body = band(r.standard_normal(n_of(0.06)), 190, 720) * env(0.06, 0.06, 0.14, 0.8, 2.0)
    grit = band(grains(secs, r.uniform(380, 560), r, 0.93), 450, 2800) * env(secs, 0.05, 0.25, 0.7, 1.6)
    scuff = band(r.standard_normal(n_of(secs)), 900, 3500) * env(secs, 0.1, 0.2, 0.7, 1.8)
    return place([(0.0, under * 0.5), (0.0, norm(body) * 0.8), (0.003, norm(grit) * 0.55 + norm(scuff) * 0.3)])


def wood(r):
    """A boot on old boards: a hollow knock, sometimes the board answering."""
    secs = 0.2
    n = n_of(secs)
    hit = np.zeros(n)
    k = n_of(0.003)
    hit[:k] = r.standard_normal(k) * np.hanning(k)
    f = r.uniform(0.9, 1.12)
    knock = formants(hit, [(138 * f, 26, 1.0), (305 * f, 48, 0.75), (520 * f, 90, 0.4), (980 * f, 240, 0.16)])
    heel = band(r.standard_normal(n_of(0.012)), 1800, 5200) * env(0.012, 0.1, 0.1, 0.8)
    parts = [(0.0, norm(knock)), (0.0, norm(heel) * 0.28)]
    if r.random() < 0.5:
        # the board giving a little under the weight
        c_secs = 0.09
        pulses = np.zeros(n_of(c_secs))
        at = 0.0
        while at < len(pulses) - 1:
            pulses[int(at)] = r.uniform(0.5, 1.0)
            at += SR / r.uniform(150, 240)
        creak = formants(pulses, [(640 * f, 60, 1.0), (1350 * f, 140, 0.5)]) * env(c_secs, 0.3, 0.3, 0.4)
        parts.append((0.03, norm(creak) * 0.13))
    return place(parts)


def stone(r):
    """A hard sole on flagstones: a sharp tap, a little scuff, almost no body."""
    tap_secs = 0.02
    tap = band(r.standard_normal(n_of(tap_secs)), 1500, 6000) * env(tap_secs, 0.05, 0.1, 0.85, 2.2)
    secs = 0.1
    hit = np.zeros(n_of(secs))
    k = n_of(0.002)
    hit[:k] = r.standard_normal(k)
    f = r.uniform(0.92, 1.1)
    body = formants(hit, [(230 * f, 70, 1.0), (470 * f, 130, 0.6), (1150 * f, 380, 0.3)])
    s_secs = r.uniform(0.05, 0.08)
    scuff = band(grains(s_secs, 900, r, 0.7), 2200, 7000) * env(s_secs, 0.2, 0.2, 0.6, 1.5)
    return place([(0.0, norm(tap) * 0.8), (0.0, norm(body) * 0.7), (0.012, norm(scuff) * 0.22)])


def stairs(r):
    """A tread of the inn's stairs: the board rings higher than a floor's, and creaks."""
    secs = 0.22
    n = n_of(secs)
    hit = np.zeros(n)
    k = n_of(0.003)
    hit[:k] = r.standard_normal(k) * np.hanning(k)
    f = r.uniform(1.25, 1.5)
    knock = formants(hit, [(150 * f, 22, 1.0), (330 * f, 40, 0.9), (610 * f, 80, 0.5), (1150 * f, 260, 0.2)])
    heel = band(r.standard_normal(n_of(0.012)), 1800, 5200) * env(0.012, 0.1, 0.1, 0.8)
    c_secs = r.uniform(0.1, 0.16)
    pulses = np.zeros(n_of(c_secs))
    at = 0.0
    rate = r.uniform(130, 210)
    while at < len(pulses) - 1:
        pulses[int(at)] = r.uniform(0.5, 1.0)
        at += SR / (rate * r.uniform(0.85, 1.2))
        rate *= 1.03
    creak = formants(pulses, [(720 * f, 60, 1.0), (1500 * f, 150, 0.5)]) * env(c_secs, 0.3, 0.3, 0.4)
    return place([(0.0, norm(knock)), (0.0, norm(heel) * 0.25), (0.035, norm(creak) * r.uniform(0.14, 0.26))])


def water(r):
    """A foot into the shallows: the slap of it, the water closing after."""
    secs = r.uniform(0.26, 0.34)
    n = n_of(secs)
    slap = band(r.standard_normal(n), 600, 6500) * env(secs, 0.03, 0.12, 0.85, 2.2)
    spray = band(grains(secs, r.uniform(500, 900), r, 0.6), 3000, 9000) * env(secs, 0.1, 0.3, 0.6, 1.6)
    plop_t = np.arange(n_of(0.09)) / SR
    plop = np.sin(2 * np.pi * np.cumsum(np.interp(plop_t, [0, 0.09], [r.uniform(380, 460), 190.0])) / SR) * np.exp(-plop_t * 30.0)
    parts = [(0.0, norm(slap) * 0.9 + norm(spray) * 0.3), (0.008, plop * 0.45)]
    at = 0.06
    for _ in range(int(r.integers(3, 6))):
        b_secs = r.uniform(0.02, 0.05)
        f = np.interp(np.arange(n_of(b_secs)) / SR, [0, b_secs], [r.uniform(500, 1500), r.uniform(900, 2400)])
        parts.append((at, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(len(f)) * r.uniform(0.12, 0.3)))
        at += r.uniform(0.03, 0.07)
    return place(parts)


GROUNDS = {"snow": snow, "grass": grass, "dirt": dirt, "wood": wood, "stone": stone, "stairs": stairs, "water": water}
ROOM = {"snow": (0.03, 0.05), "grass": (0.04, 0.07), "dirt": (0.04, 0.08), "wood": (0.07, 0.16), "stone": (0.09, 0.2),
    "stairs": (0.08, 0.18), "water": (0.05, 0.1)}


def finish(x):
    x = highpass(x, 50.0)
    x = x - np.mean(x)
    fade = n_of(0.002)
    x[:fade] *= np.linspace(0, 1, fade)
    tail = n_of(0.02)
    x[-tail:] *= np.linspace(1, 0, tail) ** 2
    win = n_of(LOUD_WIN)
    heard = highpass(x, mc.HEARD_FROM)   # (levelled by what an ear, and a phone's speaker, gets of it)
    power = np.convolve(heard * heard, np.ones(win) / win, mode="same")
    x = x * (LOUD / (float(np.sqrt(np.max(power))) + 1e-9))
    top = float(np.max(np.abs(x)))
    return x * (PEAK / top) if top > PEAK else x


def main():
    args = sys.argv[1:]
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")
    if "--out" in args:
        i = args.index("--out")
        out_dir = args[i + 1]
        del args[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for name in (args or list(GROUNDS)):
        for take in range(TAKES):
            r = np.random.default_rng(1112 + 97 * take + sum(ord(c) for c in name))
            mc.rng = r   # (the shared tools' own dice: the room's tail)
            secs, amount = ROOM[name]
            x = finish(mc.room(GROUNDS[name](r), secs, amount))
            path = os.path.join(out_dir, "step_%s%s.wav" % (name, "" if take == 0 else "_%d" % (take + 1)))
            mc.save(path, x)
            print("%-6s take %d  %.2f s  rms %.3f  -> %s" % (name, take + 1, len(x) / SR, float(np.sqrt(np.mean(x * x))), path))


if __name__ == "__main__":
    main()
