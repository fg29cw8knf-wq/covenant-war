#!/bin/sh
# Rebuilds a villager's model (assets/models/characters/<who>.glb) from Gary's
# AssetFurnace master file, the way tools/rig_player_a.sh does the player's:
#   tools/rig_villager.sh corin ~/incoming-18oct/Corin_Model/Corin_Master_12_Animations.glb
#   tools/rig_villager.sh tam   ".../Tam the miller model/Tam_Master_11_Animations.glb"
#   tools/rig_villager.sh tilly ".../Tilly model/Unknown_Tilly_Master_11_Animations.glb"
#   tools/rig_villager.sh nell  .../Old_Nell_model/Old_Nell_Master_10_Animations.glb
#   tools/rig_villager.sh hob   ".../Hob model/Hob_Master_8_Animations.glb"
#   tools/rig_villager.sh bram  ".../Bram model/Bram_Master_18_Animations.glb"   (20 Oct)
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
	# a young man a little shorter than the player. Given a folder of
	# single-clip AssetFurnace files (..._idle.glb, _walk, _run, _jump, _sit,
	# _wave, _cheer, _dance, _punch, _death), the idle file is the body and
	# the others lend their one clip each (the same rig), so he'd walk, run,
	# sit and wave as himself; his 18 October fighting clips come over from
	# the model he had. (The "corin model" folder of 19 October turned out to
	# hold Old Nell's files, so his 18 October model stands until his come.)
	if [ -d "$src" ]; then
		# (copied to a folder with no spaces in its name first)
		tmp=$(mktemp -d)
		cp "$src"/*.glb "$tmp"/
		# the body: the idle file, or (Gary's 20 October folder, "Corins extra
		# movements", which has only walk, run, sit and wave) the walk file,
		# with his idle and everything else from the 18 October model
		idle=$(ls "$tmp"/*_idle.glb 2>/dev/null | head -1)
		body="$idle"
		bodyclip=idle
		if [ -z "$body" ]; then
			body=$(ls "$tmp"/*_walk.glb | head -1)
			bodyclip=walk
		fi
		borrow=""
		for c in idle walk run jump sit wave cheer dance punch death; do
			test "$c" = "$bodyclip" && continue
			f=$(ls "$tmp"/*_$c.glb 2>/dev/null | head -1)
			test -n "$f" && borrow="$borrow --borrow $f:*=$c"
		done
		# (his 18 October model, as committed: the one with the fighting clips,
		# and his idle, jump, cheer, dance, punch and death when the folder
		# lacks them)
		git show 0afe166:assets/models/characters/corin.glb > /tmp/corin_18oct.glb
		set -f   # (the "*=" in $borrow is for rig_character.py, not the shell)
		python3 tools/rig_character.py "$body" "$out" --name Corin --height 1.72 \
			--rename ArmatureAction=$bodyclip \
			--cycle walk --cycle run --seam idle --seam dance \
			$borrow \
			--borrow /tmp/corin_18oct.glb:idle,jump,cheer,dance,punch,death \
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
bram)
	# the innkeeper (grey-haired, in his sixties, in a leather apron): Gary's
	# 20 October master with his own idle, walk, run, sit, wave, dance and
	# fighting clips. His lift (he lifts the lantern crate, and everyone
	# borrows it) and his cheer come over from the stand-in model he had
	# (committed on 11 October; git show 3c521d9:... is the last of it)
	git show 3c521d9:assets/models/characters/bram.glb > /tmp/bram_standin.glb
	python3 tools/rig_character.py "$src" "$out" --name Bram --height 1.84 \
		--cycle walk --cycle run --seam idle --seam dance --seam fight_stance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow /tmp/bram_standin.glb:lift,cheer \
		--head-up=-12:walk,run
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
	echo "usage: $0 bram|corin|tam|tilly|nell|hob <master.glb or folder of single-clip files>" >&2
	exit 1
	;;
esac
