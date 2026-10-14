"""Turns Gary's image-to-video clips into the opening movie's shots.

Usage: python3 tools/movie_clips.py <folder of clips> [--size 1600x900] [--q 5]

Each clip is named after its shot (shot_01.mp4, shot_07a.mov, shot_15.webm...).
It is cut (or held on its last frame) to that shot's exact length in
scripts/story/opening_movie.gd, fitted to 16:9, its sound dropped (the movie
has its own narration and music) and saved as Ogg Theora, the video format
Godot plays, in assets/movies/shots/<shot>.ogv. The movie picks each one up
automatically; shots without a clip keep their painting.
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]
if not args:
    sys.exit(__doc__)
src = args[0]
size = "1600x900"
q = "5"
if "--size" in args:
    size = args[args.index("--size") + 1]
if "--q" in args:
    q = args[args.index("--q") + 1]
w, h = size.split("x")
movie = open(os.path.join(ROOT, "scripts/story/opening_movie.gd")).read()
lengths = {m.group(1): float(m.group(2)) for m in re.finditer(r'"id": "(shot_\w+)", "len": ([\d.]+)', movie)}
out_dir = os.path.join(ROOT, "assets/movies/shots")
os.makedirs(out_dir, exist_ok=True)
total = 0
for f in sorted(os.listdir(src)):
    stem, ext = os.path.splitext(f)
    if ext.lower() not in (".mp4", ".mov", ".webm", ".mkv", ".m4v"):
        continue
    shot = stem.lower().strip().replace(" ", "_")
    m = re.match(r"(shot_\d+[a-z]?)", shot)
    if not m or m.group(1) not in lengths:
        print("skipped %s: name it after its shot, like shot_07a.mp4" % f)
        continue
    shot = m.group(1)
    secs = lengths[shot]
    dst = os.path.join(out_dir, shot + ".ogv")
    vf = ("scale=%s:%s:force_original_aspect_ratio=decrease,pad=%s:%s:(ow-iw)/2:(oh-ih)/2:black,"
          "fps=30,tpad=stop_mode=clone:stop_duration=%s,trim=duration=%s,setpts=PTS-STARTPTS,format=yuv420p") % (w, h, w, h, secs, secs)
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", os.path.join(src, f), "-an",
           "-vf", vf, "-c:v", "libtheora", "-q:v", q, dst]
    subprocess.run(cmd, check=True)
    kb = os.path.getsize(dst) // 1024
    total += kb
    print("%-9s %5.1f s  %6d KB  <- %s" % (shot, secs, kb, f))
print("total %.1f MB in assets/movies/shots" % (total / 1024))
