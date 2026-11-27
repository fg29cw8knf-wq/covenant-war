#!/bin/sh
# Rebuilds a person's model (assets/models/characters/<who>.glb) from Gary's
# Tripo3D Smart Mesh file, the way tools/rig_player_a.sh does the player's:
# Tripo's own Mixamo rig kept (on a Smart Mesh it fits), every clip the model
# in the game has now carried across to the new body, and the new file's
# normal and roughness maps kept at full size and put right for skin.
#
#   tools/rig_person.sh <who> <Tripo file.glb> --name "Bram" --height 1.84 \
#       [--eyes "<paint_eyeballs.py args>"] [--maps "<maps_follow_paint.py args>"]
#
#   tools/rig_person.sh bram_coat younger_bram.glb --name Bram --height 1.84 \
#       --maps "--eye=-0.0646,1.7143 --eye=0.0020,1.7112"
#                       (27 November: the memory's Bram in his coat, Smart Mesh;
#                       his grey hair reads as eye paint to the eye finder, so
#                       his eyes' places are given)
#
# Gary adds moves through ChatGPT; a person keeps the game's own whatever
# the file brings (the story's clips are named and timed for it), so the
# file's are dropped. The steps:
#   glb_bake_turn.py      Tripo's rest turn baked in (it faces +Z)
#   glb_weld.py           Tripo's split vertices welded, its clips dropped
#   rig_character.py      the standard skeleton, its height, every clip of the
#                         model it replaces (--borrow), its normal map and
#                         its roughness at the atlas's size (--mr-size 4096:
#                         a Smart Mesh atlas is thousands of tiny islands)
#   paint_eyeballs.py     only with --eyes: eyes Tripo left flat (Player A's)
#   clean_under_arms.py   paint of the body on the underside of the arms,
#                         from a model made arms-down; writes nothing if none
#   maps_follow_paint.py  the maps where the paint was changed, the eyes wet,
#                         and Tripo's two faults on skin: too shiny, ridged at
#                         every hard edge of the paint (brows, hairline)
# The picture's import settings are kept. Then `godot --headless --import`,
# and the model's own settings (Figure3D: HANDS, MOUTHS, POSTURE, FROZEN,
# OWN_GAIT; any scene's) looked at again on the new body.
set -e
cd "$(dirname "$0")/.."
who="$1"
src="$2"
shift 2 || true
name=""
height=""
eyes=""
maps=""
while [ $# -gt 0 ]; do
    case "$1" in
    --name) name="$2"; shift 2 ;;
    --height) height="$2"; shift 2 ;;
    --eyes) eyes="$2"; shift 2 ;;
    --maps) maps="$2"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
    esac
done
out="assets/models/characters/$who.glb"
test -f "$src" && test -f "$out" && test -n "$name" && test -n "$height" || {
    echo "usage: $0 <who> <Tripo file.glb> --name NAME --height METRES [--eyes ARGS]  (the model in the game lends its clips)" >&2; exit 1; }
tmp=$(mktemp -d)
cp "$out" "$tmp/donor.glb"
CLIPS=$(python3 -I -c "
import json, struct, sys
f = open(sys.argv[1], 'rb'); f.read(12); n, _ = struct.unpack('<I4s', f.read(8))
print(','.join(a['name'] for a in json.loads(f.read(n)).get('animations', [])))" "$tmp/donor.glb")
echo "$who: carrying across $CLIPS"
python3 tools/glb_bake_turn.py "$src" "$tmp/baked.glb"
python3 tools/glb_weld.py "$tmp/baked.glb" "$tmp/welded.glb" --drop-clips
cp "${out%.glb}_atlas.png.import" "$tmp/atlas.import"
for m in normal mr; do
    if test -f "${out%.glb}_$m.png.import"; then cp "${out%.glb}_$m.png.import" "$tmp/$m.import"; fi
    rm -f "${out%.glb}_$m.png" "${out%.glb}_$m.png.import"
done
python3 tools/rig_character.py "$tmp/welded.glb" "$out" --name "$name" --height "$height" \
    --borrow "$tmp/donor.glb:$CLIPS" --normal-map --mr-size 4096
cp "$tmp/atlas.import" "${out%.glb}_atlas.png.import"
for m in normal mr; do
    if test -f "${out%.glb}_$m.png" && test -f "$tmp/$m.import"; then cp "$tmp/$m.import" "${out%.glb}_$m.png.import"; fi
done
atlas="${out%.glb}_atlas.png"
cp "$atlas" "$tmp/tripo.png"
cp "$atlas" "$tmp/eyes.png"
if test -n "$eyes"; then
    # shellcheck disable=SC2086
    python3 tools/paint_eyeballs.py "$out" "$atlas" "$tmp/eyes.png" $eyes
fi
python3 tools/clean_under_arms.py "$out" "$tmp/eyes.png" "$tmp/clean.png"
test -f "$tmp/clean.png" || cp "$tmp/eyes.png" "$tmp/clean.png"
cp "$tmp/clean.png" "$atlas"
if test -f "${out%.glb}_normal.png" && test -f "${out%.glb}_mr.png"; then
    # shellcheck disable=SC2086
    python3 tools/maps_follow_paint.py "$out" "$tmp/tripo.png" "$atlas" "${out%.glb}_normal.png" "${out%.glb}_mr.png" $maps
fi
rm -rf "$tmp"
