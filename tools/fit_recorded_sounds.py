#!/usr/bin/env python3
"""Real recordings for the footsteps, the crate, the card box's lid and doors
(25 November: Gary's "4 can you find them online and use them" for the
footsteps, and his yes to "Use the wood and metal knocks in the Impact Sounds
pack for the crate, the box lid and doors"; 26 November: his yes to sounds
for a door shutting and the shelter's door).

They come from two of Kenney's packs, both public domain (CC0), which Gary
downloaded himself (kenney.nl turns AI tools away):

    Impact Sounds 1.0   https://kenney.nl/assets/impact-sounds
    RPG Audio           https://kenney.nl/assets/rpg-audio

    python3 -I tools/fit_recorded_sounds.py <Impact Sounds folder> <RPG Audio folder>
    python3 -I tools/fit_recorded_sounds.py <...> <...> --out /tmp/fitted   # somewhere else
    python3 -I tools/fit_recorded_sounds.py <...> <...> --list              # what goes where
    python3 -I tools/fit_recorded_sounds.py <...> <...> --extra <folder>    # and the two long recordings (LONG), from the folder they were downloaded to

(each folder is the one with "Audio" and "License.txt" in it). It writes
assets/sfx/<name>.wav and its takes (<name>_2 ...), mono, 44.1 kHz, 16-bit,
over the made stand-ins of the same names (tools/make_steps.py, which now
leaves these grounds alone), and assets/sfx/SOURCES.md, which says where
every one came from.

What's done to a recording, and nothing else: both channels summed; the
silence before it cut; its tail cut where it has died away (TAIL_DB under
its loudest); rumble under 50 Hz taken off; levelled the way the made
sounds are (its loudest twelfth of a second, judged above 180 Hz, brought to
the level the stand-in it replaces had), with a limiter that takes at most
LIMIT_DB off its sharpest peak (less, the deeper the sound: fit()), so a
clicky or a boomy recording ends up a little quieter than its stand-in
sooner than it is squashed. No reverb, no EQ, no
mixing of one sound with another. Needs ffmpeg, numpy and scipy.
"""
import glob
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 44100
HEARD_FROM = 180.0     # as tools/make_cries.py: loudness is judged above this
LOUD_WIN = 0.08        # as tools/make_steps.py: a step's loudest twelfth of a second
PEAK = 0.85            # no sample over this
LIMIT_DB = 4.0         # the most the limiter may take off a peak
TAIL_DB = -46.0        # the tail is cut where the sound stays this far under its loudest
PRE = 0.002            # kept before the first sound (s)

# name: (pack, [takes], level, longest (s), speed). `level`: what its loudest
# twelfth of a second is brought to (the made stand-in's own, for the steps).
# `speed` under 1 plays it slower and lower (a bigger door).
FIT = {
    # ---- footsteps: four takes each (Sfx.step picks one, and moves its pitch a little)
    "step_grass": ("impact", ["footstep_grass_000", "footstep_grass_001", "footstep_grass_002", "footstep_grass_004"], 0.167, 0.40, 1.0),
    "step_snow": ("impact", ["footstep_snow_000", "footstep_snow_001", "footstep_snow_002", "footstep_snow_004"], 0.178, 0.40, 1.0),
    "step_wood": ("impact", ["footstep_wood_000", "footstep_wood_001", "footstep_wood_002", "footstep_wood_003"], 0.094, 0.30, 1.0),
    "step_stone": ("impact", ["footstep_concrete_000", "footstep_concrete_001", "footstep_concrete_003", "footstep_concrete_004"], 0.109, 0.25, 1.0),
    "step_dirt": ("rpg", ["footstep00", "footstep02", "footstep06", "footstep07"], 0.150, 0.32, 1.0),
    # the inn's stairs: the wooden floor's, a little higher (a tread is a smaller board)
    "step_stairs": ("impact", ["footstep_wood_004", "footstep_wood_002", "footstep_wood_000", "footstep_wood_003"], 0.121, 0.30, 1.1),
    # ---- the lantern crate
    "crate_lift": ("impact", ["impactWood_medium_002", "impactWood_medium_003"], 0.2, 0.35, 1.0),
    "crate_set": ("impact", ["impactWood_medium_000", "impactWood_medium_001", "impactWood_medium_004"], 0.2, 0.35, 1.0),
    # ---- the card box's lid: its clasp, the lid reaching its stop, the lid shut
    "box_latch": ("impact", ["impactMetal_light_001", "impactMetal_light_002", "impactMetal_light_004"], 0.2, 0.30, 1.0),
    "box_open": ("impact", ["impactWood_light_001", "impactWood_light_003"], 0.2, 0.28, 1.0),
    "box_close": ("impact", ["impactWood_light_000", "impactWood_light_002", "impactWood_light_004"], 0.2, 0.28, 1.0),
    # ---- doors
    "door_open": ("rpg", ["doorOpen_1", "doorOpen_2"], 0.2, 1.5, 1.0),
    # a door shut (26 November: the shelter's, behind them). Of the pack's
    # four, the two with a door's weight in them: _4 is the deepest (a third
    # of it under 200 Hz), _3 the longest; _1 is a handle's rattle and _2 a
    # latch's click, which is what made "the pack's close" read as a tick.
    "door_close": ("rpg", ["doorClose_4", "doorClose_3"], 0.2, 0.9, 1.0),
    # a door's latch tried, its hook lifted
    "door_latch": ("rpg", ["metalLatch"], 0.16, 0.30, 1.0),
    # (26 November: a chest's lid and a trapdoor were asked for too, and
    # fitted: creak1 and creak2 at 0.8 speed for the hinges, impactPlank_
    # medium_001 and _003 for the lid on its stop and the door on the floor,
    # the two planks with most of themselves above 180 Hz. Then it turned out
    # the game never plays them: the cellar scene with Bram's chest and the
    # trapdoor (Ashford._cellar, v3's P4) hasn't been reached since the v7
    # Prologue. They are the picks if a lid or a hatch is ever seen to move.)
    # the Golden Gate's two great leaves: the longer door, slower and lower
    "gate_open": ("rpg", ["doorOpen_2"], 0.2, 2.6, 0.62),
}
PACKS = {"impact": ("Impact Sounds 1.0", "https://kenney.nl/assets/impact-sounds"),
    "rpg": ("RPG Audio", "https://kenney.nl/assets/rpg-audio")}

# ---- two long recordings, each a single download (26 November: Gary's yes
# to wheels and hooves for the dawn, and the hooves the Reckoning had always
# asked for and never had). Neither Kenney pack has a horse. Both are Craig
# Smith's transfers of the USC film school's old optical sound-effect
# library (1930s to 1960s), on Freesound, public domain (CC0). They're in
# the folder given as --extra, found by the number in their file names.
#   name: (the file's number, its page, its title, from s, to s, how)
# how: "rms" its body's level in dB (a steady bed) or "loud" its loudest
# twelfth of a second (hits); "in" and "out" the fades in seconds, in the
# file itself (a film sound is played once and left); "away_db" how much
# quieter it has grown by the time it starts to fade (it's leaving);
# "lowpass" a top cut in Hz (heard through a floor).
LONG = {
    # The dawn: the wagon rolling out of the Golden Gate. The recording is
    # one four-second stretch of wheels and horses on a hard road, repeated
    # (its loudness repeats every 3.99 s); nothing in it is over 2 kHz. Cut
    # to the shot: 8.6 s from where the transfer has settled (its first 7 s
    # are a bump and the leader), up over the first second as the picture
    # comes up, 4 dB quieter by the time the picture starts to go, as the
    # wagon draws away, and gone by the black.
    "wagon_roll": ("437076", "https://freesound.org/s/437076", "G52-07-Horse Drawn Carriage.wav", 13.0, 21.6,
        {"rms": -20.0, "in": 0.9, "out": 2.0, "away_db": -4.0}),
    # The Reckoning: riders pulling up on the green, heard from the cellar.
    # The recording is one horse at a gallop on stone that slows and stops
    # (its last three beats are at 7.5, 8.0 and 8.1 s). Cut to the arrival:
    # in fast (half a second: the film shakes the cellar as it starts, and
    # Bram's "She's early." comes a second later), two and a half seconds of
    # gallop, three of slowing, the stop. The top is
    # taken off above 1.2 kHz: it's heard through the taproom's floor, and
    # as recorded it's a horse in the room. (The one sound here with any
    # tone-shaping; say so if it's ever played anywhere it's seen.)
    "hooves": ("479699", "https://freesound.org/people/craigsmith/sounds/479699/",
        "R13-27-Horse Gallops and Stops on Stone.wav", 3.0, 8.6,
        {"loud": 0.2, "in": 0.5, "out": 0.4, "lowpass": 1200.0}),
}


def decode(path, speed=1.0):
    """The file as mono floats at 44.1 kHz (ffmpeg)."""
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "x.wav")
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", path, "-ac", "1", "-ar", str(SR),
            "-c:a", "pcm_s16le", out], check=True)
        with wave.open(out, "rb") as w:
            x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
    if speed != 1.0:
        x = signal.resample_poly(x, 1000, int(round(1000 * speed)))
    return x


def highpass(x, hz):
    b, a = signal.butter(2, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def loudest(x):
    """Its loudest twelfth of a second, above HEARD_FROM (RMS)."""
    win = int(LOUD_WIN * SR)
    heard = highpass(x, HEARD_FROM)
    if len(x) <= win:
        return float(np.sqrt(np.mean(heard * heard)))
    power = np.convolve(heard * heard, np.ones(win) / win, mode="same")
    return float(np.sqrt(np.max(power)))


def trim(x, longest):
    peak = float(np.max(np.abs(x)))
    first = int(np.argmax(np.abs(x) > peak * 0.01))
    x = x[max(0, first - int(PRE * SR)):]
    # the tail: the last moment its 10 ms loudness is within TAIL_DB of its loudest
    win = int(0.010 * SR)
    power = np.convolve(x * x, np.ones(win) / win, mode="same")
    floor = np.max(power) * 10 ** (TAIL_DB / 10.0)
    above = np.where(power > floor)[0]
    end = min(len(x), int(above[-1]) + int(0.03 * SR)) if len(above) else len(x)
    end = min(max(end, int(0.08 * SR)), int(longest * SR), len(x))
    x = x[:end].copy()
    fade = min(len(x), int(0.02 * SR))
    x[-fade:] *= np.linspace(1.0, 0.0, fade) ** 2
    return x


def limit(x):
    """No sample over PEAK: the gain comes down just before a peak (1 ms) and back after it."""
    need = np.minimum(1.0, PEAK / np.maximum(np.abs(x), 1e-9))
    look = int(0.001 * SR)
    # the least gain needed within a millisecond either side...
    padded = np.concatenate([np.ones(look), need, np.ones(look)])
    least = np.min(np.lib.stride_tricks.sliding_window_view(padded, 2 * look + 1), axis=1)
    # ...smoothed, so it doesn't step
    smooth = np.convolve(np.concatenate([np.full(look, least[0]), least, np.full(look, least[-1])]),
        np.hanning(2 * look + 1) / np.sum(np.hanning(2 * look + 1)), mode="valid")
    return x * np.minimum(smooth[:len(x)], need)


def low_share(x):
    """How much of it is under HEARD_FROM (0 to 1, by its spectrum)."""
    sp = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    fr = np.fft.rfftfreq(len(x), 1.0 / SR)
    return float(sp[fr < HEARD_FROM].sum() / (sp.sum() + 1e-12))


def fit(x, level, longest):
    x = trim(x, longest)
    x = highpass(x, 50.0)
    x = x - np.mean(x)
    peak = float(np.max(np.abs(x)))
    # a deep thump (a boot on boards is nine parts in ten under 180 Hz) is
    # barely limited at all: flattening a slow wave's top is heard as a
    # crunch, where a click's lost tip isn't
    allow = LIMIT_DB * (1.0 - low_share(x))
    gain = min(level / (loudest(x) + 1e-9), PEAK * 10 ** (allow / 20.0) / (peak + 1e-9))
    return limit(x * gain), gain


def body_rms(x):
    """A steady sound's level: the RMS of what's above HEARD_FROM."""
    heard = highpass(x, HEARD_FROM)
    return float(np.sqrt(np.mean(heard * heard)))


def fit_long(x, start, end, how):
    """A stretch of a long recording as a film sound: cut, its rumble and
    (if asked) its top taken off, levelled, and its fades written in."""
    x = x[int(start * SR):int(end * SR)].copy()
    x = highpass(x, 50.0)
    if "lowpass" in how:
        b, a = signal.butter(2, how["lowpass"] / (SR / 2), "low")
        x = signal.lfilter(b, a, x)
    x = x - np.mean(x)
    if "rms" in how:
        gain = 10 ** (how["rms"] / 20.0) / (body_rms(x) + 1e-9)
    else:
        gain = how["loud"] / (loudest(x) + 1e-9)
    gain = min(gain, PEAK * 10 ** (LIMIT_DB / 20.0) / (float(np.max(np.abs(x))) + 1e-9))
    x = limit(x * gain)
    n = len(x)
    shape = np.ones(n)
    fin = min(n, int(how.get("in", 0.0) * SR))
    fout = min(n - fin, int(how.get("out", 0.0) * SR))
    if "away_db" in how and n - fout - fin > 0:
        shape[fin:n - fout] = 10 ** (np.linspace(0.0, how["away_db"], n - fout - fin) / 20.0)
        shape[n - fout:] = 10 ** (how["away_db"] / 20.0)
    if fin > 0:
        shape[:fin] *= np.linspace(0.0, 1.0, fin) ** 2
    if fout > 0:
        shape[n - fout:] *= np.linspace(1.0, 0.0, fout) ** 2
    return x * shape, gain


def long_note(how):
    bits = []
    if "lowpass" in how:
        bits.append("top cut above %.1f kHz (heard through a floor)" % (how["lowpass"] / 1000.0))
    if "away_db" in how:
        bits.append("%d dB quieter by its end (it's leaving)" % abs(how["away_db"]))
    bits.append("fades in over %.1f s, out over %.1f s" % (how.get("in", 0.0), how.get("out", 0.0)))
    return "; ".join(bits)


def save(path, x):
    data = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def save_long(out_dir, name, x):
    """A long sound as Ogg (a tenth of a WAV's size; the short ones are
    WAV, which costs nothing at their length), or as WAV where this
    machine's ffmpeg has no Ogg encoder. The file's name, as saved."""
    for ext in ("ogg", "wav"):
        old = os.path.join(out_dir, "%s.%s" % (name, ext))
        if os.path.exists(old):
            os.remove(old)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "x.wav")
        save(wav, x)
        ogg = os.path.join(out_dir, name + ".ogg")
        done = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis",
            "-q:a", "5", ogg])
        if done.returncode == 0 and os.path.exists(ogg) and os.path.getsize(ogg) > 0:
            return name + ".ogg"
        if os.path.exists(ogg):
            os.remove(ogg)
    save(os.path.join(out_dir, name + ".wav"), x)
    return name + ".wav"


def main():
    args = sys.argv[1:]
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")
    if "--out" in args:
        i = args.index("--out")
        out_dir = args[i + 1]
        del args[i:i + 2]
    extra = ""
    if "--extra" in args:
        i = args.index("--extra")
        extra = args[i + 1]
        del args[i:i + 2]
    listing = "--list" in args
    args = [a for a in args if a != "--list"]
    if listing:
        for name, (pack, takes, level, longest, speed) in FIT.items():
            print("%-12s %-18s %s%s" % (name, PACKS[pack][0], ", ".join(takes), "" if speed == 1.0 else "  (at %.2f speed)" % speed))
        for name, (num, page, title, start, end, how) in LONG.items():
            print("%-12s %-18s %s, %.1f to %.1f s" % (name, "Freesound " + num, title, start, end))
        return
    if len(args) != 2:
        sys.exit(__doc__)
    folders = {"impact": args[0], "rpg": args[1]}
    os.makedirs(out_dir, exist_ok=True)
    notes = ["# Where the recorded sounds came from", "",
        "Written by `tools/fit_recorded_sounds.py` (25 and 26 November 2026). Both packs are",
        "Kenney's (www.kenney.nl), public domain under Creative Commons Zero (CC0):",
        "free to use in a game that's sold, with no credit owed. Gary downloaded them.",
        "Each file here is one recording, trimmed, levelled and saved as mono 16-bit",
        "WAV; nothing is mixed in. Every other sound in this folder was made by the",
        "tools in `tools/` (make_cries.py, make_steps.py and the rest) or is Gary's own.", "",
        "| File | Pack | Recording | Notes |", "| --- | --- | --- | --- |"]
    for name, (pack, takes, level, longest, speed) in FIT.items():
        for i, take in enumerate(takes):
            src = os.path.join(folders[pack], "Audio", take + ".ogg")
            if not os.path.exists(src):
                sys.exit("missing: %s" % src)
            raw = decode(src, speed)
            x, gain = fit(raw, level, longest)
            fname = "%s%s.wav" % (name, "" if i == 0 else "_%d" % (i + 1))
            save(os.path.join(out_dir, fname), x)
            got = loudest(x)
            print("%-18s %-24s %.2f s  gain %+5.1f dB  loud %.3f (asked %.3f)  peak %.2f" % (
                fname, take, len(x) / SR, 20 * np.log10(gain), got, level, float(np.max(np.abs(x)))))
            notes.append("| `%s` | [%s](%s) | `Audio/%s.ogg` | %s |" % (fname, PACKS[pack][0], PACKS[pack][1], take,
                "played at %.2f speed (lower, longer)" % speed if speed < 1.0 else ("played at %.2f speed (a little higher)" % speed if speed > 1.0 else "")))
    notes += ["", "## The two long recordings", "",
        "Each is a single download, not from a pack: Craig Smith's transfers of the",
        "USC film school's optical sound-effect library (Hollywood effects of the",
        "1930s to 1960s), on Freesound, public domain under Creative Commons Zero",
        "(CC0): free to use in a game that's sold, with no credit owed. Gary",
        "downloaded them on 26 November 2026. Each is one stretch of one recording,",
        "levelled, with its fades written into the file, saved as Ogg.", "",
        "| File | Recording | Stretch | Notes |", "| --- | --- | --- | --- |"]
    for name, (num, page, title, start, end, how) in LONG.items():
        notes.append("| `%s.ogg` | [%s](%s), by craigsmith | %.1f to %.1f s | %s |" % (name, title, page, start, end, long_note(how)))
        if extra == "":
            print("%-18s skipped: no --extra folder given (the file in assets/sfx is left as it is)" % name)
            continue
        found = sorted(f for f in glob.glob(os.path.join(extra, "*%s*" % num)) if os.path.isfile(f))
        if not found:
            sys.exit("missing: a file with %s in its name in %s (%s)" % (num, extra, page))
        x, gain = fit_long(decode(found[0]), start, end, how)
        fname = save_long(out_dir, name, x)
        print("%-18s %-24s %.2f s  gain %+5.1f dB  loud %.3f  body %.1f dB  peak %.2f" % (
            fname, "Freesound " + num, len(x) / SR, 20 * np.log10(gain), loudest(x),
            20 * np.log10(body_rms(x) + 1e-9), float(np.max(np.abs(x)))))
    if os.path.abspath(out_dir).endswith(os.path.join("assets", "sfx")):
        with open(os.path.join(out_dir, "SOURCES.md"), "w") as f:
            f.write("\n".join(notes) + "\n")


if __name__ == "__main__":
    main()
