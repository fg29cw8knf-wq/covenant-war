#!/bin/sh
# Rebuilds one of the player's looks (assets/models/characters/player_<look>.glb,
# the look chosen in the attic mirror) from Gary's AssetFurnace master with its
# 21 clips, the way tools/rig_player_a.sh does look A:
#   tools/rig_player.sh b ".../Player B model/Player_B_New_21_Animations.glb"   (20 Oct)
#   tools/rig_player.sh c ".../Player C model/Player_C_Master_21_Animations.glb"
#   tools/rig_player.sh d ".../Player D model/Player_D_Master_21_Animations.glb"
# then `godot --headless --import`, render the look's portrait
# (tools/render_portraits.tscn -- player_<look>), put its paces in
# Figure3D.OWN_GAIT and run tests/clips_check.gd (README, Story mode). The
# mirror offers a look the moment its file exists.
set -e
cd "$(dirname "$0")/.."
look="$1"
src="$2"
case "$look" in
b) name="Player B"; height=1.76 ;;   # Gary's Player B (20 October): a young man with stubble and a strap (not look A, Gary says)
c) name="Player C"; height=1.68 ;;   # Player C: the dark-haired young woman in green
d) name="Player D"; height=1.82 ;;   # Player D: the bearded man in blue
*) echo "usage: $0 b|c|d <master.glb>" >&2; exit 1 ;;
esac
python3 tools/rig_character.py "$src" "assets/models/characters/player_$look.glb" --name "$name" --height $height \
    --cycle walk --cycle run --cycle sneak --seam idle --seam fight_stance --seam dance \
    --borrow assets/models/characters/clips/shared.glb:talk,duel_idle,play_card,victory,defeat,fall,look_up \
    --borrow assets/models/characters/bram.glb:lift \
    --head-up 10:idle,talk,duel_idle,play_card,victory,defeat,fall,look_up,lift
