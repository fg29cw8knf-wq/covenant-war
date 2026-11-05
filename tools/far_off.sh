#!/bin/sh
# Makes a close, dry recording sound far off and down a valley, for a sound
# heard from a distance: Nell crying on the green, carried up the hill to the
# player at the look back (assets/audio/sfx/nell_crying.ogg, played in a loop
# under the bell by AshfordNight._nell_crying). The recording is levelled,
# its lows and highs thinned the way distance thins them, given a soft
# double echo off the valley sides, and faded at each end so the loop's join
# can't be heard; Gary's file is kept untouched in assets/audio/source/.
#
#   tools/far_off.sh <recording> assets/audio/sfx/nell_crying.ogg
# With a third argument, nofade, the ends aren't faded and the file is written
# as a .wav for tools/sfx_loop.py to make the join (5 November: Gary's crying is
# 5.9 s, too short for 1.5 s fades at each end; sfx_loop.py --pad 3 --fade 2
# puts a pause between the bouts and crossfades the start out of the quiet).
set -e
in=${1:?"usage: tools/far_off.sh <recording> <out.ogg> [nofade]"}
out=${2:?"usage: tools/far_off.sh <recording> <out.ogg> [nofade]"}
len=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
fade_out=$(python3 -c "print(max(0.0, $len - 1.5))")
fades=",afade=t=in:st=0:d=1.5,afade=t=out:st=$fade_out:d=1.5"
codec="-c:a libvorbis -q:a 4"
if [ "$3" = "nofade" ]; then
	fades=""
	codec="-c:a pcm_s16le"
fi
ffmpeg -hide_banner -loglevel error -y -i "$in" -ac 1 -ar 44100 -af "\
loudnorm=I=-20:TP=-3:LRA=11,\
highpass=f=260,lowpass=f=2800,\
aecho=0.85:0.55:140|310:0.30|0.16$fades" \
	$codec "$out"
echo "$out: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out") s, far off; run godot --headless --import"
