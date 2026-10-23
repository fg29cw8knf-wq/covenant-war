"""Turns Gary's image-to-video clips into a movie's shots.

Usage: python3 tools/movie_clips.py <folder of clips> [--film midnight|dawn] [--size 1600x900] [--q 5]

The opening movie (no --film): each clip is named after its shot (shot_01.mp4,
shot_07a.mov, shot_15.webm...). It is cut (or held on its last frame) to that
shot's exact length in scripts/story/opening_movie.gd, fitted to 16:9, its
sound dropped (the movie has its own narration and music) and saved as Ogg
Theora, the video format Godot plays, in assets/movies/shots/<shot>.ogv. The
movie picks each one up automatically; shots without a clip keep their painting.

A story film (--film midnight, --film dawn: StoryFilm in
scripts/story/story_film.gd): the clips are named after the film's shots
(mid_01.mp4, dawn_07.mov...), and a shot that shows the player can come as
one clip per look (mid_02_a.mp4, mid_02_b.mp4, _c, _d). They are cut to the
shot's length the same way and saved in assets/movies/<film>/<shot>.ogv. The
film plays in place of the engine's 3D scene once every shot has a clip or a
painting (assets/art/movie/<film>/<shot>.png).
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]
if not args:
    sys.exit(__doc__)
src = args[0]
size = "1600x900"
q = "5"
film = ""
if "--size" in args:
    size = args[args.index("--size") + 1]
if "--q" in args:
    q = args[args.index("--q") + 1]
if "--film" in args:
    film = args[args.index("--film") + 1]
w, h = size.split("x")
if film:
    text = open(os.path.join(ROOT, "scripts/story/story_film.gd")).read()
    m = re.search(r'"%s": \{(.*?)\n\t\},\n' % re.escape(film), text, re.S)
    if not m:
        sys.exit("no film called %s in scripts/story/story_film.gd" % film)
    lengths = {s.group(1): float(s.group(2)) for s in re.finditer(r'"id": "(\w+)", "len": ([\d.]+)', m.group(1))}
    out_dir = os.path.join(ROOT, "assets/movies", film)
    name_re = r"((?:%s)_\d+[a-z]?)(?:_([abcd]))?$" % "|".join(sorted({k.split("_")[0] for k in lengths}))
    example = next(iter(lengths)) + ".mp4"
else:
    movie = open(os.path.join(ROOT, "scripts/story/opening_movie.gd")).read()
    lengths = {m.group(1): float(m.group(2)) for m in re.finditer(r'"id": "(shot_\w+)", "len": ([\d.]+)', movie)}
    out_dir = os.path.join(ROOT, "assets/movies/shots")
    name_re = r"(shot_\d+[a-z]?)()"
    example = "shot_07a.mp4"
os.makedirs(out_dir, exist_ok=True)
total = 0
for f in sorted(os.listdir(src)):
    stem, ext = os.path.splitext(f)
    if ext.lower() not in (".mp4", ".mov", ".webm", ".mkv", ".m4v"):
        continue
    shot = stem.lower().strip().replace(" ", "_")
    m = re.match(name_re, shot)
    if not m or m.group(1) not in lengths:
        print("skipped %s: name it after its shot, like %s" % (f, example))
        continue
    shot = m.group(1)
    look = m.group(2) or ""
    secs = lengths[shot]
    dst = os.path.join(out_dir, shot + ("_" + look if look else "") + ".ogv")
    vf = ("scale=%s:%s:force_original_aspect_ratio=decrease,pad=%s:%s:(ow-iw)/2:(oh-ih)/2:black,"
          "fps=30,tpad=stop_mode=clone:stop_duration=%s,trim=duration=%s,setpts=PTS-STARTPTS,format=yuv420p") % (w, h, w, h, secs, secs)
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", os.path.join(src, f), "-an",
           "-vf", vf, "-c:v", "libtheora", "-q:v", q, dst]
    subprocess.run(cmd, check=True)
    kb = os.path.getsize(dst) // 1024
    total += kb
    print("%-11s %5.1f s  %6d KB  <- %s" % (os.path.basename(dst)[:-4], secs, kb, f))
print("total %.1f MB in %s" % (total / 1024, os.path.relpath(out_dir, ROOT)))
