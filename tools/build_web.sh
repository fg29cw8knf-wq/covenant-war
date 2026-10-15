#!/bin/sh
# Builds the phone/web version into build/web. It opens on the title screen:
# New Game starts the Prologue in Ashford, and the Duel Lab has its own button.
# Pass --lab to open straight into the Duel Lab instead,
# ready to publish on the gh-pages branch (https://fg29cw8knf-wq.github.io/covenant-war/).
# Needs Godot 4.7.2 with the web (no threads) export templates installed,
# Python 3 for tools/split_pack.py, and Python 3 with numpy and ffmpeg for tools/web_music.py.
#
# A phone browser can't hold the whole game at once, so it's built in parts
# (tools/web_packs.py): a main pack, and build/web/packs/<name>.pck for the
# opening movie, the duel Totems and Summons, and Solhaven, each fetched the
# first time the game needs it (scripts/game/packs.gd).
# The music isn't in the web pack: tools/web_music.py makes an MP3 of each
# track in build/web/music/ and puts the page's own music player (which loops
# them seamlessly, see scripts/ui/music_web.js) into index.html.
set -e
GODOT=${GODOT:-godot}
. tools/build_info.sh
python3 tools/web_packs.py presets
rm -rf build/web && mkdir -p build/web/packs
SIZES=""
for pack in movie duel solhaven; do
	"$GODOT" --headless --export-pack "Web pack: $pack" "build/web/packs/$pack.pck"
	size=$(wc -c < "build/web/packs/$pack.pck")
	# GitHub Pages refuses files over 100 MB: split the pack in tools/web_packs.py if it grows that big
	test "$size" -lt 95000000 || { echo "packs/$pack.pck is $size bytes, over GitHub's limit"; exit 1; }
	SIZES="$SIZES\"$pack\": $size, "
done
printf '\n[packs]\n\nsizes={%s}\n' "${SIZES%, }" >> build_info.cfg
"$GODOT" --headless --export-release "Web" build/web/index.html
if [ "$1" = "--lab" ]; then
	sed -i.bak 's/"args":\[\]/"args":["--","--lab"]/' build/web/index.html && rm -f build/web/index.html.bak
fi
# GitHub Pages refuses files over 100 MB: split a big pack and let the page stitch it
python3 tools/split_pack.py build/web
python3 tools/web_music.py build/web
touch build/web/.nojekyll
ls -l build/web/index.pck* build/web/packs
echo "Built build/web ($BUILD_PUBLISHED) - push its contents to the gh-pages branch to publish."
