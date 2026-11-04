"""Makes one of Gary's sound recordings into a loop with no join: the last
`fade` seconds are crossfaded (equal power) into the first, so the file's end
runs straight into its start, and the peaks are kept under -1 dB. Written as
Ogg Vorbis (the game's loops set AudioStreamOggVorbis.loop), the recording
kept untouched in assets/audio/source/sfx/.
  python3 tools/sfx_loop.py <recording> assets/sfx/<name>.ogg [--fade 3.0] [--gain-db 0]
The Night of the White Sky's storm (storm_wind, 45 s, fade 4 s) and the
child's crying (baby_cry, 10 s, fade 0.8 s) were made with it (4 November).
"""
import argparse, os, shutil, subprocess
import numpy as np
SR = 48000
ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("out")
ap.add_argument("--fade", type=float, default=3.0)
ap.add_argument("--gain-db", type=float, default=0.0)
a = ap.parse_args()
raw = subprocess.run(["ffmpeg", "-v", "error", "-i", a.src, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"], capture_output=True, check=True).stdout
y = np.frombuffer(raw, np.float32).reshape(-1, 2).copy()
n = int(a.fade * SR)
assert 2 * n < len(y), "the fade is longer than half the recording"
t = np.linspace(0.0, 1.0, n, endpoint=False)[:, None]
head = y[:n] * np.sin(t * np.pi / 2)            # the start, rising
tail = y[-n:] * np.cos(t * np.pi / 2)           # the end, falling
y = np.concatenate([y[n:-n], tail + head])      # the join is baked into the last `fade` seconds
y *= 10 ** (a.gain_db / 20)
peak = np.abs(y).max()
if peak > 10 ** (-1 / 20):
    y *= 10 ** (-1 / 20) / peak
keep = os.path.join("assets/audio/source/sfx", os.path.basename(a.out)[:-4] + os.path.splitext(a.src)[1])
os.makedirs(os.path.dirname(keep), exist_ok=True)
if not os.path.exists(keep):
    shutil.copyfile(a.src, keep)
subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ac", "2", "-ar", str(SR), "-i", "-", "-c:a", "libvorbis", "-q:a", "6", a.out], input=y.astype(np.float32).tobytes(), check=True)
print("%s: %.1f s, loops with a %.1f s join, peak %.1f dB; kept %s" % (a.out, len(y) / SR, a.fade, 20 * np.log10(np.abs(y).max() + 1e-9), keep))
