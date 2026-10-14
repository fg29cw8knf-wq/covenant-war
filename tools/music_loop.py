"""Cuts one of Gary's tracks into a seamless game loop.

The track plays from the start once (its intro), then loops from `start` back
to... well, from `end` back to `start`, forever. The join is made inaudible by:
  1. moving `end` so the beats before it line up exactly with the beats before
     `start` (searched over +-120 ms by onset pattern, then +-2 ms by waveform);
  2. baking a crossfade into the file's last bar, from the music before `end`
     into the music before `start`, so the last sample of the file runs straight
     into the sample at `start`.
The game then plays it with Music.LOOP_START[name] = start (see scripts/ui/music.gd),
and Godot's loop_offset lands on that sample exactly (checked with tests/loop_probe.gd).

Usage:
  python3 tools/music_loop.py <in.mp3> <out.ogg> --start 35.03 --end 86.85 [--fade 2.15]
                              [--check <seam_check.mp3>] [--lufs -14]
Prints the final start and end; put the start in Music.LOOP_START.
"""
import argparse, subprocess, sys
import numpy as np

SR = 48000


def decode(path, channels):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", str(channels), "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    y = np.frombuffer(raw, np.float32).copy()
    return y if channels == 1 else y.reshape(-1, 2)


def onset_env(y, hop=48, win=1024):
    """Spectral flux at 1 ms steps: where the beats are, finely."""
    n = (len(y) - win) // hop
    w = np.hanning(win)
    frames = np.lib.stride_tricks.as_strided(y, shape=(n, win), strides=(y.strides[0] * hop, y.strides[0]))
    spec = np.abs(np.fft.rfft(frames * w, axis=1))
    flux = np.maximum(np.diff(spec, axis=0), 0).sum(axis=1)
    return np.concatenate([[0.0], flux]), hop


def refine_end(mono, start, end, bar, search=0.12):
    """Shifts `end` so its lead-in beats line up with the lead-in to `start`."""
    env, hop = onset_env(mono)
    a0, a1 = int((start - 2 * bar) * SR / hop), int((start + 0.5 * bar) * SR / hop)
    ref = env[a0:a1] - env[a0:a1].mean()
    best = None
    for off in np.arange(-search, search, hop / SR):
        b0 = int((end + off - 2 * bar) * SR / hop)
        seg = env[b0:b0 + len(ref)]
        if len(seg) < len(ref):
            continue
        seg = seg - seg.mean()
        c = float(np.dot(ref, seg) / (np.linalg.norm(ref) * np.linalg.norm(seg) + 1e-9))
        if best is None or c > best[0]:
            best = (c, end + off)
    end = best[1]
    # then the waveform itself, within +-2 ms, so the crossfade doesn't cancel
    win = int(0.03 * SR)
    a = mono[int(start * SR) - win:int(start * SR)]
    best2 = None
    for d in range(-int(0.002 * SR), int(0.002 * SR)):
        e = int(end * SR) + d
        b = mono[e - win:e]
        c = float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9))
        if best2 is None or c > best2[0]:
            best2 = (c, e / SR)
    return best2[1], best[0], best2[0]


def bake(stereo, start, end, fade):
    """The file up to `end`, its last `fade` seconds blended into what leads into `start`."""
    s, e, f = int(start * SR), int(end * SR), int(fade * SR)
    out = stereo[:e].copy()
    w = (0.5 - 0.5 * np.cos(np.linspace(0, np.pi, f)))[:, None]   # equal-power-ish, smooth
    out[e - f:e] = out[e - f:e] * np.sqrt(1 - w) + stereo[s - f:s] * np.sqrt(w)
    return out


def encode(stereo, path, lufs=None):
    raw = stereo.astype(np.float32).tobytes()
    gain = []
    if lufs is not None:
        probe = subprocess.run(["ffmpeg", "-v", "info", "-f", "f32le", "-ac", "2", "-ar", str(SR), "-i", "-", "-af", "ebur128", "-f", "null", "-"],
                               input=raw, capture_output=True).stderr.decode()
        have = float([ln for ln in probe.splitlines() if ln.strip().startswith("I:")][-1].split()[1])
        gain = ["-af", "volume=%.2fdB" % (lufs - have)]
    codec = ["-c:a", "libvorbis", "-q:a", "4"] if path.endswith(".ogg") else ["-c:a", "libmp3lame", "-b:a", "160k"]
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", "2", "-ar", str(SR), "-i", "-"] + gain + codec + [path],
                   input=raw, check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--start", type=float, required=True)
    ap.add_argument("--end", type=float, required=True)
    ap.add_argument("--fade", type=float, default=2.0, help="crossfade length in seconds (about one bar)")
    ap.add_argument("--bar", type=float, default=None, help="bar length in seconds (defaults to --fade)")
    ap.add_argument("--check", help="write a seam-check mp3: the join as the game plays it, three times")
    ap.add_argument("--lufs", type=float, default=None, help="normalise the loop to this loudness")
    ap.add_argument("--no-refine", action="store_true")
    a = ap.parse_args()
    bar = a.bar or a.fade
    stereo = decode(a.src, 2)
    mono = stereo.mean(axis=1)
    end = a.end
    if not a.no_refine:
        end, c_beat, c_wave = refine_end(mono, a.start, a.end, bar)
        print("end %.3f -> %.4f s (beat match %.2f, waveform match %.2f)" % (a.end, end, c_beat, c_wave))
    out = bake(stereo, a.start, end, a.fade)
    encode(out, a.out, a.lufs)
    print("wrote %s: %.3f s, loops back to %.3f s (%.1f s loop)" % (a.out, len(out) / SR, a.start, len(out) / SR - a.start))
    if a.check:
        s, n = int(a.start * SR), int(5.0 * SR)
        piece = np.concatenate([out[-n:], out[s:s + n]])
        encode(np.concatenate([piece, piece, piece]), a.check, a.lufs)
        print("seam check: %s (5 s before the join, then 5 s after it, three times)" % a.check)
    print("Music.LOOP_START: %.3f" % a.start)


if __name__ == "__main__":
    main()
