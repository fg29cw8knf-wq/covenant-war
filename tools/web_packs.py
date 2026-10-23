#!/usr/bin/env python3
"""The parts of the web version that are downloaded only when they're needed.

A phone browser runs out of memory if the whole game is loaded at once, so the
web build is a small main pack (title, menus, Ashford, Thornwood) plus one pack
for each of these, fetched the first time the game needs it (scripts/game/packs.gd):

    movie     the opening movie: Gary's finished cut (assets/movies/opening.ogv)
              on its own once it exists (the paintings, voice lines and theme
              the engine falls back to without it stay out of the web build:
              with them the pack would pass GitHub's 100 MB limit); until
              then the paintings, clips, voice and theme
    duel      the duel Totems and Summons: their 3D models and Summon art
    solhaven  Solhaven: its area script and anything in a solhaven/ folder
              (scripts/world/solhaven/: the set, the films, the chase, the duels)
    looks     the player's looks B, C and D (their models and textures; their
              portraits stay in the main pack for the mirror), fetched when
              one of them is chosen in the mirror, or a game with one is continued
    midnight  the Lantern Night film (StoryFilm: assets/movies/midnight/, or the cut)
    dawn      the morning-after film (assets/movies/dawn/, or the cut)

The native apps (iPhone, Mac) keep everything in one pack.

    python3 tools/web_packs.py presets    # rewrites the pack lists in export_presets.cfg

tools/build_web.sh runs it before every export, so a new creature or movie shot
lands in the right pack without anyone editing the presets.
"""
import fnmatch
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Never in any build: source files, checks (docs/audio-checks), tests, look
# tests, and the "put the files here" notes left in asset folders.
# (the native video player's source and the 4K films it plays, fetched by
# tools/fetch_native.sh, stay out too: the export plugin ships the films loose
# in the app bundles, and the libraries in addons/native_video/bin/ go in
# through their .gdextension)
NEVER = ["docs/*", "tools/*", "tests/*", "lookdev/*", "assets/audio/source/*", "*/PUT_*_HERE.txt", "incoming/*",
	"addons/native_video/src/*", "addons/native_video/films/*"]
# The web plays the music through the page (tools/web_music.py), not the pack.
WEB_ONLY_OUT = ["assets/audio/music/*"]
# The finished opening movie, and what the engine plays shot by shot when it's
# missing (OpeningMovie): the fallback stays out of the web build once the cut
# exists. The apps keep both.
MOVIE_CUT = "assets/movies/opening.ogv"
MOVIE_FALLBACK = ["assets/art/movie/*", "assets/movies/shots/*", "assets/audio/opening_theme.ogg", "assets/audio/vo/vo_*"]

PACKS = {
	"movie": {
		"title": "the opening movie",
		"files": ["assets/movies/opening.ogv", "assets/movies/shots/*"] + MOVIE_FALLBACK,
	},
	"duel": {
		"title": "the Totems and Summons",
		"files": ["assets/models/creatures/*", "assets/models/summons/*", "assets/art/summons/*"],
		# creatures the films and the village need outside a duel stay in the main pack
		"keep": ["assets/models/creatures/lantern_moth*", "assets/models/creatures/shieldhound*"],
	},
	"solhaven": {
		"title": "Solhaven",
		"files": ["scripts/world/areas/solhaven.gd", "scripts/*/solhaven/*", "assets/*/solhaven/*", "assets/*/*/solhaven/*"],
	},
	"looks": {
		"title": "your look",
		"files": ["assets/models/characters/player_b*", "assets/models/characters/player_c*", "assets/models/characters/player_d*"],
	},
	# the story films (StoryFilm), one pack each: a film is the size of the
	# opening movie, so two in one pack would pass GitHub's limit
	"midnight": {
		"title": "the Lantern Night",
		"files": ["assets/movies/midnight.ogv", "assets/movies/midnight/*", "assets/art/movie/midnight/*", "assets/audio/vo/mid_*"],
	},
	"dawn": {
		"title": "the morning after",
		"files": ["assets/movies/dawn.ogv", "assets/movies/dawn/*", "assets/art/movie/dawn/*"],
	},
}


def project_files():
	"""Every file Godot would export, relative to the project, without .import/.uid sidecars."""
	out = []
	for d, dirs, files in os.walk(ROOT):
		rel = os.path.relpath(d, ROOT)
		dirs[:] = [x for x in dirs if not x.startswith(".") and x != "build"]
		for f in files:
			if f.endswith((".import", ".uid")) or f.startswith("."):
				continue
			p = f if rel == "." else rel + "/" + f
			out.append(p.replace(os.sep, "/"))
	return sorted(out)


def matches(path, patterns):
	return any(fnmatch.fnmatchcase(path, p) for p in patterns)


def web_only_out():
	"""What the web build leaves out altogether."""
	out = list(WEB_ONLY_OUT)
	if os.path.exists(os.path.join(ROOT, MOVIE_CUT)):
		out += MOVIE_FALLBACK
	return out


def pack_files(name):
	"""The files in a pack, each named exactly (Godot's filters have no "except")."""
	spec = PACKS[name]
	return [p for p in project_files()
		if matches(p, spec["files"]) and not matches(p, spec.get("keep", [])) and not matches(p, NEVER)
		and not matches(p, web_only_out())]


def cfg_list(items):
	return ", ".join(items)


def presets():
	path = os.path.join(ROOT, "export_presets.cfg")
	text = open(path).read()
	in_packs = [f for name in PACKS for f in pack_files(name)]

	def set_key(section_name, key, value):
		nonlocal text
		m = re.search(r'(\[preset\.(\d+)\]\n\nname="%s"\n.*?)(?=\n\[preset\.\d+\]\n|\Z)' % re.escape(section_name), text, re.S)
		assert m, "export_presets.cfg has no preset named %s" % section_name
		block = m.group(1)
		new_block, n = re.subn(r'\n%s="[^"\n]*"' % key, '\n%s="%s"' % (key, value), block)
		assert n == 1, "preset %s has no %s" % (section_name, key)
		text = text.replace(block, new_block)

	set_key("Web", "exclude_filter", cfg_list(NEVER + web_only_out() + in_packs))
	for name in PACKS:
		set_key("Web pack: " + name, "include_filter", cfg_list(pack_files(name)))
		set_key("Web pack: " + name, "exclude_filter", cfg_list(NEVER))
	for native in ("macOS", "iOS"):
		set_key(native, "exclude_filter", cfg_list(NEVER))
	if text != open(path).read():
		open(path, "w").write(text)
		print("export_presets.cfg: pack lists updated")
	for name in PACKS:
		print("%-9s %4d files" % (name, len(pack_files(name))))


if __name__ == "__main__":
	if sys.argv[1:] == ["presets"]:
		presets()
	elif len(sys.argv) == 3 and sys.argv[1] == "count":
		print(len(pack_files(sys.argv[2])))   # (build_web.sh skips a pack with nothing in it yet)
	else:
		print(__doc__)
