#!/bin/sh
# Makes the phone link's streaming copy of one of Gary's 4K films (HLS: the
# format the browser's own video player streams on an iPhone, and hls.js on
# every other browser), so the phone link can play the film in 4K without
# downloading all of it first:
#
#   tools/make_hls.sh <film.mp4> <out dir>      # e.g. opening_4k.mp4 build/films/opening
#
# Three copies of the picture, cut into the same 4-second pieces so the player
# can move between them at any piece as the connection allows:
#   2160p60  Gary's own 4K picture, untouched (copied, not re-encoded)
#   1080p60  about 6 Mb/s, the one a phone starts on
#   540p60   about 1.4 Mb/s, for a poor connection
# The pieces are cut at the master's own keyframes (every 250 frames in the
# opening), and the two smaller copies keep the master's own frame times
# (-fps_mode passthrough) with keyframes forced at exactly those moments, so
# every copy's pieces start on the same frame and the player can step between
# them without a stutter.
# The sound is the film's own AAC, copied into every piece.
# Out: <out dir>/master.m3u8 (the list of copies, 1080p first so it starts
# quickly) and <out dir>/<copy>/index.m3u8 with its pieces.
# Needs ffmpeg and ffprobe. Takes a few minutes for the two smaller copies.
set -e
SRC=$1
OUT=$2
[ -f "$SRC" ] && [ -n "$OUT" ] || { echo "usage: tools/make_hls.sh <film.mp4> <out dir>"; exit 1; }
mkdir -p "$OUT/2160" "$OUT/1080" "$OUT/540"
KEYS=$(ffprobe -v error -select_streams v:0 -skip_frame nokey -show_entries frame=pts_time -of csv=p=0 "$SRC" | tr -d ',' | tr '\n' ',' | sed 's/,$//')
SEG=4
hls() {
	# $1: copy name, then ffmpeg's video options
	name=$1; shift
	ffmpeg -hide_banner -loglevel error -y -i "$SRC" -map 0:v:0 -map 0:a:0 "$@" -c:a copy \
		-f hls -hls_time $SEG -hls_playlist_type vod -hls_segment_type mpegts \
		-hls_segment_filename "$OUT/$name/%03d.ts" "$OUT/$name/index.m3u8"
	echo "$name: $(ls "$OUT/$name" | grep -c '\.ts$') pieces, $(du -sm "$OUT/$name" | cut -f1) MB"
}
hls 2160 -c:v copy
hls 1080 -fps_mode passthrough -vf scale=1920:1080:flags=lanczos -c:v libx264 -preset faster -profile:v high -level 4.2 -pix_fmt yuv420p \
	-crf 20 -maxrate 6500k -bufsize 13000k -force_key_frames "$KEYS" -g 600 -keyint_min 600 -sc_threshold 0
hls 540 -fps_mode passthrough -vf scale=960:540:flags=lanczos -c:v libx264 -preset faster -profile:v main -level 3.2 -pix_fmt yuv420p \
	-crf 23 -maxrate 1500k -bufsize 3000k -force_key_frames "$KEYS" -g 600 -keyint_min 600 -sc_threshold 0
python3 - "$OUT" "$SRC" <<'EOF'
import os, sys, re, subprocess
out, src = sys.argv[1], sys.argv[2]
def peak(name):
	# the busiest piece, in bits a second (what BANDWIDTH must say)
	text = open(os.path.join(out, name, "index.m3u8")).read()
	durs = [float(d) for d in re.findall(r"#EXTINF:([0-9.]+)", text)]
	files = re.findall(r"^(\d+\.ts)$", text, re.M)
	rates = [os.path.getsize(os.path.join(out, name, f)) * 8 / d for f, d in zip(files, durs) if d > 0.5]
	avg = sum(os.path.getsize(os.path.join(out, name, f)) for f in files) * 8 / sum(durs)
	return int(max(rates) * 1.05), int(avg)
copies = [("1080", "1920x1080", "60.000", "avc1.64002a"), ("2160", "3840x2160", "60.000", "avc1.42c034"), ("540", "960x540", "60.000", "avc1.4d4020")]
lines = ["#EXTM3U", "#EXT-X-VERSION:3", "#EXT-X-INDEPENDENT-SEGMENTS"]
for name, res, fps, codec in copies:
	bw, avg = peak(name)
	lines.append('#EXT-X-STREAM-INF:BANDWIDTH=%d,AVERAGE-BANDWIDTH=%d,RESOLUTION=%s,FRAME-RATE=%s,CODECS="%s,mp4a.40.2"' % (bw, avg, res, fps, codec))
	lines.append("%s/index.m3u8" % name)
open(os.path.join(out, "master.m3u8"), "w").write("\n".join(lines) + "\n")
print(open(os.path.join(out, "master.m3u8")).read())
EOF
du -sh "$OUT"
