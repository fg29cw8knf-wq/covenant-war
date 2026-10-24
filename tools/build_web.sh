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
# The page fills a phone's screen edge to edge (viewport-fit=cover, below, and
# the head lines and full-screen Home Screen app in export_presets.cfg).
set -e
GODOT=${GODOT:-godot}
. tools/build_info.sh
python3 tools/web_packs.py presets
rm -rf build/web && mkdir -p build/web/packs
# The opening film streams in 4K through the browser's own player on the web
# (films/opening on the site), so its Theora copy in the movie pack is only a
# fallback for a browser that can't: a 480p copy goes into the web's pack
# instead of the 720p one the apps keep, which keeps the site (streams and
# all) inside GitHub Pages' 1 GB. The 720p file is put back however the build
# ends. KEEP_MOVIE=1 builds with the 720p copy.
MOVIE=assets/movies/opening.ogv
if [ -f "$MOVIE" ] && [ -z "$KEEP_MOVIE" ]; then
	SMALL=build/opening_480.ogv
	if [ ! -f "$SMALL" ] || [ "$MOVIE" -nt "$SMALL" ]; then
		ffmpeg -hide_banner -loglevel error -y -i "$MOVIE" -vf scale=854:480:flags=lanczos \
			-c:v libtheora -q:v 5 -c:a libvorbis -q:a 3 "$SMALL"
		touch -r "$MOVIE" "$SMALL"
	fi
	cp -p "$MOVIE" build/opening_full.ogv
	trap 'cp -p build/opening_full.ogv "$MOVIE"' EXIT
	cp -p "$SMALL" "$MOVIE"
	echo "opening.ogv: the 480p copy for the web pack ($(du -m "$SMALL" | cut -f1) MB)"
fi
SIZES=""
for pack in $(python3 tools/web_packs.py names); do
	# a story film pack with no clips in it yet isn't built (an empty include
	# list would export the whole game), and the game plays the 3D scene
	if [ "$(python3 tools/web_packs.py count "$pack")" = "0" ]; then
		echo "packs/$pack.pck: nothing to pack yet"
		continue
	fi
	"$GODOT" --headless --export-pack "Web pack: $pack" "build/web/packs/$pack.pck"
	size=$(wc -c < "build/web/packs/$pack.pck")
	# GitHub Pages refuses files over 100 MB: split the pack in tools/web_packs.py if it grows that big
	test "$size" -lt 95000000 || { echo "packs/$pack.pck is $size bytes, over GitHub's limit"; exit 1; }
	SIZES="$SIZES\"$pack\": $size, "
done
printf '\n[packs]\n\nsizes={%s}\n' "${SIZES%, }" >> build_info.cfg
"$GODOT" --headless --export-release "Web" build/web/index.html
# Edge to edge on a phone: viewport-fit=cover lets the page (and the game) run
# under the iPhone's Dynamic Island and home bar instead of Safari leaving bars
# beside them; the game keeps its buttons clear of them itself (SafeArea, which
# reads the page's env(safe-area-inset-*)). Godot's own page doesn't say it.
python3 - build/web/index.html <<'EOF'
import re, sys
path = sys.argv[1]
page = open(path).read()
m = re.search(r'<meta name="viewport" content="([^"]*)">', page)
assert m, "index.html has no viewport line to add viewport-fit=cover to"
if "viewport-fit" not in m.group(1):
	page = page.replace(m.group(0), '<meta name="viewport" content="%s, viewport-fit=cover">' % m.group(1), 1)
	open(path, "w").write(page)
EOF
if [ "$1" = "--lab" ]; then
	sed -i.bak 's/"args":\[\]/"args":["--","--lab"]/' build/web/index.html && rm -f build/web/index.html.bak
fi
# GitHub Pages refuses files over 100 MB: split a big pack and let the page stitch it
python3 tools/split_pack.py build/web
python3 tools/web_music.py build/web
# Gary's 4K films through the browser's own video player (scripts/ui/film_web.js,
# driven by scripts/story/web_video_player.gd): the player goes into the page,
# hls.js (for browsers without their own HLS) beside it. The streams themselves
# (films/<name>/, made by tools/make_hls.sh) live only on the gh-pages branch,
# too big to rebuild every time: tools/publish_web.sh keeps them there.
python3 - build/web/index.html scripts/ui/film_web.js <<'PYEOF'
import sys
page_path, js_path = sys.argv[1], sys.argv[2]
page, js = open(page_path).read(), open(js_path).read()
assert "</script" not in js.lower(), "film_web.js can't contain </script> (it goes inline)"
if "window.CWFilm" not in page:
	page = page.replace("</head>", "<script>\n%s</script>\n</head>" % js, 1)
	open(page_path, "w").write(page)
PYEOF
cp tools/web/hls.light.min.js tools/web/hls.js.LICENSE build/web/
touch build/web/.nojekyll
ls -l build/web/index.pck* build/web/packs
echo "Built build/web ($BUILD_PUBLISHED) - tools/publish_web.sh puts it on the gh-pages branch (keeping the film streams there)."
