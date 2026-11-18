#!/bin/sh
# Bakes the inn's rooms (18 November, BakedLight): readies them
# (bake_rooms.tscn), then presses Bake in the editor on each state's scene
# (autobake), the light written to assets/bake/<room>/<state>.lmbake.
#   tools/bake/bake_rooms.sh [attic] [eve] [shards]    (FORCE=1 bakes again what's done)
# (shards: the Shardlands at the start of the game, tools/bake/bake_shards.gd)
# The editor ignores override.cfg, so autobake is switched on in
# project.godot for the run (with the textures squeezed on the processor,
# not the slow software GPU), and project.godot and any import settings
# the editor changed on the way are put back afterwards.
set -e
cd "$(dirname "$0")/../.."
export VK_ICD_FILENAMES=${VK_ICD_FILENAMES:-/usr/share/vulkan/icd.d/lvp_icd.json}
rooms=$(echo " $* " | sed 's/ shards / /g')
if [ $# -eq 0 ] || [ -n "$(echo $rooms)" ]; then
	godot --headless res://tools/bake/bake_rooms.tscn -- $rooms | grep "BAKE ROOMS"
fi
if [ $# -eq 0 ] || echo " $* " | grep -q " shards "; then
	godot --headless res://tools/bake/bake_shards.tscn | grep "BAKE SHARDS"
fi
cp project.godot /tmp/bake_project.godot
git diff --name-only -- '*.import' | sort > /tmp/bake_imports_before
restore() {
	cp /tmp/bake_project.godot project.godot
	git diff --name-only -- '*.import' | sort | comm -13 /tmp/bake_imports_before - | xargs -r git checkout --
}
trap restore EXIT
sed -i 's#^enabled=PackedStringArray(\(.*\))$#enabled=PackedStringArray(\1, "res://tools/bake/autobake/plugin.cfg")#' project.godot
sed -i 's#^\[rendering\]$#[rendering]\n\ntextures/vram_compression/compress_with_gpu=false#' project.godot
grep -q autobake project.godot
# everything imported first: the editor busy importing when Bake is pressed
# can't take the bake's own light picture ("reimport_files() recursively")
godot --headless --import --path . > /tmp/bake_import.log 2>&1 || true
for scene in tools/bake/scenes/*.tscn; do
	name=$(basename "$scene" .tscn)
	room=${name%%_*}
	state=${name#*_}
	if [ $# -gt 0 ] && ! echo " $* " | grep -q " $room "; then continue; fi
	if [ -f "assets/bake/$room/$state.lmbake" ] && [ -z "$FORCE" ]; then echo "already baked $room $state (FORCE=1 to bake again)"; continue; fi
	echo "baking $room $state"
	BAKE_SCENE="res://$scene" BAKE_OUT="res://assets/bake/$room/$state.lmbake" BAKE_WAIT=${BAKE_WAIT:-3600} \
		xvfb-run -a -s "-screen 0 1600x900x24" godot --editor --path . --rendering-driver vulkan > "/tmp/bake_${room}_$state.log" 2>&1 || true
	grep -E "AUTOBAKE|Done baking" "/tmp/bake_${room}_$state.log" || true
done
