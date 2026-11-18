#!/usr/bin/env python3
"""Makes a deep boom heard on a phone (18 November, Gary's yes to "remake
light_wave with a whoosh in it, so phones can hear it").

His light_wave is nearly all under 100 Hz: a phone's small speaker gives
almost nothing below about 200 Hz, so on an iPhone the moment was all but
silent. This keeps his boom as it is and adds, under his control of the
moment's shape (it follows his boom's own loudness, so it swells and dies
with it):

  1. the boom's own overtones: the low end driven through a soft saturator
     and kept from 150 Hz up, so the ear hears the boom's pitch on a small
     speaker (the "missing fundamental": the brain fills the low note in);
  2. a rush of air: noise swept from low to high and back as the light
     rolls past, in stereo, moving from one side to the other.

    python3 tools/sfx_lift.py <in> <out.wav> [--harm 0.5] [--rush 0.45]

Then tools/sfx_master.py on the result, as for any of his sounds. His
recording stays as it came in assets/audio/source/sfx/.
"""
import argparse, subprocess, sys
import numpy as np
from scipy.signal import butter, sosfilt, sosfiltfilt

SR = 44100


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).astype(np.float64)


def envelope(x, secs=0.03):
    p = (x * x).mean(1) if x.ndim > 1 else x * x
    w = max(1, int(secs * SR))
    k = np.ones(w) / w
    return np.sqrt(np.convolve(p, k, mode="same"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--harm", type=float, default=0.5, help="how loud the boom's overtones are against it")
    ap.add_argument("--rush", type=float, default=0.45, help="how loud the rush of air is against the boom")
    a = ap.parse_args()
    x = decode(a.src)
    n = len(x)
    t = np.arange(n) / SR
    env = envelope(x)
    env /= env.max() + 1e-12
    # 1. overtones of the boom
    low = sosfilt(butter(4, 140, "lp", fs=SR, output="sos"), x, axis=0)
    drive = 6.0 / (np.abs(low).max() + 1e-9)
    sat = np.tanh(low * drive)
    harm = sosfilt(butter(4, [150, 2400], "bp", fs=SR, output="sos"), sat, axis=0)
    harm *= (np.abs(low).max() / (np.abs(harm).max() + 1e-9))
    # 2. the rush: noise through a band that rises as the light comes and falls as it goes
    rng = np.random.default_rng(718)
    noise = rng.standard_normal((n, 2))
    peak_t = t[int(np.argmax(envelope(x, 0.15)))]
    out = np.zeros((n, 2))
    hop = 512
    for s in range(0, n, hop):
        e = min(n, s + hop * 3)
        tt = t[s]
        k = np.exp(-((tt - peak_t - 0.15) / 0.55) ** 2)
        lo_f = 300 + 1500 * k
        hi_f = min(SR / 2 - 100, 1500 + 6500 * k)
        seg = sosfiltfilt(butter(2, [lo_f, hi_f], "bp", fs=SR, output="sos"), noise[s:e], axis=0)
        win = np.hanning(e - s)[:, None]
        out[s:e] += seg * win
    # left to right as it passes
    pan = np.clip((t - peak_t + 0.6) / 1.6, 0, 1)
    out[:, 0] *= np.cos(pan * np.pi / 2) * 0.6 + 0.4
    out[:, 1] *= np.sin(pan * np.pi / 2) * 0.6 + 0.4
    rush_env = np.minimum(1.0, env * 1.3) ** 0.8
    out *= rush_env[:, None]
    out *= np.abs(x).max() / (np.abs(out).max() + 1e-9)
    y = x + harm * a.harm + out * a.rush
    y /= np.abs(y).max() + 1e-9
    y *= 0.95
    pcm = (np.clip(y, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-", a.out], input=pcm, check=True)
    # how much of each came out above 200 Hz (what a phone gives)
    hp = butter(4, 200, "hp", fs=SR, output="sos")
    def above(z):
        return 20 * np.log10(np.sqrt((sosfilt(hp, z, axis=0) ** 2).mean()) / np.sqrt((z ** 2).mean() + 1e-12) + 1e-12)
    print("%s: above 200 Hz, his %.1f dB of the whole, now %.1f dB" % (a.out, above(x), above(y)))


if __name__ == "__main__":
    main()
