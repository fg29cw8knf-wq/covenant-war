#!/bin/sh
# Rebuilds a villager's model (assets/models/characters/<who>.glb) from Gary's
# AssetFurnace master file, the way tools/rig_player_a.sh does the player's:
#   tools/rig_villager.sh corin ~/incoming-18oct/Corin_Model/Corin_Master_12_Animations.glb
#   tools/rig_villager.sh tam   ".../Tam the miller model/Tam_Master_11_Animations.glb"
#   tools/rig_villager.sh tilly ".../Tilly model/Unknown_Tilly_Master_11_Animations.glb"
#   tools/rig_villager.sh nell  .../Old_Nell_model/Old_Nell_Master_10_Animations.glb
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
	# a young man a little shorter than the player; no walk, run, sit or wave of his own
	python3 tools/rig_character.py "$src" "$out" --name Corin --height 1.72 \
		--seam idle --seam fight_stance --seam dance \
		--borrow "assets/models/characters/clips/shared.glb:$GAME" \
		--borrow assets/models/characters/bram.glb:lift \
		--borrow assets/models/characters/player_a.glb:walk,run,sit,wave \
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
	echo "usage: $0 corin|tam|tilly|nell <master.glb>" >&2
	exit 1
	;;
esac
