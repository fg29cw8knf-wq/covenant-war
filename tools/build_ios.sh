#!/bin/sh
# Builds the iPhone/iPad app as an Xcode project, zipped into
# build/CovenantWar-iOS.zip: unzip it on a Mac, open CovenantWar.xcodeproj,
# pick your Apple ID as the team and press Run (the steps are in docs/iphone.md).
# Works on Linux or a Mac; needs Godot 4.7.2 with the iOS export templates.
# Everything is in one pack at full quality (the Forward+ renderer, as on the Mac).
set -e
GODOT=${GODOT:-godot}
. tools/build_info.sh
python3 tools/web_packs.py presets
rm -rf build/ios build/CovenantWar-iOS.zip && mkdir -p build/ios
"$GODOT" --headless --export-release "iOS" build/ios/CovenantWar.ipa
test -d build/ios/CovenantWar.xcodeproj
# Godot needs a team ID (CHOOSETEAM in export_presets.cfg); it is blanked here so
# Xcode asks for one: your Apple ID's Personal Team.
python3 tools/ios_tidy.py build/ios
(cd build && mv ios CovenantWar && zip -qr -y CovenantWar-iOS.zip CovenantWar && mv CovenantWar ios)
echo "$BUILD_PUBLISHED" > build/CovenantWar-iOS.txt
ls -l build/CovenantWar-iOS.zip
echo "Built build/CovenantWar-iOS.zip ($BUILD_PUBLISHED)."
