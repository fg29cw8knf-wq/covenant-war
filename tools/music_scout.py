"""Suggests where to loop one of Gary's tracks, for tools/music_loop.py.

Finds the tempo and the bar grid, where the intro settles into the body of
the piece (the loop's start: the first downbeat after the music is at full
strength), and the bar-aligned end in the last part of the track that sounds
most like the bar before the start (so the join is a natural one), avoiding
the outro's fade. Prints a few candidates and the one it would take.

  python3 tools/music_scout.py assets/audio/source/<name>.mp3 [--bars-per-loop 4]
"""
import argparse, subprocess, sys
import numpy as np
import librosa

SR = 22050


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).copy()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--beats-per-bar", type=int, default=4)
    ap.add_argument("--min-start", type=float, default=4.0, help="the loop can't start before this (s)")
    ap.add_argument("--tempo", type=float, default=None, help="use this tempo (bpm) instead of guessing")
    a = ap.parse_args()
    y = decode(a.src)
    dur = len(y) / SR
    hop = 512
    onset = librosa.onset.onset_strength(y=y, sr=SR, hop_length=hop)
    if a.tempo:
        tempo = a.tempo
        _, beats = librosa.beat.beat_track(onset_envelope=onset, sr=SR, hop_length=hop, bpm=tempo, units="time")
    else:
        tempo, beats = librosa.beat.beat_track(onset_envelope=onset, sr=SR, hop_length=hop, units="time")
        tempo = float(np.atleast_1d(tempo)[0])
    beats = np.asarray(beats)
    # the steady tempo behind the tracked beats (a straight line through
    # them), then made exact: the lag of eight bars at which the onsets
    # repeat best
    if len(beats) > 8:
        sl = np.polyfit(np.arange(len(beats)), beats, 1)[0]
        tempo = 60.0 / sl
    beat = 60.0 / tempo
    bar = beat * a.beats_per_bar
    fps = SR / hop
    env = onset - onset.mean()
    best = None
    for k in np.linspace(0.985, 1.015, 121):
        lag = int(round(8 * bar * k * fps))
        if lag >= len(env) - 10:
            continue
        c = float(np.dot(env[:-lag], env[lag:]) / (np.linalg.norm(env[:-lag]) * np.linalg.norm(env[lag:]) + 1e-9))
        if best is None or c > best[0]:
            best = (c, lag / fps / 8)
    if best is not None:
        bar = best[1]
        beat = bar / a.beats_per_bar
        tempo = 60.0 / beat
    # loudness over time (RMS in dB), smoothed over a bar
    rms = librosa.feature.rms(y=y, frame_length=2048, hop_length=hop)[0]
    t_rms = librosa.frames_to_time(np.arange(len(rms)), sr=SR, hop_length=hop)
    db = 20 * np.log10(rms + 1e-6)
    win = max(1, int(bar / (hop / SR)))
    k = np.ones(win) / win
    db_s = np.convolve(db, k, mode="same")
    body_level = np.percentile(db_s[(t_rms > dur * 0.2) & (t_rms < dur * 0.8)], 75)
    # the downbeats: beats phased so the strongest onsets fall on beat 1
    best_phase, best_score = 0, -1
    for ph in range(a.beats_per_bar):
        idx = beats[ph::a.beats_per_bar]
        fr = librosa.time_to_frames(idx, sr=SR, hop_length=hop)
        fr = fr[fr < len(onset)]
        sc = onset[fr].mean()
        if sc > best_score:
            best_phase, best_score = ph, sc
    downs = beats[best_phase::a.beats_per_bar]
    # the intro ends at the first downbeat where the music has reached the body's level
    def level_at(t):
        i = np.searchsorted(t_rms, t)
        return db_s[min(i, len(db_s) - 1)]
    start = None
    for d in downs:
        if d >= max(a.min_start, 2.0 * bar + 0.3) and level_at(d + bar * 0.5) >= body_level - 3.0:
            start = d
            break
    if start is None:
        start = downs[min(2, len(downs) - 1)]
    # the start on a real onset: the strongest onset within a tenth of a beat
    f0 = int(start * fps)
    r = int(0.1 * beat * fps)
    seg = onset[max(0, f0 - r):f0 + r + 1]
    if len(seg):
        start = (max(0, f0 - r) + int(np.argmax(seg))) / fps
    # the end: where the fade starts (the level drops away for good)
    fade_at = dur
    for t in np.arange(dur - 1.0, dur * 0.5, -0.5):
        if level_at(t) >= body_level - 4.0:
            fade_at = t
            break
    # candidates: downbeats in the last 40% of the body, scored by how like
    # the two bars before the start the two bars before them sound (chroma +
    # mel), and by how much they keep of the track
    mel = librosa.power_to_db(librosa.feature.melspectrogram(y=y, sr=SR, hop_length=hop, n_mels=64))
    chroma = librosa.feature.chroma_cqt(y=y, sr=SR, hop_length=hop)
    def feat(t0, t1):
        f0, f1 = librosa.time_to_frames([t0, t1], sr=SR, hop_length=hop)
        f0, f1 = max(0, f0), min(mel.shape[1], f1)
        m = mel[:, f0:f1].mean(axis=1)
        c = chroma[:, f0:f1].mean(axis=1)
        return m, c
    ref_m, ref_c = feat(start - 2 * bar, start)
    # the onsets of the four bars into the start, to line each end up with
    w0, w1 = max(0, int((start - 4 * bar) * fps)), int(start * fps)
    ref_o = onset[w0:w1] - onset[w0:w1].mean()
    def line_up(e):
        # the lag (within half a beat) at which the bars into `e` beat like
        # the bars into the start
        bl = None
        for lag in range(-int(0.5 * beat * fps), int(0.5 * beat * fps) + 1):
            s0 = int(e * fps) + lag - len(ref_o)
            seg = onset[s0:s0 + len(ref_o)]
            if len(seg) < len(ref_o):
                continue
            seg = seg - seg.mean()
            c = float(np.dot(ref_o, seg) / (np.linalg.norm(ref_o) * np.linalg.norm(seg) + 1e-9))
            if bl is None or c > bl[0]:
                bl = (c, e + lag / fps)
        return bl
    cands = []
    n_max = int((fade_at - 0.5 - start) / bar)
    for n in range(8, n_max + 1):
        d0 = start + n * bar
        bl = line_up(d0)
        if bl is None:
            continue
        co, d = bl
        m, c = feat(d - 2 * bar, d)
        sm = 1 - np.linalg.norm(m - ref_m) / (np.linalg.norm(m) + np.linalg.norm(ref_m) + 1e-9)
        sc = float(np.dot(c, ref_c) / (np.linalg.norm(c) * np.linalg.norm(ref_c) + 1e-9))
        lv = abs(level_at(d - bar * 0.5) - level_at(start - bar * 0.5))
        score = 0.4 * co + 0.3 * sm + 0.3 * sc - 0.02 * lv + 0.0005 * (d - start)
        cands.append((score, d, sm, sc, lv, co, n))
    cands.sort(reverse=True)
    print("%s: %.1f s, %.1f bpm (bar %.3f s), body level %.1f dB, fade from %.1f s" % (a.src, dur, tempo, bar, body_level, fade_at))
    print("loop start (intro ends): %.3f s" % start)
    print("end candidates (score, time, beat, timbre, harmony, level diff):")
    for c in cands[:6]:
        print("  %.3f  %8.3f s  beat %.2f  timbre %.2f  harmony %.2f  level %.1f dB  (%d bars)" % (c[0], c[1], c[5], c[2], c[3], c[4], c[6]))
    if cands:
        # the latest join that's about as good as the best: a longer loop
        # repeats less
        top = cands[0][0]
        best = max((c for c in cands if c[0] >= top - 0.03), key=lambda c: c[1])
        print("suggest: --start %.3f --end %.3f --fade %.3f --search 0.04   (%d bars, %.0f s loop, beat match %.2f)" % (start, best[1], bar, best[6], best[1] - start, best[5]))


if __name__ == "__main__":
    main()
