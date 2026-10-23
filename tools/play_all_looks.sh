#!/bin/sh
# The play-through as every look, in one command (Gary's standing rule of 22
# October: after each update, the game played as looks A, B, C and D with
# the stills looked at): the opening (the attic to "Find Tam", with the mirror
# choosing the look) and Chapter 1 in Solhaven as each look, a still on every
# line, into <dir>/<look>/opening and <dir>/<look>/solhaven. Each run's
# verdict line and any problems are printed as it goes and kept in
# <dir>/summary.txt; the exit code is the number of runs with problems.
#
#   tools/play_all_looks.sh /tmp/looks            # all four looks, both parts
#   tools/play_all_looks.sh /tmp/looks b d        # just these looks
#   PARTS="opening" tools/play_all_looks.sh /tmp/looks   # or PARTS="solhaven"
#
# Needs xvfb-run and Godot 4.7.2 (GODOT=... to name it). Each run takes a few
# minutes here; the stills are the point: look through them.
set -u
GODOT=${GODOT:-godot}
PARTS=${PARTS:-"opening solhaven"}
out=${1:-/tmp/looks}
shift 2>/dev/null || true
looks=${*:-"a b c d"}
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
			xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 8 \
				res://tests/ashford_test.tscn -- "$dir" opening keys "look=$look" > "$log" 2>&1
			verdict=$(grep -E "^ASHFORD TEST" "$log" | tail -1)
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
