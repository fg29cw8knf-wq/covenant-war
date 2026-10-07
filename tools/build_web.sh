#!/bin/sh
# Builds the phone/web version into build/web. It opens on the title screen:
# New Game starts the Prologue in Ashford, and the Duel Lab has its own button.
# Pass --lab to open straight into the Duel Lab instead,
# ready to publish on the gh-pages branch (https://fg29cw8knf-wq.github.io/covenant-war/).
# Needs Godot 4.7.2 with the web (no threads) export templates installed.
set -e
GODOT=${GODOT:-godot}
rm -rf build/web && mkdir -p build/web
"$GODOT" --headless --export-release "Web" build/web/index.html
if [ "$1" = "--lab" ]; then
	sed -i.bak 's/"args":\[\]/"args":["--","--lab"]/' build/web/index.html && rm -f build/web/index.html.bak
fi
touch build/web/.nojekyll
echo "Built build/web - push its contents to the gh-pages branch to publish."
