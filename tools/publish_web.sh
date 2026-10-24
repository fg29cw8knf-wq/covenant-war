#!/bin/sh
# Publishes build/web (tools/build_web.sh) as the phone link: a new commit on
# the gh-pages branch, on top of the last one, that holds build/web's files and
# keeps the film streams already there (films/<name>/, tools/make_hls.sh),
# which are far too big to rebuild or download for every publish.
#
#   tools/publish_web.sh "Phone build: what changed"
#   tools/publish_web.sh "Phone build: the opening in 4K" --film opening build/films/opening
#
# --film <name> <dir> adds (or replaces) films/<name>/ with that folder's
# streams. Nothing is checked out: the commit is made straight from the index
# (git read-tree), and gh-pages is fetched without its file contents
# (--filter=blob:none), so publishing never downloads the films. GitHub Pages
# serves a site up to 1 GB: the script stops if the new tree is over 980 MB.
set -e
MSG=${1:?"usage: tools/publish_web.sh <message> [--film <name> <dir>]..."}
shift
[ -f build/web/index.html ] || { echo "build/web isn't built: run tools/build_web.sh first"; exit 1; }
git fetch --depth 1 --filter=blob:none origin gh-pages
PARENT=$(git rev-parse FETCH_HEAD)
IDX=$(mktemp)
rm -f "$IDX"
export GIT_INDEX_FILE="$IDX"
git read-tree --empty
git --work-tree=build/web add -A -f .
# the films already published, as they are
if git cat-file -e "$PARENT:films" 2>/dev/null; then
	git read-tree --prefix=films/ "$PARENT:films" 2>/dev/null || {
		# read-tree --prefix refuses to overlay: films/ isn't in build/web, so
		# this only happens if build/web grew a films folder of its own
		echo "build/web has its own films/ folder: remove it"; exit 1; }
fi
while [ $# -gt 0 ]; do
	[ "$1" = "--film" ] || { echo "unknown option $1"; exit 1; }
	name=$2; dir=$3; shift 3
	[ -f "$dir/master.m3u8" ] || { echo "$dir has no master.m3u8"; exit 1; }
	git rm -r -q --cached --ignore-unmatch "films/$name" >/dev/null
	tmp=$(mktemp -d)
	mkdir -p "$tmp/films"
	ln -s "$(cd "$dir" && pwd)" "$tmp/films/$name"
	# (a symlinked folder is added as a link, so copy instead)
	rm "$tmp/films/$name"
	cp -r "$dir" "$tmp/films/$name"
	git --work-tree="$tmp" add -f "films/$name"
	rm -rf "$tmp"
done
TREE=$(git write-tree)
# the published size, summed from the index's own record of each file
SIZE=$(git ls-files -s | awk '{print $2}' | git cat-file --batch-check='%(objectsize)' 2>/dev/null | awk '{s+=$1} END {print s+0}')
echo "gh-pages: $(git ls-files | wc -l) files, $((SIZE / 1000000)) MB"
[ "$SIZE" -lt 980000000 ] || { echo "Over GitHub Pages' 1 GB: not published"; exit 1; }
COMMIT=$(git commit-tree "$TREE" -p "$PARENT" -m "$MSG")
unset GIT_INDEX_FILE
rm -f "$IDX"
git push origin "$COMMIT:refs/heads/gh-pages"
echo "Published $COMMIT to gh-pages: https://fg29cw8knf-wq.github.io/covenant-war/"
