#!/bin/sh
# Rebuilds a villager's model (assets/models/characters/<who>.glb) from Gary's
# AssetFurnace master file, the way tools/rig_player_a.sh does the player's:
#   tools/rig_villager.sh corin ~/incoming-18oct/Corin_Model/Corin_Master_12_Animations.glb
#   tools/rig_villager.sh tam   ".../Tam the miller model/Tam_Master_11_Animations.glb"
#   tools/rig_villager.sh tilly ".../Tilly model/Unknown_Tilly_Master_11_Animations.glb"
#   tools/rig_villager.sh nell  .../Old_Nell_model/Old_Nell_Master_10_Animations.glb
#   tools/rig_villager.sh hob   ".../Hob model/Hob_Master_8_Animations.glb"
#   tools/rig_villager.sh corin ".../corin model"      (19 Oct: the folder of his single-clip files)
# then `godot --headless --import`, re-render their portrait and check them
# (README, Story mode). Each keeps all of its own clips; the game's clips it
# lacks are fitted to it from clips/shared.glb, Bram's lift and (Corin, who
# came without a walk) the player's walk, run, sit and wave. AssetFurnace's
# walk and run lift the head 14 degrees above the idle's, so it's levelled.
set -e
cd "$(dirname "$0")/.."
who="$1"
src="$2"
out="assets/models/characters/$who.glb"
GAME="talk,duel_idle,play_card,victory,defeat,fall,look_up"
case "$who" in
corin)
	# a young man a little shorter than the player. Gary's 19 October set is
	# ten single-clip AssetFurnace files in one folder (..._idle.glb, _walk,
	# _run, _jump, _sit, _wave, _cheer, _dance, _punch, _death): the idle file
	# is the body and the others lend their one clip each (the same rig), so
	# he walks, runs, sits and waves as himself now; his 18 October fighting
	# clips come over from the model he had
	if [ -d "$src" ]; then
		# (copied to a folder with no spaces in its name first)
		tmp=$(mktemp -d)
		cp "$src"/*.glb "$tmp"/
		idle=$(ls "$tmp"/*_idle.glb | head -1)
		borrow=""
		for c in walk run jump sit wave cheer dance punch death; do
			f=$(ls "$tmp"/*_$c.glb 2>/dev/null | head -1)
			test -n "$f" && borrow="$borrow --borrow $f:*=$c"
		done
		old=assets/models/characters/corin.glb
		test -f "$old" && cp "$old" /tmp/corin_18oct.glb
		set -f   # (the "*=" in $borrow is for rig_character.py, not the shell)
		python3 tools/rig_character.py "$idle" "$out" --name Corin --height 1.72 \
			--cycle walk --cycle run --seam idle --seam dance \
			$borrow \
			--borrow "assets/models/characters/clips/shared.glb:$GAME" \
			--borrow assets/models/characters/bram.glb:lift \
			--borrow /tmp/corin_18oct.glb:fight_stance,flying_kick,hit_react,kata,kick,punch_combo \
			--head-up=-12:walk,run
		set +f
	else
		# the 18 October master: no walk, run, sit or wave of his own
		python3 tools/rig_character.py "$src" "$out" --name Corin --height 1.72 \
			--seam idle --seam fight_stance --seam dance \
			--borrow "assets/models/characters/clips/shared.glb:$GAME" \
			--borrow assets/models/characters/bram.glb:lift \
			--borrow assets/models/characters/player_a.glb:walk,run,sit,wave \
			--head-up=-12:walk,run
	fi
	;;
hob)
	# a farmer (bald, in his fifties): his own walk and run
	python3 tools/rig_character.py "$src" "$out" --name Hob --height 1.80 \
		--cycle walk --cycle run --seam idle \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
tam)
	# a big man
	python3 tools/rig_character.py "$src" "$out" --name Tam --height 1.88 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run
	;;
tilly)
	# a girl of about seven; her leather satchel and its strap (bound to her
	# arms by AssetFurnace: the bag stretched after her hand when she held her
	# card out) move with her body
	python3 tools/rig_character.py "$src" "$out" --name Tilly --height 1.25 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--head-up=-12:walk,run \
		--free-of-arms 0.40,0.27,0.21:0.14
	;;
nell)
	# a small, stooped old woman with a walking stick (part of her mesh, in her
	# right hand): that arm stays as in her idle wherever it would swing the
	# stick through her (talking, cheering, walking...)
	python3 tools/rig_character.py "$src" "$out" --name "Old Nell" --height 1.50 \
		--cycle walk --cycle run --seam idle --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--hold-arm Right:idle:walk,run,talk,cheer,look_up,duel_idle,play_card,victory,defeat \
		--head-up=-12:walk,run
	;;
*)
	echo "usage: $0 corin|tam|tilly|nell|hob <master.glb or folder of single-clip files>" >&2
	exit 1
	;;
esac
