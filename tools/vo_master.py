"""Turns Gary's narration recordings into the opening movie's voice lines.

For each recording (vo_01.wav ... any format ffmpeg reads):
  1. trims the silence before the first word (keeping 20 ms before it, faded in
     over 15 ms) and after the last (a breath that starts right at the end of
     the file is cut; a final consonant after a short gap is kept), fading out
     over 60 ms;
  2. sets it to about -16 LUFS, like the earlier voice set, with true peaks at or
     under -1 dBTP once encoded (one gain, then a look-ahead limiter on the few
     peaks above that); lines recorded in one breath and split (09a into 09b)
     share one gain so the sentence keeps its shape;
  3. writes assets/audio/vo/<name>.ogg: Ogg Vorbis, quality 5, mono, 44.1 kHz.
No reverb or other effect is added: Gary's voice brief asks for a clean voice.

Usage:
  python3 tools/vo_master.py <folder of recordings> [assets/audio/vo]
Prints each line's trim points, length, loudness and peak. The lengths are what
scripts/story/opening_movie.gd schedules; tests/movie_shot.gd checks the timeline.
Gary's recordings are kept, untouched, in assets/audio/source/vo/ (never exported).

The game's spoken lines (tools/vo_sheet.py, scripts/story/voice_lines.gd):
  python3 tools/vo_master.py --lines <folder of recordings> [docs/script/vo_lines.csv]
Each recording is named by its number on the sheet (0042.wav, "0042 Bram.wav")
or its id (c5ab712b.wav); the csv says whose line it is and where it goes
(assets/audio/vo/<area>/<speaker>/<id>.ogg). Each line is levelled on its own.
A file that matches no line is reported and left alone. Then run
`godot --headless --import` so the game sees the new files.
"""
import os, subprocess, sys
import numpy as np
from scipy.ndimage import minimum_filter1d
from scipy.signal import resample_poly

SR = 44100
TARGET_LUFS = -16.0
CEILING_DBTP = -1.0
QUALITY = 5
SILENT_DB = -50.0
# lines recorded as one flowing sentence and split: they share one gain
TOGETHER = [("vo_09a", "vo_09b")]


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def frame_db(y, hop=441, win=882):
    """Level in dB of each 10 ms step (RMS over 20 ms)."""
    n = max(1, (len(y) - win) // hop + 1)
    out = np.empty(n)
    for i in range(n):
        f = y[i * hop:i * hop + win]
        out[i] = 10 * np.log10(np.mean(f * f) + 1e-12)
    return out


def speech_span(y):
    """(start, end) in seconds of the spoken part."""
    db = frame_db(y)
    loud = db > SILENT_DB
    n = len(db)
    first = 0
    for i in range(n):
        # the first sustained sound that leads into speech (not a click left by the cut)
        if loud[i] and loud[i:i + 10].sum() >= 6 and (db[i:i + 40] > -35).any():
            first = i
            break
    while first > 0 and db[first - 1] > -56:
        first -= 1
    last = n - 1
    while last > first and not loud[last]:
        last -= 1
    # a short sound starting after a pause right at the end is the next breath, cut off
    run = last
    while run > first and loud[run - 1]:
        run -= 1
    if last - run + 1 < 6:
        gap = run - 1
        while gap > first and not loud[gap]:
            gap -= 1
        if run - 1 - gap >= 10:
            last = gap
    start = max(0.0, first * 0.01 - 0.02)
    end = min(len(y) / SR, (last + 2) * 0.01 + 0.03)
    return start, end


def cut(y, start, end, fade_in=0.015, fade_out=0.06):
    seg = y[int(start * SR):int(end * SR)].copy()
    a, b = int(fade_in * SR), int(fade_out * SR)
    seg[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    seg[-b:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, b))
    return seg


def true_peak(y):
    return float(np.max(np.abs(resample_poly(y, 4, 1)))) if len(y) else 0.0


def limit(y, ceiling, look=0.002, attack=0.0005, release=0.08):
    """Look-ahead peak limiter on the 4x oversampled signal: the gain starts to dip
    2 ms before a peak and recovers over 80 ms, so no peak gets through."""
    up = np.abs(resample_poly(y, 4, 1))[:len(y) * 4]
    need = np.minimum(1.0, ceiling / np.maximum(up, 1e-9)).reshape(-1, 4).min(axis=1)
    k = int(look * SR)
    held = minimum_filter1d(need, 2 * k + 1, origin=-k, mode="nearest")   # the lowest over the next 2k samples
    a, r = np.exp(-1.0 / (attack * SR)), np.exp(-1.0 / (release * SR))
    g = np.empty_like(held)
    cur = 1.0
    for i, h in enumerate(held):
        cur = h + (cur - h) * (a if h < cur else r)
        g[i] = cur
    return y * np.minimum(g, need)


def lufs(y):
    """Integrated loudness and true peak, measured by ffmpeg's EBU R128 meter."""
    pcm = (np.clip(y, -1, 1) * 32767).astype("<i2").tobytes()
    r = subprocess.run(["ffmpeg", "-nostats", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-",
                        "-af", "ebur128=peak=true", "-f", "null", "-"], input=pcm, capture_output=True)
    i = tp = None
    for ln in r.stderr.decode().splitlines()[-14:]:
        ln = ln.strip()
        if ln.startswith("I:"):
            i = float(ln.split()[1])
        elif ln.startswith("Peak:"):
            tp = float(ln.split()[1])
    return i, tp


def master(segs):
    """One gain for the group (to TARGET_LUFS together), limited to the ceiling.

    This voice is raspy: its peaks stand 16-19 dB above its loudness, so reaching
    -16 LUFS under the old set's -3 dBTP would flatten every syllable. The limiter
    only takes the tops off the loudest ones (a few percent of the time, a few dB
    at most), and the line is allowed to land up to 0.5 dB under the target."""
    joined = np.concatenate(segs)
    ceiling = 10 ** ((CEILING_DBTP - 1.0) / 20)   # Vorbis adds about 1 dB to the peaks
    gain_db = TARGET_LUFS - lufs(joined)[0]
    for _ in range(3):
        out = [limit(s * 10 ** (gain_db / 20), ceiling) for s in segs]
        have = lufs(np.concatenate(out))[0]
        if have > TARGET_LUFS - 0.5:
            break
        gain_db += (TARGET_LUFS - 0.25 - have) * 0.5
    return out, gain_db


def encode(y, path):
    pcm = (np.clip(y, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(QUALITY), "-map_metadata", "-1", path],
                   input=pcm, check=True)


def master_one(path_in, path_out):
    """One recording, trimmed and levelled on its own, written as Ogg. Returns its report line."""
    y = decode(path_in)
    span = speech_span(y)
    seg = cut(y, *span)
    out, gain = master([seg])
    os.makedirs(os.path.dirname(path_out), exist_ok=True)
    encode(out[0], path_out)
    i, tp = lufs(decode(path_out))
    lim = 20 * np.log10(np.maximum(np.abs(seg * 10 ** (gain / 20)), 1e-9) / np.maximum(np.abs(out[0]), 1e-9))
    lim = lim[np.abs(seg) > 1e-4]
    return "%7.3f %7.3f %7.3f %+6.1f %6.1f %6.1f %6.1f %5.0f%%" % (
        span[0], span[1], len(out[0]) / SR, gain, i, tp, lim.max() if len(lim) else 0.0, 100 * (lim > 1).mean() if len(lim) else 0.0)


def main_lines(src, sheet):
    import csv, re
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    rows = list(csv.DictReader(open(sheet)))
    by_no = {r["no"]: r for r in rows}
    by_id = {r["id"]: r for r in rows if r["id"]}
    print("%-28s %-9s %-10s %7s %7s %7s %6s %6s %6s %6s %6s" % ("recording", "speaker", "id", "from", "to", "length", "gain", "LUFS", "dBTP", "limit", ">1dB"))
    done = 0
    for f in sorted(os.listdir(src)):
        if not f.lower().endswith((".wav", ".flac", ".mp3", ".ogg", ".m4a", ".aiff", ".aif")):
            continue
        stem = os.path.splitext(f)[0]
        m = re.search(r"\b([0-9a-f]{8})\b", stem)
        row = by_id.get(m.group(1)) if m else None
        if row is None:
            m = re.match(r"(\d{4})\b", stem)
            row = by_no.get(m.group(1)) if m else None
        if row is None:
            print("%-28s matches no line on the sheet (name it by the line's number or id)" % f)
            continue
        if not row["file"]:
            print("%-28s line %s has no file to go to (%s)" % (f, row["no"], row["note"]))
            continue
        if "recorded already" in row["note"]:
            print("%-28s line %s is one of the named recordings (%s): master it with the movie's lines" % (f, row["no"], row["file"]))
            continue
        out = os.path.join(root, row["file"])
        report = master_one(os.path.join(src, f), out)
        print("%-28s %-9s %-10s %s" % (f[:28], row["speaker"][:9], row["id"], report))
        done += 1
    print("%d line%s in place under assets/audio/vo/; run godot --headless --import so the game sees them" % (done, "" if done == 1 else "s"))


def main():
    if sys.argv[1:2] == ["--lines"]:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        main_lines(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else os.path.join(root, "docs/script/vo_lines.csv"))
        return
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets/audio/vo")
    names = sorted(os.path.splitext(f)[0] for f in os.listdir(src)
                   if f.startswith("vo_") and f.lower().endswith((".wav", ".flac", ".mp3", ".ogg")))
    files = {n: next(os.path.join(src, f) for f in os.listdir(src) if os.path.splitext(f)[0] == n) for n in names}
    groups = [g for g in TOGETHER if all(n in names for n in g)]
    grouped = {n for g in groups for n in g}
    groups += [(n,) for n in names if n not in grouped]
    print("%-7s %7s %7s %7s %6s %6s %6s %6s %6s" % ("line", "from", "to", "length", "gain", "LUFS", "dBTP", "limit", ">1dB"))
    for g in sorted(groups):
        spans = {}
        segs = []
        for n in g:
            y = decode(files[n])
            spans[n] = speech_span(y)
            segs.append(cut(y, *spans[n]))
        out, gain = master(segs)
        for n, y, s in zip(g, out, segs):
            path = os.path.join(dst, n + ".ogg")
            encode(y, path)
            i, tp = lufs(decode(path))
            # how hard the limiter worked: the most it took off, and how often more than 1 dB
            lim = 20 * np.log10(np.maximum(np.abs(s * 10 ** (gain / 20)), 1e-9) / np.maximum(np.abs(y), 1e-9))
            lim = lim[np.abs(s) > 1e-4]
            print("%-7s %7.3f %7.3f %7.3f %+6.1f %6.1f %6.1f %6.1f %5.0f%%" % (
                n, spans[n][0], spans[n][1], len(y) / SR, gain, i, tp, lim.max(), 100 * (lim > 1).mean()))


if __name__ == "__main__":
    main()
