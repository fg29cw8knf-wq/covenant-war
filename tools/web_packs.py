#!/usr/bin/env python3
"""The parts of the web version that are downloaded only when they're needed.

A phone browser runs out of memory if the whole game is loaded at once, so the
web build is a small main pack (title, menus, Ashford, Thornwood) plus one pack
for each of these, fetched the first time the game needs it (scripts/game/packs.gd):

    movie     the opening movie: its paintings, clips, voice and theme
    duel      the duel Totems and Summons: their 3D models and Summon art
    solhaven  Solhaven: its area script and anything in a solhaven/ folder

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
NEVER = ["docs/*", "tools/*", "tests/*", "lookdev/*", "assets/audio/source/*", "*/PUT_*_HERE.txt"]
# The web plays the music through the page (tools/web_music.py), not the pack.
WEB_ONLY_OUT = ["assets/audio/music/*"]

PACKS = {
	"movie": {
		"title": "the opening movie",
		"files": ["assets/art/movie/*", "assets/movies/*", "assets/audio/opening_theme.ogg", "assets/audio/vo/vo_*"],
	},
	"duel": {
		"title": "the Totems and Summons",
		"files": ["assets/models/creatures/*", "assets/models/summons/*", "assets/art/summons/*"],
		# creatures the films and the village need outside a duel stay in the main pack
		"keep": ["assets/models/creatures/lantern_moth*", "assets/models/creatures/shieldhound*"],
	},
	"solhaven": {
		"title": "Solhaven",
		"files": ["scripts/world/areas/solhaven.gd", "assets/*/solhaven/*", "assets/*/*/solhaven/*"],
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


def pack_files(name):
	"""The files in a pack, each named exactly (Godot's filters have no "except")."""
	spec = PACKS[name]
	return [p for p in project_files()
		if matches(p, spec["files"]) and not matches(p, spec.get("keep", [])) and not matches(p, NEVER)]


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

	set_key("Web", "exclude_filter", cfg_list(NEVER + WEB_ONLY_OUT + in_packs))
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
	else:
		print(__doc__)
