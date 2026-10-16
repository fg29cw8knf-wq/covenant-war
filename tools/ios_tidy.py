#!/usr/bin/env python3
"""Readies Godot's exported Xcode project for a free Apple ID. Run by tools/build_ios.sh.

- Blanks the placeholder team (CHOOSETEAM), so Xcode asks for one: the
  person's own Personal Team.
- Signs the Release build (the one Run uses) with "Apple Development" like
  Debug, not "Apple Distribution", which a free Apple ID doesn't have. With the
  two the same, Xcode shows one Signing section and the team is chosen once.
- Drops the iOS Simulator copies of the engine (a real iPhone never uses them),
  which halves the download.

    python3 tools/ios_tidy.py build/ios
"""
import glob
import os
import plistlib
import shutil
import sys

out = sys.argv[1]
for path in [os.path.join(out, "CovenantWar.xcodeproj", "project.pbxproj"), os.path.join(out, "CovenantWar", "export_options.plist")]:
	t = open(path).read()
	t = t.replace("= CHOOSETEAM;", '= "";').replace("<string>CHOOSETEAM</string>", "<string></string>")
	t = t.replace('CODE_SIGN_IDENTITY = "Apple Distribution";', 'CODE_SIGN_IDENTITY = "Apple Development";')
	assert "CHOOSETEAM" not in t, path
	open(path, "w").write(t)

for fw in glob.glob(os.path.join(out, "*.xcframework")):
	info_path = os.path.join(fw, "Info.plist")
	with open(info_path, "rb") as f:
		info = plistlib.load(f)
	keep = []
	for lib in info["AvailableLibraries"]:
		if lib.get("SupportedPlatformVariant") == "simulator":
			shutil.rmtree(os.path.join(fw, lib["LibraryIdentifier"]), ignore_errors=True)
		else:
			keep.append(lib)
	info["AvailableLibraries"] = keep
	with open(info_path, "wb") as f:
		plistlib.dump(info, f)
print("Xcode project tidied: no team set, device-only engine")
