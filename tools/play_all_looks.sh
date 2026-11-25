#!/bin/sh
# The play-through as every look, in one command (Gary's standing rule of 22
# October: after each update, the game played as looks A, B, C and D with
# the stills looked at): the Prologue from New Game (the attic, the mirror,
# the taproom, the street, the Lantern Duel and on to midnight) and Chapter 1
# in Solhaven as each look, a still on every line, into <dir>/<look>/opening
# and <dir>/<look>/solhaven. Each run's verdict line and any problems are
# printed as it goes and kept in <dir>/summary.txt; the exit code is the
# number of runs with problems.
#
# (25 November: the opening is tests/p1_v7_test now. It was ashford_test's
# "opening", which waits for the mirror to come up by itself and has timed
# out there since the walk to the washbasin became the player's, in
# mid-November; every run of this script since had its four openings fail.)
#
# (25 November, Gary: "you only need to worry about player a dont add
# anything for b,c or d well add the later once the game is done". So it
# plays look A unless looks are named.)
#
#   tools/play_all_looks.sh /tmp/looks            # Player A, both parts
#   tools/play_all_looks.sh /tmp/looks a b c d    # these looks (for when B, C and D are wanted again)
#   PARTS="opening" tools/play_all_looks.sh /tmp/looks   # or PARTS="solhaven"
#   STOP="Tam at the mill" tools/play_all_looks.sh /tmp/looks   # the opening as far as
#       the wait p1_v7_test describes in those words (here: past the Lantern
#       Duel), for when the half hour to midnight four times over is too long
#
# Needs xvfb-run and Godot 4.7.2 (GODOT=... to name it). Each run takes a few
# minutes here (the whole opening about half an hour); the stills are the
# point: look through them.
set -u
GODOT=${GODOT:-godot}
PARTS=${PARTS:-"opening solhaven"}
out=${1:-/tmp/looks}
shift 2>/dev/null || true
looks=${*:-"a"}
mkdir -p "$out"
summary="$out/summary.txt"
: > "$summary"
bad=0
for look in $looks; do
	for part in $PARTS; do
		dir="$out/$look/$part"
		mkdir -p "$dir"
		log="$dir/run.log"
		case "$part" in
		opening)
			if [ -n "${STOP:-}" ]; then
				xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
					res://tests/p1_v7_test.tscn -- "$dir" keys "look=$look" "stop=$STOP" > "$log" 2>&1
			else
				xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
					res://tests/p1_v7_test.tscn -- "$dir" keys "look=$look" > "$log" 2>&1
			fi
			verdict=$(grep -E "^P1 V7 TEST" "$log" | tail -1)
			;;
		solhaven)
			xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
				res://tests/solhaven_test.tscn -- "$dir" keys "look=$look" > "$log" 2>&1
			verdict=$(grep -E "^SOLHAVEN TEST" "$log" | tail -1)
			;;
		*)
			echo "unknown part: $part" >&2
			exit 2
			;;
		esac
		problems=$(grep -c "^PROBLEM" "$log" || true)
		stills=$(ls "$dir"/*.png 2>/dev/null | wc -l | tr -d ' ')
		line="look $look, $part: ${verdict:-no verdict (see $log)} ($stills stills, $problems problem lines)"
		echo "$line" | tee -a "$summary"
		grep "^PROBLEM" "$log" | tee -a "$summary"
		case "$verdict" in
		*ok*|*PASS*) ;;
		*) bad=$((bad + 1)) ;;
		esac
	done
done
echo "play_all_looks: $bad run(s) with problems; stills under $out, summary in $summary"
exit "$bad"
