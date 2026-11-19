#!/usr/bin/env python3
"""How loud each voice recording is, thirty times a second, for the mouths
(18 November, Gary's yes: "make mouths open in time with the actual voice
lines, wider on louder words"). VoiceLines reads it while a line plays and
Figure3D opens the speaker's jaw by it.

  python3 tools/vo_envelopes.py            # every recording under assets/audio/vo
  python3 tools/vo_envelopes.py <file ...> # just these (vo_master.py calls it)

Writes assets/audio/vo/envelopes.json: {"rate": 30, "lines": {"res://...": [0..100, ...]}}.
Each value is the recording's loudness over a 30th of a second, as a share
of how loud that recording gets when the voice is full (its 95th
percentile): silence and breath under 30 dB below that are 0, so the mouth
shuts between words. Needs ffmpeg.
"""
import json
import math
import os
import subprocess
import sys
from array import array

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
VO = os.path.join(ROOT, "assets", "audio", "vo")
OUT = os.path.join(VO, "envelopes.json")
RATE = 60          # values a second
SR = 16000         # decoded at
FLOOR_DB = 30.0    # under the full voice by this much: shut
SYLLABLE = 0.12    # s either side: the voice's level about a moment
LEVEL_K = 0.55     # how much of the opening is the level itself
SYLLABLE_K = 2.2   # and how much how far it stands over the level about it


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-af", "highpass=f=250,lowpass=f=3200", "-f", "s16le", "-"],
                         check=True, capture_output=True).stdout
    a = array("h")
    a.frombytes(raw[: len(raw) - len(raw) % 2])
    return a


def envelope(path):
    s = decode(path)
    hop = SR // RATE
    dbs = []
    for i in range(0, max(len(s) - hop + 1, 1), hop):
        w = s[i:i + hop]
        if not w:
            break
        ms = sum(x * x for x in w) / len(w)
        dbs.append(10.0 * math.log10(ms / (32768.0 ** 2) + 1e-12))
    if not dbs:
        return []
    full = sorted(dbs)[int(0.95 * (len(dbs) - 1))]
    ks = [min(1.0, max(0.0, (d - (full - FLOOR_DB)) / FLOOR_DB)) for d in dbs]
    # the syllables: how far each moment stands over the voice's level about
    # it (a fifth of a second either side), on top of the level itself, so
    # the jaw opens on each syllable and closes a little between them
    # instead of hanging open through a phrase
    n = len(ks)
    span = max(1, int(RATE * SYLLABLE))
    out = []
    for i, k in enumerate(ks):
        lo, hi = max(0, i - span), min(n, i + span + 1)
        around = sum(ks[lo:hi]) / (hi - lo)
        v = LEVEL_K * k + SYLLABLE_K * (k - around)
        if k <= 0.0:
            v = 0.0
        out.append(int(round(100 * min(1.0, max(0.0, v)))))
    return out


def res_path(path):
    rel = os.path.relpath(os.path.abspath(path), ROOT).replace(os.sep, "/")
    return "res://" + rel


def main(args):
    data = {"rate": RATE, "lines": {}}
    if os.path.exists(OUT):
        try:
            with open(OUT) as f:
                old = json.load(f)
            if old.get("rate") == RATE:
                data["lines"] = old.get("lines", {})
        except (OSError, ValueError):
            pass
    files = args
    if not files:
        files = []
        for d, _, names in os.walk(VO):
            for n in sorted(names):
                if n.rsplit(".", 1)[-1].lower() in ("ogg", "mp3", "wav"):
                    files.append(os.path.join(d, n))
    for p in files:
        try:
            data["lines"][res_path(p)] = envelope(p)
        except subprocess.CalledProcessError as e:
            print("vo_envelopes: couldn't read", p, e.stderr.decode(errors="replace")[:200])
    # (only recordings that are still there)
    data["lines"] = {k: v for k, v in sorted(data["lines"].items())
                     if os.path.exists(os.path.join(ROOT, k[len("res://"):]))}
    with open(OUT, "w") as f:
        json.dump(data, f, separators=(",", ":"))
    print("vo_envelopes: %d recordings in %s" % (len(data["lines"]), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main(sys.argv[1:])
