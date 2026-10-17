#!/bin/sh
# Rebuilds the player's model (assets/models/characters/player_a.glb, look A,
# Gary's young man) from Gary's AssetFurnace master with its 21 clips:
#   tools/rig_player_a.sh ~/Downloads/Player_B_Master_21_Animation_Package/Player_B_Master_21_Animations.glb
# then `godot --headless --import` and re-render his portrait (README).
set -e
cd "$(dirname "$0")/.."
python3 tools/rig_character.py "$1" assets/models/characters/player_a.glb --name "Player A" --height 1.76 \
    --cycle walk --cycle run --cycle sneak --seam idle --seam fight_stance --seam dance \
    --borrow assets/models/characters/clips/shared.glb:talk,duel_idle,play_card,victory,defeat,fall,look_up \
    --borrow assets/models/characters/bram.glb:lift \
    --head-up 10:idle,talk,duel_idle,play_card,victory,defeat,fall,look_up,lift
