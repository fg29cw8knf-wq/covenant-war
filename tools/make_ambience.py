#!/usr/bin/env python3
"""A quiet bed of sound for each place, under its music (12 November, Gary:
"Yes re sound effects", to "a quiet background sound for each place: the
taproom's fire, birds and voices on the green, the Thornwood at night").

Writes one loop per place to assets/sfx/amb_<name>.ogg, each LOOP_SECS long
and made to join its own start without a seam (the Ambience player loops
it). Built from nothing, as the creature voices and the footsteps are
(tools/make_cries.py, whose tools these use), out of a few layers: a breeze,
leaves, birds, crickets, an owl, far voices, a hearth, a house on fire, a
river, a drip. A recording saved under the same name is used instead.

    python3 tools/make_ambience.py              every bed
    python3 tools/make_ambience.py fire night   only those
    python3 tools/make_ambience.py --out /tmp/amb --wav   (keeps the .wav too)

Needs numpy, scipy and ffmpeg (for the .ogg).
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_cries as mc  # noqa: E402
from make_cries import SR, band, lowpass, highpass, env, n_of, norm, formants, voice, curve  # noqa: E402

LOOP_SECS = 24.0
N = n_of(LOOP_SECS)
JOIN = 1.5            # seconds over which a layer's end is folded into its start
LOUD = 0.07           # a bed is quiet: its level over the whole loop (above mc.HEARD_FROM)
PEAK = 0.7


# ------------------------------------------------------------------ tools ---

def looped(make):
    """A layer of steady sound that joins its own start: `make(n)` gives n
    samples, a little more than the loop, and its tail is folded in."""
    over = n_of(JOIN)
    x = make(N + over)
    k = np.linspace(0.0, 1.0, over)
    out = x[:N].copy()
    out[:over] = x[:over] * np.sqrt(k) + x[N:N + over] * np.sqrt(1.0 - k)
    return out


def put(buf, at_secs, x, level=1.0):
    """Lays a sound on the loop at a time, round the join if it runs over."""
    idx = (n_of(at_secs) + np.arange(len(x))) % len(buf)
    buf[idx] += x * level


def slow(n, hz, depth, r):
    """A slow wander round 1 (a breeze rising and falling)."""
    k = max(1, int(SR / hz))
    pts = r.standard_normal(n // k + 3)
    w = np.interp(np.arange(n) / k, np.arange(len(pts)), pts)
    return np.clip(1.0 + depth * w, 0.05, 3.0)


def far(x, r, secs=0.22, amount=0.45):
    """Heard from a way off: a room's worth of air round it."""
    mc.rng = r
    return mc.room(x, secs, amount)


# ----------------------------------------------------------------- layers ---

def breeze(r):
    return norm(looped(lambda n: band(r.standard_normal(n), 180, 1500) * slow(n, 0.22, 0.4, r)))


def leaves(r):
    return norm(looped(lambda n: band(r.standard_normal(n), 2200, 7500) * slow(n, 0.3, 0.8, r) ** 2))


def crickets(r, count):
    """A few crickets, each with its own note and its own rate; each rate
    fits the loop a whole number of times, so none stumbles at the join."""
    out = np.zeros(N)
    for _ in range(count):
        hz = r.uniform(3900, 5300)
        chirps = int(round(r.uniform(2.3, 3.4) * LOOP_SECS))
        pulses = int(r.integers(3, 5))
        gap = 1.0 / r.uniform(27, 34)
        plen = n_of(0.013)
        t = np.arange(plen) / SR
        pulse = np.sin(2 * np.pi * hz * t) * np.hanning(plen)
        chirp = np.zeros(n_of(gap * pulses) + plen)
        for p in range(pulses):
            a = n_of(gap * p)
            chirp[a:a + plen] += pulse * (0.7 + 0.3 * p / pulses)
        level = r.uniform(0.25, 1.0)
        start = r.uniform(0, 1.0)
        for i in range(chirps):
            put(out, start + i * LOOP_SECS / chirps, chirp, level * r.uniform(0.85, 1.0))
    return norm(out)


def _tweet(r):
    """One bird's phrase: quick tweets, a trill, or a few sliding whistles."""
    kind = r.choice(["tweets", "trill", "whistle", "tweets"])
    parts = []
    if kind == "tweets":
        top = r.uniform(2800, 5200)
        at = 0.0
        for _ in range(int(r.integers(2, 6))):
            secs = r.uniform(0.05, 0.11)
            up = r.random() < 0.6
            f = curve([(0, top * (0.72 if up else 1.0)), (1, top * (1.0 if up else 0.7))], secs)
            ph = np.cumsum(f) / SR
            parts.append((at, (np.sin(2 * np.pi * ph) + 0.2 * np.sin(4 * np.pi * ph)) * env(secs, 0.15, 0.2, 0.65, 1.3)))
            at += secs + r.uniform(0.03, 0.09)
    elif kind == "trill":
        lo = r.uniform(2900, 3900)
        secs = r.uniform(0.4, 0.8)
        n = n_of(secs)
        t = np.arange(n) / SR
        f = lo * (1.0 + 0.11 * (signal.square(2 * np.pi * r.uniform(17, 25) * t) * 0.5 + 0.5))
        ph = np.cumsum(f) / SR
        parts.append((0.0, np.sin(2 * np.pi * ph) * env(secs, 0.1, 0.6, 0.3, 1.2) * (0.6 + 0.4 * np.sin(2 * np.pi * 21 * t) ** 2)))
    else:
        at = 0.0
        for _ in range(int(r.integers(2, 4))):
            secs = r.uniform(0.16, 0.28)
            a, b = r.uniform(1700, 3100), r.uniform(1700, 3100)
            f = curve([(0, a), (0.6, b), (1, b * 0.96)], secs)
            ph = np.cumsum(f) / SR
            parts.append((at, (np.sin(2 * np.pi * ph) + 0.12 * np.sin(4 * np.pi * ph)) * env(secs, 0.18, 0.4, 0.42, 1.3)))
            at += secs + r.uniform(0.05, 0.14)
    return mc.place(parts)


def birds(r, phrases):
    out = np.zeros(N)
    for _ in range(phrases):
        level = r.uniform(0.15, 1.0)       # (how near it is)
        x = _tweet(r)
        if level < 0.5:
            x = lowpass(far(x, r, 0.2, 0.5), 4200.0)
        else:
            x = far(x, r, 0.12, 0.2)
        put(out, r.uniform(0, LOOP_SECS), x, level)
    return norm(out)


def owl(r):
    def hoot(hz, secs):
        n = n_of(secs)
        ph = np.cumsum(np.full(n, float(hz)) * curve([(0, 0.94), (0.15, 1.0), (1, 0.97)], secs)) / SR
        return (np.sin(2 * np.pi * ph) + 0.2 * np.sin(4 * np.pi * ph)) * env(secs, 0.2, 0.35, 0.45, 1.3)
    out = np.zeros(N)
    call = far(mc.place([(0.0, hoot(400, 0.22)), (0.34, hoot(385, 0.42))]), r, 0.35, 0.7)
    put(out, r.uniform(5, 16), lowpass(call, 1800.0))
    return norm(out)


VOWELS = [[(700, 130, 1.0), (1200, 160, 0.6), (2600, 300, 0.2)], [(400, 110, 1.0), (1900, 220, 0.5), (2600, 300, 0.2)],
    [(320, 100, 1.0), (900, 140, 0.5), (2300, 300, 0.15)], [(520, 120, 1.0), (1500, 180, 0.55), (2500, 300, 0.2)],
    [(600, 120, 1.0), (1000, 150, 0.6), (2500, 300, 0.2)]]


def murmur(r, voices):
    """People talking, too far off for any word: each voice a run of
    syllables in its own pitch, with its own pauses."""
    out = np.zeros(N)
    for _ in range(voices):
        base = r.uniform(95, 135) if r.random() < 0.55 else r.uniform(170, 235)
        level = r.uniform(0.3, 1.0)
        at = r.uniform(0, 3.0)
        while at < LOOP_SECS:
            # a phrase of a few syllables, then a breath or a listen
            for _ in range(int(r.integers(3, 10))):
                secs = r.uniform(0.11, 0.24)
                a = base * r.uniform(0.9, 1.18)
                f0 = curve([(0, a), (1, a * r.uniform(0.86, 1.08))], secs)
                mc.rng = r
                syl = formants(voice(f0, bright=1.0, jitter=0.02, breath=0.15), VOWELS[int(r.integers(0, len(VOWELS)))])
                put(out, at, norm(syl) * env(secs, 0.2, 0.4, 0.4, 1.3), level * r.uniform(0.6, 1.0))
                at += secs + r.uniform(0.02, 0.09)
            at += r.uniform(0.5, 2.6)
    out = band(np.concatenate([out[-n_of(1.0):], out, out[:n_of(1.0)]]), 240, 2600)[n_of(1.0):-n_of(1.0)]
    # (a room's air round them, laid round the join as the voices are)
    tail_n = n_of(0.5)
    tt = np.arange(tail_n) / SR
    tail = lowpass(r.standard_normal(tail_n) * np.exp(-tt / 0.14), 3000.0)
    wet = signal.fftconvolve(np.concatenate([out, out[:tail_n]]), tail)[:N + tail_n]
    wet[:tail_n] += wet[N:N + tail_n]
    wet = wet[:N]
    return norm(out + wet / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(out)) * 0.5)


def fire(r, crackles_a_sec, big):
    """A fire: its low breath, and wood snapping in it (a hearth; `big`, a house)."""
    def roar(n):
        brown = np.cumsum(r.standard_normal(n))
        brown = highpass(brown, 35.0)
        return lowpass(brown, 900.0 if big else 420.0) * slow(n, 5.0, 0.3, r) * slow(n, 0.4, 0.35 if big else 0.2, r)
    low = norm(looped(roar))
    hiss = norm(looped(lambda n: band(r.standard_normal(n), 2500, 8000) * slow(n, 3.0, 0.4, r)))
    snaps = np.zeros(N)
    for _ in range(int(crackles_a_sec * LOOP_SECS)):
        size = r.uniform(0.0, 1.0) ** 3            # (mostly small, a few that make you look)
        secs = 0.002 + 0.012 * size
        mid = r.uniform(1200, 5500) * (1.0 - 0.5 * size)
        c = band(r.standard_normal(n_of(secs) + 64), mid * 0.6, mid * 1.6)[:n_of(secs)] * np.hanning(n_of(secs))
        if size > 0.75:
            # a log settling: a knock under the snap
            t = np.arange(n_of(0.06)) / SR
            c = mc.place([(0.0, c), (0.0, np.sin(2 * np.pi * r.uniform(110, 190) * t) * np.exp(-t * 60) * 0.6)])
        put(snaps, r.uniform(0, LOOP_SECS), c / (np.max(np.abs(c)) + 1e-9), 0.12 + 0.88 * size)
    out = low * (1.0 if big else 0.55) + norm(snaps) * (0.9 if big else 0.8) + hiss * (0.22 if big else 0.1)
    if big:
        # timbers going: a few long splitting cracks
        for _ in range(5):
            secs = r.uniform(0.12, 0.3)
            n = n_of(secs)
            g = np.zeros(n)
            at = 0
            while at < n:
                g[at] = r.uniform(0.4, 1.0)
                at += max(1, int(SR / r.uniform(120, 420)))
            put(out, r.uniform(0, LOOP_SECS), norm(band(g, 500, 4200)) * env(secs, 0.1, 0.3, 0.6), 0.55)
    return norm(out)


def river(r):
    """Running water: a wash, and the many small voices of it over stones."""
    wash = norm(looped(lambda n: band(r.standard_normal(n), 350, 3800) * slow(n, 0.6, 0.18, r)))
    high = norm(looped(lambda n: band(r.standard_normal(n), 3000, 9000) * slow(n, 1.5, 0.3, r)))
    bub = np.zeros(N)
    for _ in range(int(70 * LOOP_SECS)):
        secs = r.uniform(0.018, 0.06)
        f = curve([(0, r.uniform(450, 1900)), (1, r.uniform(700, 2600))], secs)
        b = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(len(f))
        put(bub, r.uniform(0, LOOP_SECS), b, r.uniform(0.1, 1.0) ** 2)
    return norm(wash * 0.8 + high * 0.25 + norm(bub) * 0.5)


def drips(r, count):
    """Water finding its way down into a cellar, one drop at a time."""
    out = np.zeros(N)
    for _ in range(count):
        secs = 0.09
        f = curve([(0, r.uniform(700, 1000)), (0.25, r.uniform(1300, 1900)), (1, r.uniform(1100, 1500))], secs)
        d = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-np.arange(len(f)) / SR * 45.0)
        put(out, r.uniform(0, LOOP_SECS), far(d, r, 0.45, 0.8), r.uniform(0.35, 1.0))
    air = norm(looped(lambda n: band(r.standard_normal(n), 90, 420) * slow(n, 0.2, 0.25, r)))
    return norm(norm(out) + air * 0.18)


def knocks(r, count):
    """A mug set down, a bench shifted: the small sounds of a full room."""
    out = np.zeros(N)
    for _ in range(count):
        n = n_of(0.16)
        hit = np.zeros(n)
        hit[:n_of(0.003)] = r.standard_normal(n_of(0.003))
        f = r.uniform(0.8, 1.5)
        put(out, r.uniform(0, LOOP_SECS), far(norm(formants(hit, [(210 * f, 40, 1.0), (460 * f, 80, 0.6), (980 * f, 200, 0.2)])), r, 0.2, 0.4), r.uniform(0.3, 1.0))
    return norm(out)


# ------------------------------------------------------------------- beds ---

def bed_fire(r):
    """The taproom's hearth."""
    return fire(r, 7.0, False)


def bed_tavern(r):
    """The taproom of an evening: the hearth, the room talking, mugs."""
    return fire(r, 6.0, False) * 0.6 + murmur(r, 12) * 0.5 + knocks(r, 6) * 0.2


def bed_cellar(r):
    return drips(r, 7)


def bed_green_day(r):
    """Ashford's green by day: birds, a breeze, people about their day."""
    return birds(r, 22) * 0.75 + breeze(r) * 0.3 + murmur(r, 5) * 0.14


def bed_dusk(r):
    """The sun going: the first crickets, the last birds."""
    return crickets(r, 3) * 0.35 + birds(r, 7) * 0.45 + breeze(r) * 0.3


def bed_night(r):
    """A night out of doors: crickets, the leaves, an owl."""
    return crickets(r, 5) * 0.5 + leaves(r) * 0.22 + breeze(r) * 0.18 + owl(r) * 0.3


def bed_festival(r):
    """The festival night on the green: the whole village talking."""
    return murmur(r, 16) * 0.6 + crickets(r, 3) * 0.2 + breeze(r) * 0.15 + knocks(r, 4) * 0.1


def bed_burning(r):
    """A house on fire."""
    return fire(r, 16.0, True)


def bed_wood_day(r):
    """The Thornwood by morning light: birds, the leaves."""
    return birds(r, 14) * 0.7 + leaves(r) * 0.3 + breeze(r) * 0.15


def bed_river(r):
    """The river below the hill."""
    return river(r) * 0.9 + crickets(r, 2) * 0.12


def bed_camp(r):
    """A fire in a clearing at night."""
    return fire(r, 5.0, False) * 0.6 + crickets(r, 4) * 0.35 + leaves(r) * 0.18 + owl(r) * 0.2


def bed_city(r):
    """Solhaven's streets: a crowd going by, a breeze off the plain."""
    return murmur(r, 20) * 0.65 + breeze(r) * 0.25 + knocks(r, 8) * 0.14


BEDS = {
    # ("tavern": bed_tavern, a taproom with people in it: no room has a crowd yet)
    "fire": bed_fire, "cellar": bed_cellar, "green_day": bed_green_day,
    "dusk": bed_dusk, "night": bed_night, "festival": bed_festival, "burning": bed_burning,
    "wood_day": bed_wood_day, "river": bed_river, "camp": bed_camp, "city": bed_city,
}


def finish(x):
    # (filtered round the join, so the join stays whole)
    pad = n_of(1.0)
    x = highpass(np.concatenate([x[-pad:], x, x[:pad]]), 60.0)[pad:-pad]
    x = x - np.mean(x)
    heard = highpass(np.concatenate([x[-pad:], x, x[:pad]]), mc.HEARD_FROM)[pad:-pad]
    x = x * (LOUD / (float(np.sqrt(np.mean(heard * heard))) + 1e-9))
    top = float(np.max(np.abs(x)))
    return x * (PEAK / top) if top > PEAK else x


def main():
    args = sys.argv[1:]
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")
    keep_wav = "--wav" in args
    if keep_wav:
        args.remove("--wav")
    if "--out" in args:
        i = args.index("--out")
        out_dir = args[i + 1]
        del args[i:i + 2]
    os.makedirs(out_dir, exist_ok=True)
    for name in (args or list(BEDS)):
        r = np.random.default_rng(1112 + sum(ord(c) * (i + 1) for i, c in enumerate(name)))
        mc.rng = r
        x = finish(BEDS[name](r))
        ogg = os.path.join(out_dir, "amb_%s.ogg" % name)
        wav = os.path.join(out_dir, "amb_%s.wav" % name) if keep_wav else os.path.join(tempfile.gettempdir(), "amb_%s.wav" % name)
        mc.save(wav, x)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)
        jump = abs(float(x[0] - x[-1]))
        print("%-10s %.0f s  rms %.3f  peak %.2f  join step %.4f  %d KB -> %s" % (name, len(x) / SR, float(np.sqrt(np.mean(x * x))),
            float(np.max(np.abs(x))), jump, os.path.getsize(ogg) // 1024, ogg))
        if not keep_wav:
            os.remove(wav)


if __name__ == "__main__":
    main()
