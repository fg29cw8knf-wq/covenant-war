#!/usr/bin/env python3
"""Readies Gary's own sound effects for the game (18 November: the fifteen
for the Night of the White Sky).

His recordings come as he made them: one at -6 LUFS and clipping, the next
at -33, most with a second or two of nothing after the sound. For each
recording (any format ffmpeg reads) this:

  1. cuts the nothing off both ends (what lies more than 50 dB under the
     sound's loudest moment before it, 55 dB after it), keeping 10 ms before
     the sound and fading the last 40 ms out;
  2. keeps his stereo, unless the two sides are more against each other than
     with each other (a phone's one speaker would cancel them): then the
     difference between the sides is turned down until they agree (SAFE_CORR);
  3. sets it as loud as the game's other effects: its loudest fifth of a
     second (heard above 180 Hz, as tools/make_cries.py judges the creatures'
     voices) at LOUD, and never a peak over PEAK (a crack stays a crack: it's
     turned down to its peak, not squashed). Takes of one sound (ice_ring,
     ice_ring_2, ice_ring_3) each come out as loud as each other;
  4. writes assets/sfx/<name>.ogg (Ogg Vorbis, quality 6, 44.1 kHz).

    python3 tools/sfx_master.py <folder or files> [--out assets/sfx] [--loud 0.16] [--peak 0.7]
    python3 tools/sfx_master.py <file> --music   a short piece of music instead: into
                                               assets/audio/music/, its level left as he
                                               made it but for peaks over -1.5 dB

Prints each one's cut, length, gain and what it came out at. The game finds a
sound by its name (scripts/ui/sfx.gd: assets/sfx/<name>.ogg, with _2, _3 for
more takes); then `godot --headless --import`. His recordings are kept,
untouched, in assets/audio/source/sfx/ (never exported).
"""
import argparse, os, subprocess, sys

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
LOUD = 0.16          # (the game's effects: their loudest fifth of a second runs 0.08 to 0.23)
PEAK = 0.7           # (and they peak at 0.4 to 0.62)
HEARD_FROM = 180.0   # loudness is judged above this (Hz), as make_cries.py does
SAFE_CORR = 0.5      # two sides that disagree are brought to at least this much agreement
MUSIC_PEAK = 0.84    # (-1.5 dB: Vorbis adds a little to the peaks)
QUALITY = 6


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).astype(np.float64)


def frame_db(x, hop=441, win=882):
    """Level in dB of each 10 ms step (both sides together, over 20 ms)."""
    p = (x * x).mean(1)
    n = max(1, (len(p) - win) // hop + 1)
    c = np.concatenate([[0.0], np.cumsum(p)])
    i = np.arange(n) * hop
    return 10 * np.log10((c[np.minimum(i + win, len(p))] - c[i]) / win + 1e-14)


def sound_span(x):
    """(start, end) in seconds of the sound itself."""
    db = frame_db(x)
    top = float(db.max())
    on = np.nonzero(db > top - 50.0)[0]
    tail = np.nonzero(db > top - 55.0)[0]
    start = max(0.0, on[0] * 0.01 - 0.01)
    end = min(len(x) / SR, (tail[-1] + 2) * 0.01 + 0.05)
    return start, end


def cut(x, start, end, fade_in=0.003, fade_out=0.04):
    seg = x[int(start * SR):int(end * SR)].copy()
    a, b = max(1, int(fade_in * SR)), max(1, min(int(fade_out * SR), len(seg) // 2))
    seg[:a] *= (0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a)))[:, None]
    seg[-b:] *= (0.5 + 0.5 * np.cos(np.linspace(0, np.pi, b)))[:, None]
    return seg


def agreement(x):
    l, r = x[:, 0], x[:, 1]
    return float((l * r).sum() / np.sqrt((l * l).sum() * (r * r).sum() + 1e-20))


def mono_safe(x):
    """The sides' difference turned down until they agree by SAFE_CORR.
    Returns (x, how much of the difference is kept)."""
    c = agreement(x)
    if c >= 0.0:
        return x, 1.0
    mid, side = x.mean(1), (x[:, 0] - x[:, 1]) * 0.5
    m2, s2, ms = float((mid * mid).sum()), float((side * side).sum()), float((mid * side).sum())
    keep = 1.0
    for k in np.linspace(1.0, 0.0, 101):
        l, r = mid + side * k, mid - side * k
        cc = (m2 - k * k * s2) / np.sqrt(max(1e-20, (m2 + k * k * s2) ** 2 - (2 * k * ms) ** 2))
        if cc >= SAFE_CORR:
            keep = float(k)
            break
        keep = float(k)
    return np.stack([mid + side * keep, mid - side * keep], 1), keep


def loudest(x, secs=0.2):
    """The RMS of the loudest `secs` of it, heard above HEARD_FROM."""
    sos = butter(2, HEARD_FROM, "hp", fs=SR, output="sos")
    h = sosfilt(sos, x, axis=0)
    p = (h * h).mean(1)
    w = int(secs * SR)
    if len(p) <= w:
        return float(np.sqrt(p.mean()))
    c = np.concatenate([[0.0], np.cumsum(p)])
    return float(np.sqrt(((c[w:] - c[:-w]) / w).max()))


def encode(x, path):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(QUALITY), "-map_metadata", "-1", path],
                   input=pcm, check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="+")
    ap.add_argument("--out", default="")
    ap.add_argument("--loud", type=float, default=LOUD)
    ap.add_argument("--peak", type=float, default=PEAK)
    ap.add_argument("--music", action="store_true")
    a = ap.parse_args()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = a.out or (os.path.join(root, "assets", "audio", "music") if a.music else os.path.join(root, "assets", "sfx"))
    files = []
    for s in a.src:
        if os.path.isdir(s):
            files += [os.path.join(s, f) for f in sorted(os.listdir(s)) if f.lower().endswith((".mp3", ".wav", ".ogg", ".flac", ".m4a", ".aif", ".aiff"))]
        else:
            files.append(s)
    os.makedirs(out_dir, exist_ok=True)
    print("%-20s %6s %6s %7s %7s %6s %6s %6s  %s" % ("recording", "from", "to", "length", "gain", "loud", "peak", "sides", ""))
    for path in files:
        name = os.path.splitext(os.path.basename(path))[0]
        x = decode(path)
        start, end = sound_span(x)
        y = cut(x, start, end, fade_out=0.25 if a.music else 0.04)
        y, keep = mono_safe(y)
        note = "" if keep >= 1.0 else "the sides were against each other (%+.2f): %d%% of their difference kept" % (agreement(cut(x, start, end)), round(keep * 100))
        top = float(np.abs(y).max())
        if a.music:
            gain = min(1.0, MUSIC_PEAK / top)
        else:
            gain = a.loud / (loudest(y) + 1e-12)
            if top * gain > a.peak:
                gain = a.peak / top
                note = (note + "; " if note else "") + "held to its peak"
        y = y * gain
        dst = os.path.join(out_dir, name + ".ogg")
        encode(y, dst)
        back = decode(dst)
        print("%-20s %6.2f %6.2f %7.2f %+6.1f %6.3f %6.2f %+6.2f  %s" % (name, start, end, len(y) / SR, 20 * np.log10(gain),
              loudest(back), float(np.abs(back).max()), agreement(back), note))


if __name__ == "__main__":
    main()
