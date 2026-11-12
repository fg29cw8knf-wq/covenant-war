#!/usr/bin/env python3
"""Stand-in creature voices (12 November, Gary: "adding the sound effect to
the game and cards and creatures is good implement that").

Writes one cry per kind of creature to assets/sfx/cry_<kind>.wav: a bark, a
yip, a snarl, a hoot, a hiss, a roar, a clack, a grind, a creak, a squeak, a
grunt, a chime, a glassy shimmer, a squawk. They are built from nothing
(tones through mouth-shaped filters, shaped noise), so they are stand-ins:
a recording saved as assets/sfx/cry_<kind>.ogg or cry_<creature id>.ogg is
used instead of them (Sfx.cry_sound). The game pitches each cry by the
creature's size and by the moment (called, attacking, falling), so one file
serves every creature of its kind.

    python3 tools/make_cries.py            every kind
    python3 tools/make_cries.py hound fox  only those
    python3 tools/make_cries.py --out /tmp/cries

Needs numpy and scipy.
"""
import os
import sys
import wave

import numpy as np
from scipy import signal

SR = 44100
PEAK = 0.8           # (the game's other effects peak at 0.6 to 0.88)
LOUD = 0.2           # (and their loudest fifth of a second runs 0.15 to 0.3)
rng = np.random.default_rng(1112)


# ------------------------------------------------------------------ tools ---

def n_of(secs):
    return int(round(secs * SR))


def curve(points, secs):
    """A line through (time 0..1, value) points, as long as secs."""
    n = n_of(secs)
    xs = np.array([p[0] for p in points]) * (n - 1)
    ys = np.array([p[1] for p in points], dtype=float)
    return np.interp(np.arange(n), xs, ys)


def smooth_noise(n, hz, depth):
    """Slow random wobble round 1.0 (for a throat that isn't a machine)."""
    k = max(1, int(SR / max(1.0, hz)))
    pts = rng.standard_normal(n // k + 3)
    w = np.interp(np.arange(n) / k, np.arange(len(pts)), pts)
    return 1.0 + depth * w


def voice(f0, bright=1.0, jitter=0.02, breath=0.0, rough_hz=0.0, rough=0.0):
    """A throat: a buzz at f0 (an array of Hz), its harmonics falling away,
    with jitter in the pitch, breath (noise) in it, and a rattle (rough_hz)."""
    n = len(f0)
    f = f0 * smooth_noise(n, 35.0, jitter)
    phase = np.cumsum(f) / SR
    out = np.zeros(n)
    top = int(min(60, (SR * 0.45) / max(40.0, float(np.max(f)))))
    for h in range(1, top + 1):
        out += np.sin(2 * np.pi * h * phase + rng.uniform(0, 0.4)) / (h ** (1.0 / max(0.2, bright)))
    out /= np.max(np.abs(out)) + 1e-9
    if breath > 0.0:
        out = out * (1.0 - breath) + rng.standard_normal(n) * 0.35 * breath
    if rough > 0.0 and rough_hz > 0.0:
        r = np.cumsum(np.full(n, rough_hz) * smooth_noise(n, 12.0, 0.15)) / SR
        out *= 1.0 - rough * (0.5 + 0.5 * signal.sawtooth(2 * np.pi * r, 0.85))
    return out


def formants(x, bands):
    """A mouth: the sound through resonances [(Hz, width Hz, gain)]."""
    out = np.zeros(len(x))
    for hz, width, gain in bands:
        hz = min(hz, SR * 0.45)
        b, a = signal.iirpeak(hz, hz / width, fs=SR)
        out += signal.lfilter(b, a, x) * gain
    return out


def mouth_glide(x, a_bands, b_bands, bend=1.0):
    """A mouth that changes shape from a_bands to b_bands over the sound."""
    k = np.linspace(0.0, 1.0, len(x)) ** bend
    return formants(x, a_bands) * (1.0 - k) + formants(x, b_bands) * k


def band(x, lo, hi, order=2):
    lo = max(20.0, lo)
    hi = min(hi, SR * 0.47)
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x, hz, order=2):
    sos = signal.butter(order, hz, btype="low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x, hz, order=2):
    sos = signal.butter(order, hz, btype="high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def env(secs, attack, hold, release, power=1.6):
    """Up in `attack`, held, away over `release` (each a share of secs)."""
    n = n_of(secs)
    t = np.arange(n) / max(1, n - 1)
    e = np.ones(n)
    up = t < attack
    e[up] = (t[up] / max(1e-6, attack)) ** 0.7
    down = t > attack + hold
    e[down] = np.clip(1.0 - (t[down] - attack - hold) / max(1e-6, release), 0.0, 1.0) ** power
    return e


def drive(x, amount):
    """A throat pushed hard: soft clipping."""
    x = x / (np.max(np.abs(x)) + 1e-9)
    return np.tanh(x * amount) / np.tanh(amount)


def place(parts):
    """Lays [(start secs, samples)] on one line."""
    end = max(n_of(s) + len(x) for s, x in parts)
    out = np.zeros(end)
    for s, x in parts:
        i = n_of(s)
        out[i:i + len(x)] += x
    return out


def norm(x, level=1.0):
    """The sound at a set peak, so parts can be mixed by ear-sized numbers."""
    return x / (np.max(np.abs(x)) + 1e-9) * level


def room(x, secs=0.09, amount=0.16):
    """A little air round it (a short soft tail), so it isn't bone dry."""
    n = n_of(secs * 2.6)
    t = np.arange(n) / SR
    tail = rng.standard_normal(n) * np.exp(-t / (secs * 0.55))
    tail[:n_of(0.006)] = 0.0   # (a breath of space before the room answers)
    tail = lowpass(highpass(tail, 250.0), 4800.0)
    wet = signal.fftconvolve(x, tail)
    wet = wet / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(x))
    out = np.concatenate([x, np.zeros(n - 1)])
    return out + wet * amount * 1.6


def finish(x):
    x = highpass(x, 45.0)
    x = x - np.mean(x)
    fade = n_of(0.004)
    x[:fade] *= np.linspace(0, 1, fade)
    tail = n_of(0.03)
    x[-tail:] *= np.linspace(1, 0, tail) ** 2
    # as loud as each other to the ear: the loudest fifth of a second of each
    # at LOUD, but never a peak over PEAK (a click stays a click)
    win = n_of(0.2)
    power = np.convolve(x * x, np.ones(win) / win, mode="same")
    loud = float(np.sqrt(np.max(power)))
    x = x * (LOUD / (loud + 1e-9))
    top = float(np.max(np.abs(x)))
    if top > PEAK:
        x = x * (PEAK / top)
    return x


# ------------------------------------------------------------------ cries ---

def hound():
    """A low growl catching into one hard bark."""
    g_secs = 0.16
    g = voice(curve([(0, 92), (1, 120)], g_secs), bright=1.3, jitter=0.05, breath=0.25, rough_hz=31, rough=0.75)
    g = norm(drive(formants(g, [(420, 220, 1.0), (1050, 380, 0.5), (2300, 700, 0.2)]), 1.8)) * env(g_secs, 0.45, 0.25, 0.3) * 0.42
    b_secs = 0.30
    f0 = curve([(0, 200), (0.1, 330), (0.35, 255), (1, 135)], b_secs)
    b = voice(f0, bright=1.5, jitter=0.045, breath=0.3, rough_hz=64, rough=0.35)
    b = mouth_glide(b, [(520, 260, 1.0), (1150, 420, 0.7), (2500, 800, 0.3)],
        [(760, 320, 1.0), (1500, 480, 0.75), (2800, 900, 0.35)], 0.5)
    b = drive(b, 2.6) * env(b_secs, 0.05, 0.12, 0.83, 1.9)
    chuff = norm(band(rng.standard_normal(n_of(0.05)), 900, 4200)) * env(0.05, 0.1, 0.1, 0.8) * 0.35
    return room(place([(0.0, g), (0.15, b), (0.145, chuff)]))


def fox():
    """Two sharp yips, the second lower."""
    def yip(top, secs):
        f0 = curve([(0, top * 0.62), (0.22, top), (0.5, top * 0.9), (1, top * 0.5)], secs)
        y = voice(f0, bright=1.1, jitter=0.03, breath=0.12, rough_hz=95, rough=0.3)
        y = formants(y, [(1500, 500, 1.0), (2900, 800, 0.8), (4300, 1200, 0.3)])
        return drive(y, 1.8) * env(secs, 0.07, 0.1, 0.83, 1.6)
    return room(place([(0.0, yip(1280, 0.15)), (0.2, yip(1120, 0.19))]), 0.07, 0.14)


def cat():
    """A hiss opening into a rising, falling snarl."""
    secs = 0.62
    f0 = curve([(0, 300), (0.25, 520), (0.55, 610), (1, 290)], secs)
    v = voice(f0, bright=1.25, jitter=0.035, breath=0.2, rough_hz=47, rough=0.5)
    v = mouth_glide(v, [(520, 260, 1.0), (1700, 520, 0.6), (3100, 900, 0.3)],
        [(980, 380, 1.0), (2050, 600, 0.8), (3400, 1000, 0.35)], 0.7)
    v = drive(v, 2.2) * env(secs, 0.22, 0.3, 0.48, 1.5)
    h_secs = 0.26
    h = norm(band(rng.standard_normal(n_of(h_secs)), 3200, 9000)) * env(h_secs, 0.12, 0.3, 0.58) * 0.3
    return room(place([(0.0, h), (0.07, v)]))


def bird():
    """A harsh falling squawk, and a shorter one after it."""
    def squawk(top, secs, level):
        f0 = curve([(0, top * 0.8), (0.12, top), (1, top * 0.7)], secs)
        s = voice(f0, bright=1.4, jitter=0.03, breath=0.25, rough_hz=105, rough=0.85)
        s = formants(s, [(1700, 600, 1.0), (3000, 900, 0.9), (4600, 1400, 0.4)])
        return drive(s, 2.4) * env(secs, 0.06, 0.4, 0.54, 1.4) * level
    return room(place([(0.0, squawk(980, 0.3, 1.0)), (0.36, squawk(900, 0.17, 0.7))]), 0.1, 0.16)


def owl():
    """Two soft hoots, the second longer."""
    def hoot(hz, secs):
        n = n_of(secs)
        f = np.full(n, float(hz)) * (1.0 + 0.012 * np.sin(2 * np.pi * 5.5 * np.arange(n) / SR)) * curve([(0, 0.94), (0.15, 1.0), (1, 0.97)], secs)
        ph = np.cumsum(f) / SR
        t = np.sin(2 * np.pi * ph) + 0.22 * np.sin(4 * np.pi * ph) + 0.07 * np.sin(6 * np.pi * ph)
        air = norm(band(rng.standard_normal(n), 350, 1500)) * 0.07
        return (t + air) * env(secs, 0.2, 0.35, 0.45, 1.3)
    return room(place([(0.0, hoot(415, 0.2)), (0.3, hoot(400, 0.4))]), 0.12, 0.22)


def sprite():
    """A quick rising run of small bells over a flutter of wings."""
    def bell(hz, secs):
        t = np.arange(n_of(secs)) / SR
        b = np.sin(2 * np.pi * hz * t) + 0.45 * np.sin(2 * np.pi * hz * 2.76 * t) * np.exp(-t * 26) + 0.2 * np.sin(2 * np.pi * hz * 5.4 * t) * np.exp(-t * 44)
        return b * np.exp(-t * 11.0)
    notes = [(0.0, 1568.0), (0.075, 1975.5), (0.15, 2349.3), (0.235, 3136.0)]
    bells = place([(s, bell(hz, 0.34) * (0.7 + 0.1 * i)) for i, (s, hz) in enumerate(notes)])
    secs = len(bells) / SR
    n = len(bells)
    wings = norm(band(rng.standard_normal(n), 4200, 10500)) * (0.5 + 0.5 * np.sin(2 * np.pi * 31.0 * np.arange(n) / SR)) * env(secs, 0.1, 0.35, 0.55) * 0.12
    return room(norm(bells) + wings, 0.11, 0.2)


def serpent():
    """A long hiss with a rattle in it, a low breath under it."""
    secs = 0.8
    n = n_of(secs)
    raw = rng.standard_normal(n)
    hi = band(raw, 4200, 10500)
    lo = band(raw, 2400, 6200)
    k = np.linspace(0, 1, n)
    hiss = hi * (1.0 - 0.55 * k) + lo * 0.75 * k
    t = np.arange(n) / SR
    rattle = 1.0 - 0.42 * (0.5 + 0.5 * signal.sawtooth(2 * np.pi * 21.0 * t * (1.0 + 0.25 * k), 0.7)) * np.clip((k - 0.2) * 3.0, 0, 1)
    hiss = hiss * rattle * env(secs, 0.1, 0.5, 0.4, 1.4)
    throat = voice(curve([(0, 150), (1, 110)], secs), bright=0.8, jitter=0.06, breath=0.5, rough_hz=24, rough=0.5)
    throat = norm(formants(throat, [(380, 240, 1.0), (900, 400, 0.4)])) * env(secs, 0.2, 0.4, 0.4)
    return room(norm(hiss) + throat * 0.3, 0.1, 0.14)


def drake():
    """A roar: low, rough, swelling and dying."""
    secs = 0.92
    f0 = curve([(0, 82), (0.3, 128), (0.6, 112), (1, 70)], secs)
    v = voice(f0, bright=1.5, jitter=0.07, breath=0.35, rough_hz=27, rough=0.8)
    v = mouth_glide(v, [(380, 240, 1.0), (980, 420, 0.7), (2300, 800, 0.3)],
        [(620, 300, 1.0), (1250, 480, 0.75), (2600, 900, 0.35)], 0.6)
    n = len(v)
    breath = norm(band(rng.standard_normal(n), 500, 3400))
    r = drive(norm(v) + breath * 0.22, 2.6) * env(secs, 0.16, 0.42, 0.42, 1.5)
    under = norm(lowpass(voice(f0 * 0.5, bright=0.6, jitter=0.05), 160.0)) * env(secs, 0.2, 0.4, 0.4) * 0.4
    return room(r + under, 0.13, 0.2)


def shell():
    """Quick dry clicks of plate on plate, then a hollow knock."""
    def click(hz, secs, level):
        n = n_of(secs)
        hit = np.zeros(n)
        hit[:n_of(0.004)] = rng.standard_normal(n_of(0.004))
        c = formants(hit, [(hz, hz / 9.0, 1.0), (hz * 2.07, hz / 5.0, 0.6), (hz * 3.4, hz / 3.0, 0.25)])
        return c / (np.max(np.abs(c)) + 1e-9) * level
    parts = []
    at = 0.0
    for i, gap in enumerate([0.07, 0.058, 0.048, 0.04, 0.05]):
        parts.append((at, click(1500.0 + 140.0 * (i % 2) - 40.0 * i, 0.07, 0.55 + 0.08 * i)))
        at += gap
    parts.append((at + 0.03, click(215.0, 0.28, 1.0) + click(470.0, 0.28, 0.5)))
    return room(place(parts), 0.08, 0.18)


def stone():
    """Rock grinding on rock, and the weight of it coming down."""
    secs = 0.55
    n = n_of(secs)
    grit = np.zeros(n)
    at = 0
    while at < n:
        grit[at] = rng.uniform(0.4, 1.0) * rng.choice([-1.0, 1.0])
        at += int(SR / rng.uniform(55.0, 170.0))
    grit = signal.lfilter([1.0], [1.0, -0.985], grit)
    grind = formants(grit + rng.standard_normal(n) * 0.05, [(170, 110, 1.0), (330, 160, 0.9), (720, 300, 0.45), (1500, 700, 0.18)])
    grind = norm(grind) * env(secs, 0.3, 0.4, 0.3, 1.2)
    t = np.arange(n_of(0.36)) / SR
    thud = np.sin(2 * np.pi * np.cumsum(np.interp(t, [0, 0.36], [96.0, 42.0])) / SR) * np.exp(-t * 11.0)
    crack = norm(band(rng.standard_normal(n_of(0.05)), 600, 3200)) * env(0.05, 0.05, 0.1, 0.85) * 0.4
    return room(place([(0.0, grind * 0.8), (0.46, thud), (0.455, crack)]), 0.12, 0.2)


def wood():
    """Old timber creaking under a weight, leaves stirring."""
    secs = 0.78
    n = n_of(secs)
    # stick and slip: pulses that come faster as the creak rises, never evenly
    rate = curve([(0, 48), (0.45, 120), (0.75, 150), (1, 85)], secs)
    pulses = np.zeros(n)
    at = 0.0
    while at < n - 1:
        pulses[int(at)] = rng.uniform(0.55, 1.0)
        at += SR / (rate[int(at)] * rng.uniform(0.82, 1.2))
    creak = formants(pulses, [(430, 70, 1.0), (910, 110, 0.8), (1680, 190, 0.5), (2600, 320, 0.2)])
    creak = norm(creak) * env(secs, 0.18, 0.5, 0.32, 1.3)
    groan = norm(formants(voice(curve([(0, 68), (0.6, 92), (1, 60)], secs), bright=1.0, jitter=0.06, rough_hz=17, rough=0.6),
        [(260, 150, 1.0), (560, 220, 0.5)])) * env(secs, 0.3, 0.35, 0.35)
    leaves = norm(band(rng.standard_normal(n), 2600, 8000) * smooth_noise(n, 14.0, 0.6).clip(0, 3)) * env(secs, 0.3, 0.3, 0.4)
    return room(creak + groan * 0.45 + leaves * 0.06, 0.11, 0.18)


def rodent():
    """Three quick squeaks."""
    def squeak(top, secs, level):
        f0 = curve([(0, top * 0.75), (0.3, top), (1, top * 0.66)], secs)
        ph = np.cumsum(f0 * smooth_noise(len(f0), 60.0, 0.015)) / SR
        s = np.sin(2 * np.pi * ph) + 0.3 * np.sin(4 * np.pi * ph) + 0.1 * np.sin(6 * np.pi * ph)
        return s * env(secs, 0.12, 0.2, 0.68, 1.4) * level
    return room(place([(0.0, squeak(3300, 0.075, 0.85)), (0.105, squeak(3650, 0.07, 1.0)), (0.2, squeak(3000, 0.1, 0.8))]), 0.06, 0.12)


def beast():
    """A snort and a short deep grunt."""
    secs = 0.36
    f0 = curve([(0, 128), (0.3, 188), (1, 104)], secs)
    v = voice(f0, bright=1.3, jitter=0.05, breath=0.3, rough_hz=38, rough=0.55)
    v = mouth_glide(v, [(430, 240, 1.0), (980, 380, 0.6), (2200, 800, 0.25)],
        [(600, 280, 1.0), (1150, 420, 0.6), (2400, 900, 0.25)], 0.6)
    v = drive(v, 2.4) * env(secs, 0.1, 0.3, 0.6, 1.6)
    s_secs = 0.12
    snort = norm(band(rng.standard_normal(n_of(s_secs)), 700, 2800)) * env(s_secs, 0.15, 0.25, 0.6) * 0.4
    return room(place([(0.0, snort), (0.09, v)]), 0.1, 0.17)


def astral():
    """Glass singing: stacked fifths that swell out of nothing, a whisper of
    pages under them (the Scrivener, the Loomwarden, the Unspent Hour)."""
    secs = 0.95
    n = n_of(secs)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for i, hz in enumerate([587.3, 880.0, 1318.5, 1760.0, 2637.0]):
        for det in (-1.6, 1.9):
            out += np.sin(2 * np.pi * (hz + det * (1 + i * 0.3)) * t + rng.uniform(0, 6.28)) * (0.8 ** i)
    out = out / np.max(np.abs(out)) * env(secs, 0.36, 0.14, 0.5, 2.0)
    ping_t = np.arange(n_of(0.5)) / SR
    ping = (np.sin(2 * np.pi * 2637.0 * ping_t) + 0.5 * np.sin(2 * np.pi * 3520.0 * ping_t)) * np.exp(-ping_t * 9.0) * 0.4
    pages = norm(band(rng.standard_normal(n), 2200, 6500) * smooth_noise(n, 22.0, 0.7).clip(0, 3)) * env(secs, 0.3, 0.2, 0.5) * 0.07
    return room(place([(0.0, out + pages), (0.33, ping)]), 0.14, 0.26)


CRIES = {
    "hound": hound, "fox": fox, "cat": cat, "bird": bird, "owl": owl, "sprite": sprite,
    "serpent": serpent, "drake": drake, "shell": shell, "stone": stone, "wood": wood,
    "rodent": rodent, "beast": beast, "astral": astral,
}


def save(path, x):
    data = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def main():
    args = sys.argv[1:]
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")
    if "--out" in args:
        i = args.index("--out")
        out_dir = args[i + 1]
        del args[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for name in (args or list(CRIES)):
        x = finish(CRIES[name]())
        path = os.path.join(out_dir, "cry_%s.wav" % name)
        save(path, x)
        print("%-8s %.2f s  rms %.3f  -> %s" % (name, len(x) / SR, float(np.sqrt(np.mean(x * x))), path))


if __name__ == "__main__":
    main()
