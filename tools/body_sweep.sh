#!/bin/bash
# The Prologue played through with the body check (tests/body_check.gd), as
# each of the four looks (12 November, Gary: the model glitches he kept
# finding himself; his standing rule: every look). Draws only the frames it
# keeps, so it runs at the speed of the game's own scripts:
#
#   tools/body_sweep.sh <out_dir> [parts] [looks]
#
# parts (default all): snow (the Night of the White Sky), p1 (the attic to
# midnight), ashford (midnight to leaving Ashford), thorn (the Thornwood to
# the ridge). looks (default "a b c d"). Each run's log is <out_dir>/<run>.log,
# its stills <out_dir>/<run>/ and the body check's <out_dir>/<run>/body/.
# Look A is checked for everyone, drawn (a still at every line and of every
# finding); B, C and D for the player only (the rest don't change with the
# look): after midnight and the Thornwood headless (no stills, only the
# checks, under a minute each), P1 drawn up to the street (headless the
# attic's mirror never finishes).
# Then: python3 tools/body_report.py <out_dir> (contact sheets and a list).
# Every Godot run goes through flock /tmp/godot.lock, so two sweeps (or a
# sweep and another test) take turns.

OUT=${1:-/tmp/body_sweep}
PARTS=${2:-"snow p1 ashford thorn"}
LOOKS=${3:-"a b c d"}
cd "$(dirname "$0")/.." || exit 1
mkdir -p "$OUT"

run() {
	local name=$1; shift
	echo "== $name ($(date -u +%H:%M:%S))"
	mkdir -p "$OUT/$name"
	if [ "$HEADLESS" = 1 ]; then
		flock /tmp/godot.lock timeout 7200 godot --headless --path . "$@" > "$OUT/$name.log" 2>&1
	else
		flock /tmp/godot.lock timeout 7200 xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
			--resolution 1280x720 --path . "$@" > "$OUT/$name.log" 2>&1
	fi
	echo "   exit $? ($(date -u +%H:%M:%S)): $(grep -h "TEST:\|white_sky_test: PASS\|white_sky_test: FAIL\|FILM: done" "$OUT/$name.log" | tail -1 | cut -c1-160)"
	grep -h "^BODY SUMMARY\|^QA SUMMARY" "$OUT/$name.log" | sed 's/^/   /'
}

# look A first, the whole way (everyone checked); then B, C and D, the
# player's own body only (everyone else is the same in every look)
for l in $LOOKS; do
	only=""
	HEADLESS=0
	# (B, C and D: the player only, and nothing drawn: the checks without
	# stills, much faster; a moment worth seeing is drawn afterwards)
	[ "$l" != "a" ] && only="body_only=player" && HEADLESS=1
	for part in $PARTS; do
		case $part in
			snow)
				[ "$l" = "$(echo $LOOKS | cut -d' ' -f1)" ] && run snow --fixed-fps 10 res://tests/white_sky_test.tscn -- "$OUT/snow" 4 keys body ;;
			p1)
				# (headless, the attic's mirror never finishes, and drawn it's half
				# an hour a look: B, C and D up to the street, the attic, the mirror,
				# the porridge and the crate, the player's own close work)
				if [ "$HEADLESS" = 1 ]; then
					HEADLESS=0 run "p1_$l" --fixed-fps 8 res://tests/p1_v7_test.tscn -- "$OUT/p1_$l" keys body "look=$l" stop=street $only
				else
					run "p1_$l" --fixed-fps 8 res://tests/p1_v7_test.tscn -- "$OUT/p1_$l" keys body "look=$l" $only
				fi ;;
			ashford)
				run "ashford_$l" --fixed-fps 8 res://tests/film_test.tscn -- "$OUT/ashford_$l" midnight 400 keys body "look=$l" $only ;;
			thorn)
				run "thorn_$l" --fixed-fps 8 res://tests/film_test.tscn -- "$OUT/thorn_$l" river 400 keys body "look=$l" $only ;;
		esac
	done
done
echo "== done ($(date -u +%H:%M:%S))"
