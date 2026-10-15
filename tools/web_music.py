#!/usr/bin/env python3
"""Gets a web export's music ready: the web build plays its music through the
page's own player (scripts/ui/music_web.js), because Godot's web audio can't
loop a track from its loop point without a gap. Run by tools/build_web.sh.

For every track in assets/audio/music/ this writes <web>/music/<name>.mp3 (MP3,
because Safari on iPhone decodes it reliably; Ogg it doesn't) and
<web>/music/manifest.json with each track's real length (the loop's end, taken
from the source file, since MP3 decoders may pad the end of the audio) and
where it first gets loud (to spot padding a decoder leaves at the start).
Then it puts the track list and the player into index.html.
The loop start points stay in Music.LOOP_START (scripts/ui/music.gd).

    python3 tools/web_music.py build/web
"""
import concurrent.futures
import glob
import hashlib
import json
import os
import subprocess
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MUSIC = os.path.join(ROOT, "assets", "audio", "music")
PLAYER = os.path.join(ROOT, "scripts", "ui", "music_web.js")
ONSET_LEVEL = 0.05   # the same as music_web.js
BITRATE = "192k"


def tracks():
    """name -> source file, preferring .ogg, then .mp3, then .wav (like Music.path_for)."""
    found = {}
    for ext in ("ogg", "mp3", "wav"):
        for path in sorted(glob.glob(os.path.join(MUSIC, "*." + ext))):
            found.setdefault(os.path.splitext(os.path.basename(path))[0], path)
    return found


def make(name, src, out_dir):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-f", "f32le", "-ac", "2", "-"],
                         capture_output=True, check=True).stdout
    rate = int(subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=sample_rate",
                               "-of", "csv=p=0", src], capture_output=True, text=True, check=True).stdout.strip())
    pcm = np.frombuffer(raw, np.float32).reshape(-1, 2)
    loud = np.flatnonzero(np.abs(pcm[:rate * 10]).max(axis=1) >= ONSET_LEVEL)
    mp3 = os.path.join(out_dir, name + ".mp3")
    # the LAME header ffmpeg writes tells decoders how much padding to drop
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-map", "0:a:0", "-map_metadata", "-1",
                    "-c:a", "libmp3lame", "-b:a", BITRATE, mp3], check=True)
    with open(mp3, "rb") as f:
        tag = hashlib.sha1(f.read()).hexdigest()[:10]
    return name, {
        "file": "%s.mp3?v=%s" % (name, tag),
        "length": round(len(pcm) / rate, 9),
        "onset": round(int(loud[0]) / rate, 6) if len(loud) else None,
    }


def main():
    web = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    out_dir = os.path.join(web, "music")
    os.makedirs(out_dir, exist_ok=True)
    found = tracks()
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 2) as pool:
        made = dict(pool.map(lambda kv: make(kv[0], kv[1], out_dir), found.items()))
    made = {k: made[k] for k in sorted(made)}
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(made, f, indent=1)

    html = os.path.join(web, "index.html")
    page = open(html).read()
    assert "window.CW_MUSIC" not in page, "index.html already has the music player"
    with open(PLAYER) as f:
        player = f.read()
    assert "</script" not in player.lower(), "music_web.js can't contain </script> (it goes inline)"
    script = "<script>\nwindow.CW_MUSIC = %s;\n%s</script>\n" % (
        json.dumps({"base": "music/", "tracks": made}, separators=(",", ":")), player)
    assert "</head>" in page
    page = page.replace("</head>", script + "</head>", 1)
    with open(html, "w") as f:
        f.write(page)
    size = sum(os.path.getsize(os.path.join(out_dir, n + ".mp3")) for n in made)
    print("music: %d tracks as MP3 (%.1f MB) in %s, player added to index.html" % (len(made), size / 1048576, out_dir))


if __name__ == "__main__":
    main()
