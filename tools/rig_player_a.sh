#!/bin/sh
# Rebuilds the player's model (assets/models/characters/player_a.glb, look A,
# Gary's young man) from his Tripo3D Smart Mesh file: quads, a Mixamo rig of
# Tripo's own that fits him, a 4096 colour picture, and since the evening of
# 26 November (new_player_a_model-2.glb, the same model put through Tripo's
# PBR) its normal map and roughness-metal map, 4096 each:
#   tools/rig_player_a.sh <PlayerA.glb>
# then `godot --headless --import`, re-render his portrait and check him
# (README, "Player A's Smart Mesh body").
#
# He keeps every clip the game's Player A has now (the model in the game is
# the donor, copied aside first): the motion-captured 21, the game's own,
# Bram's lift and get_out_of_bed. Tripo's library clips in his file are left
# out (--drop-clips): they're stiffer (the arms hardly swing in its walk, its
# wave stops at the chest), and other models borrow his by name at run time
# (Figure3D.DONORS), so the set has to stay as it is.
#
# What's done to Gary's file, in order:
#   glb_bake_turn.py     the quarter turn Tripo leaves on the nodes over the rig
#   glb_weld.py          each quad's own four corners made one (113,956
#                        vertices to 60,303), its clips left out
#   rig_character.py     the game's skeleton names and rests, 1.76 m, the clips
#   paint_eyeballs.py    whites, pale silver-grey irises and pupils (his paint
#                        had the whole eyeball one glassy blue)
#   clean_under_arms.py  the waistcoat's paint off the underside of his sleeves
#   paint_face_marks.py  the light freckles over his nose and cheeks and the
#                        old scar through his left eyebrow that his sheet
#                        gives him and Tripo's paint left off (Gary's yes,
#                        26 November)
#   maps_follow_paint.py the normal and roughness maps put right where the
#                        paint was: Tripo worked them out from its own
#                        colour, so the sleeves' patches were still rough
#                        as the waistcoat; the eyeballs made flat and wet
# His normal and roughness maps are Tripo's, kept at 4096 (--mr-size): a
# Smart Mesh atlas is cut into thousands of islands a few texels across
# (5,796 here, where a High Detail Model's has about a hundred), and at the
# usual 1024 one island's roughness runs into the next. Never make one from
# his colour picture (tools/derive_creature_maps.py --person): the slopes
# worked out inside each little island don't agree with their neighbours',
# and his face came out in blocks (the portrait, the morning of 26 November).
# Built from his first file, with no maps, he gets none: the old ones are
# taken away rather than left laid over a picture they weren't made for.
set -e
cd "$(dirname "$0")/.."
src="$1"
test -f "$src" || { echo "usage: $0 <Gary's PlayerA.glb (Tripo3D Smart Mesh, rigged)>" >&2; exit 1; }
out=assets/models/characters/player_a.glb
tmp=$(mktemp -d)
cp "$out" "$tmp/donor.glb"
CLIPS="idle,walk,run,sneak,strafe_left,jump,sit,fight_stance,punch,punch_combo,kick,roundhouse,flying_kick,sword_swing,kata,hit_react,death,cheer,dance,wave,roll,talk,duel_idle,play_card,victory,defeat,fall,look_up,lift,get_out_of_bed"
python3 tools/glb_bake_turn.py "$src" "$tmp/baked.glb"
python3 tools/glb_weld.py "$tmp/baked.glb" "$tmp/welded.glb" --drop-clips
# (the picture's import settings are kept: rig_character.py writes plain ones)
cp "${out%.glb}_atlas.png.import" "$tmp/atlas.import"
for m in normal mr; do
    if test -f "${out%.glb}_$m.png.import"; then cp "${out%.glb}_$m.png.import" "$tmp/$m.import"; fi
    rm -f "${out%.glb}_$m.png" "${out%.glb}_$m.png.import"
done
python3 tools/rig_character.py "$tmp/welded.glb" "$out" --name "Player A" --height 1.76 \
    --borrow "$tmp/donor.glb:$CLIPS" --normal-map --mr-size 4096
cp "$tmp/atlas.import" "${out%.glb}_atlas.png.import"
for m in normal mr; do
    if test -f "${out%.glb}_$m.png" && test -f "$tmp/$m.import"; then cp "$tmp/$m.import" "${out%.glb}_$m.png.import"; fi
done
atlas="${out%.glb}_atlas.png"
# (the maker's picture kept aside: the face's marks are placed from the eyes,
# which are found by Tripo's paint, not by the eyes painted over it)
cp "$atlas" "$tmp/tripo.png"
python3 tools/paint_eyeballs.py "$out" "$atlas" "$tmp/eyes.png" --iris 0.57,0.61,0.65 --ring 0.55 --iris-share 0.60 --pupil 0.42
python3 tools/clean_under_arms.py "$out" "$tmp/eyes.png" "$tmp/clean.png"
# (nothing found, nothing written: the eyes' picture stands)
test -f "$tmp/clean.png" || cp "$tmp/eyes.png" "$tmp/clean.png"
python3 tools/paint_face_marks.py "$out" "$tmp/clean.png" "$tmp/marks.png" --eyes-from "$tmp/tripo.png"
cp "$tmp/marks.png" "$atlas"
if test -f "${out%.glb}_normal.png" && test -f "${out%.glb}_mr.png"; then
    python3 tools/maps_follow_paint.py "$out" "$tmp/tripo.png" "$atlas" "${out%.glb}_normal.png" "${out%.glb}_mr.png"
fi
rm -rf "$tmp"
