#!/bin/sh
# Fetches what the iPhone and Mac apps need to play Gary's films at full size,
# none of it kept in git: the native video player's libraries (the
# "native-video" release, built by .github/workflows/native-video.yml) into
# addons/native_video/bin/, with the .gdextension that names them, and the 4K
# films themselves (every .mp4 on the "films" release, put there by
# .github/workflows/films.yml) into addons/native_video/films/, where the
# export plugin (addons/native_video/films_export.gd) ships them loose in the
# app bundles. The iPhone and Mac app workflows run it before the import and
# the export. Each download is checked against the .sha256 beside it on the
# release, and one already here with the right sum isn't fetched again.
#
# Nothing here fails a build: without a release (or offline) the apps simply
# play the Theora copy in the pack, as the phone link does, and the build goes
# on; what was and wasn't fetched is printed.
#
#   tools/fetch_native.sh            # the player and the films
#   tools/fetch_native.sh player     # the libraries alone
#   tools/fetch_native.sh films      # the films alone
#
# In GitHub Actions GH_TOKEN is set and gh does the downloading; anywhere else
# curl fetches from the public release addresses.
set -e
cd "$(dirname "$0")/.."
REPO=${GITHUB_REPOSITORY:-fg29cw8knf-wq/covenant-war}
BASE="https://github.com/$REPO/releases/download"
ADDON=addons/native_video
what=${1:-all}

# fetch <release tag> <asset> <destination file>: 0 if it's there afterwards
fetch() {
	rm -f "$3"
	if [ -n "$GH_TOKEN" ] && command -v gh >/dev/null 2>&1; then
		gh release download "$1" --repo "$REPO" --pattern "$2" --output "$3" 2>/dev/null && return 0
	fi
	curl -fsSL --retry 3 --retry-delay 5 -o "$3" "$BASE/$1/$2" 2>/dev/null && return 0
	rm -f "$3"
	return 1
}

# sum_ok <file> <sha256 file (one line: sum name)>: the file has that sum
sum_ok() {
	test -f "$1" && test -f "$2" || return 1
	want=$(awk '{print $1}' "$2")
	if command -v sha256sum >/dev/null 2>&1; then
		have=$(sha256sum "$1" | awk '{print $1}')
	else
		have=$(shasum -a 256 "$1" | awk '{print $1}')
	fi
	test "$have" = "$want"
}

# the names of the .mp4 files on the films release: gh when it can (a token
# that doesn't work, as here outside Actions, gives nothing), else the public API
film_names() {
	names=""
	if [ -n "$GH_TOKEN" ] && command -v gh >/dev/null 2>&1; then
		names=$(gh release view films --repo "$REPO" --json assets --jq '.assets[].name' 2>/dev/null | grep '\.mp4$' || true)
	fi
	if [ -z "$names" ]; then
		names=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/tags/films" 2>/dev/null \
			| python3 -c 'import json,sys
try:
    for a in json.load(sys.stdin).get("assets", []):
        if a["name"].endswith(".mp4"):
            print(a["name"])
except Exception:
    pass' || true)
	fi
	echo "$names"
}

if [ "$what" = "all" ] || [ "$what" = "player" ]; then
	mkdir -p "$ADDON/bin"
	if fetch native-video native-video.zip.sha256 "$ADDON/bin/native-video.zip.sha256" \
		&& fetch native-video native-video.zip "$ADDON/bin/native-video.zip" \
		&& sum_ok "$ADDON/bin/native-video.zip" "$ADDON/bin/native-video.zip.sha256"; then
		rm -rf "$ADDON/bin/libnativevideo.macos.template_release.framework" "$ADDON/bin/libnativevideo.ios.template_release.xcframework"
		(cd "$ADDON/bin" && unzip -q -o native-video.zip && rm -f native-video.zip native-video.zip.sha256)
		cp "$ADDON/native_video.gdextension.in" "$ADDON/bin/native_video.gdextension"
		echo "fetch_native: the native video player is in $ADDON/bin/ (iPhone and Mac libraries)"
	else
		rm -f "$ADDON/bin/native-video.zip" "$ADDON/bin/native-video.zip.sha256" "$ADDON/bin/native_video.gdextension"
		echo "fetch_native: no native-video release to fetch; the apps will play the Theora copies"
	fi
fi

if [ "$what" = "all" ] || [ "$what" = "films" ]; then
	mkdir -p "$ADDON/films"
	got=0
	for name in $(film_names); do
		if fetch films "$name.sha256" "$ADDON/films/$name.sha256" && sum_ok "$ADDON/films/$name" "$ADDON/films/$name.sha256"; then
			echo "fetch_native: $name is already here"
			got=$((got + 1))
			continue
		fi
		if fetch films "$name" "$ADDON/films/$name" && { [ ! -f "$ADDON/films/$name.sha256" ] || sum_ok "$ADDON/films/$name" "$ADDON/films/$name.sha256"; }; then
			echo "fetch_native: $name fetched ($(du -m "$ADDON/films/$name" | cut -f1) MB)"
			got=$((got + 1))
		else
			rm -f "$ADDON/films/$name"
			echo "fetch_native: $name couldn't be fetched whole; the apps will play its Theora copy"
		fi
	done
	test "$got" -gt 0 || echo "fetch_native: no films on the films release yet; the apps will play the Theora copies"
fi
