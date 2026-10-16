#!/bin/sh
# Builds the Mac app (Apple silicon and Intel) into build/CovenantWar-Mac.zip:
# unzip it on a Mac and open "The Covenant War". It's signed ad hoc, not by a
# paid Apple developer account, so the first time macOS asks: System Settings >
# Privacy & Security > Open Anyway (docs/mac.md). Full quality, everything in one pack.
# Works on Linux or a Mac; needs Godot 4.7.2 with the macOS export template.
set -e
GODOT=${GODOT:-godot}
. tools/build_info.sh
python3 tools/web_packs.py presets
rm -rf build/mac build/CovenantWar-Mac.zip && mkdir -p build/mac
"$GODOT" --headless --export-release "macOS" build/mac/CovenantWar.zip
mv build/mac/CovenantWar.zip build/CovenantWar-Mac.zip
echo "$BUILD_PUBLISHED" > build/CovenantWar-Mac.txt
ls -l build/CovenantWar-Mac.zip
echo "Built build/CovenantWar-Mac.zip ($BUILD_PUBLISHED)."
