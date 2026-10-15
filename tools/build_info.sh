#!/bin/sh
# Writes build_info.cfg (read by scripts/game/packs.gd): when this build was
# made, shown as the "Early build" on the title screen and the pause menu, in
# UK time. Sourced by tools/build_web.sh and tools/build_ios.sh, which delete
# the file again when they finish. Extra lines can be appended after it.
BUILD_PUBLISHED=$(TZ=Europe/London date '+%-d %b %Y, %H:%M %Z')
BUILD_ID=$(date -u '+%Y%m%d%H%M%S')
printf '[build]\n\npublished="%s"\nid="%s"\n' "$BUILD_PUBLISHED" "$BUILD_ID" > build_info.cfg
trap 'rm -f build_info.cfg' EXIT
