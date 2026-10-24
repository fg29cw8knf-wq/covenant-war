#!/usr/bin/env python3
"""Every line the game speaks, in the order it's played, for recording.

Gary (23 October): "what if we used actual voices instead of just text?" A
recording of a line plays with it and moves it on by itself when it ends; a
line with no recording waits for a tap as before (scripts/story/voice_lines.gd).
The game finds a recording by the line's id: the first eight hex digits of the
sha1 of its words as written in the script (trimmed, one space between words,
before the player's name is filled in), under
assets/audio/vo/<area>/<speaker>/<id>.ogg (the area is ashford, thornwood or
solhaven, so the web build can carry Solhaven's apart). A line said in two
places (the midnight film and its staged version) has one id and one recording.

This reads the scripts and writes
    docs/script/vo_lines.md    the sheet to read from: by area and scene, numbered
    docs/script/vo_lines.csv   no, area, speaker, id, words, file, note
Record each line as its own file, named by its number on the sheet (0042.wav)
or its id (c5ab712b.wav); then
    python3 tools/vo_master.py --lines <folder of recordings>
levels each and puts it in place by the csv. The numbers follow the sheet of
the day they were printed from: keep the csv that goes with a set of
recordings (git has every version).

What it reads (and in what order):
    Cine.say(w, "<who>", "<words>")            a film's subtitle ("" is the narrator)
    _say(w, "<who>", "<words>" | [...])         the same, in parts
    _narrate(w, "<words>")                      narration
    {"who": "<who>", "say": "<words>"}          a conversation step (no "who": the narrator)
    _voice(w, "<file>", "<who>", [...]) and _herald_say(w, N, "<words>")
                                                lines Gary recorded already, by file name
A side story's _say splits its words at " | " into lines said one after the
other, each its own line here. The duel lessons (the lesson box: steps with
"do", "focus" or "learn") and the pack tour aren't voiced, and aren't listed.
A line whose words are built as it's said (a string followed by % or +) has
no id, and is listed with a note. {name} is the player's chosen name.

    python3 tools/vo_sheet.py            # writes the two files, prints a count
    python3 tools/vo_sheet.py --check    # only says what would change
"""
import csv
import hashlib
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_MD = "docs/script/vo_lines.md"
OUT_CSV = "docs/script/vo_lines.csv"

# in the order the game plays them
SOURCES = [
	("ashford", "scripts/world/areas/ashford_p1.gd", "Ashford: the last morning (the opening)"),
	("ashford", "scripts/world/areas/ashford.gd", "Ashford: the village, the Lantern Night, the dawn"),
	("ashford", "scripts/story/story_film.gd", "Ashford: the midnight and dawn films"),
	("thornwood", "scripts/world/areas/thornwood.gd", "Thornwood: the river, the camp, the road, the ridge"),
	("solhaven", "scripts/world/solhaven/films.gd", "Solhaven: the films"),
	("solhaven", "scripts/world/areas/solhaven.gd", "Solhaven: the Sun Square"),
	("solhaven", "scripts/world/areas/solhaven/solhaven_side.gd", "Solhaven: the side stories"),
]

# the people, as the sheet names them (an id not here is shown capitalised)
NAMES = {
	"narrator": "Narrator", "bram": "Bram", "corin": "Corin", "tilly": "Tilly", "nell": "Old Nell", "tam": "Tam",
	"ned": "Ned", "hob": "Hob", "herald": "The Pale Herald", "solmaris": "Solmaris", "dask": "Dask",
	"wren": "Wren", "pip": "Pip", "maren": "Old Maren", "tamsin": "Tamsin", "liora": "Liora", "aldric": "Ser Aldric Vane",
	"hale": "Warden Hale", "gate_warden": "The gate warden", "hierarch": "The Hierarch", "anselm": "Anselm", "ysa": "Ysa",
	"krell": "Krell", "fen": "Fen", "morne": "Morne", "morrowen": "Morrowen", "sergeant": "The sergeant",
	"captain": "The captain", "corvin": "Corvin", "horse_trader": "The horse-trader", "healer": "The healer",
	"debtor": "The debtor", "crowd": "The crowd", "children": "The children", "refugees": "The refugees",
	"refugee": "A refugee", "refugee_b": "Another refugee", "corin_mam": "Corin's mam", "board": "The notice board",
	"courtier_2": "A courtier", "courtier_3": "Another courtier", "h3": "A hunter", "h4": "Another hunter",
}

# the scene each function stages, in plain words (a function not here is shown by its name)
SCENES = {
	"opening": "Waking up", "follow": "Bram and the player, walking", "_green": "To the Lantern", "intro": "Arriving",
	"_bram": "Talking to Bram", "_tam": "Talking to Tam", "_nell": "Talking to Old Nell", "_tilly": "Talking to Tilly",
	"_ned": "Talking to Ned", "_hob": "Talking to Hob", "_corin": "Talking to Corin", "_coach_question": "Bram's offer to coach",
	"_lantern_duel": "The Lantern duel", "_the_duel": "The duel", "_after_the_duel": "After the duel",
	"_first_deck": "Bram's first deck", "_tilly_gift": "Tilly's gift", "_midnight": "Midnight", "_the_run": "The run",
	"_the_cart": "The cart", "_the_white_light": "The white light", "_dawn": "The dawn", "_taproom": "The taproom",
	"_burning": "The burning", "_river": "The river", "_camp": "The camp", "_camp_duel": "Bram's duel by the fire",
	"_camp_night": "The night at the camp", "_morning": "The second day", "_road": "The road", "_road_meeting": "Meeting Dask",
	"_oath": "The oath", "_ridge": "The ridge", "_gate": "The gate", "_gate_meeting": "At the gate", "_gate_after": "Through the gate",
	"_wagon": "The wagon", "_thief": "The thief", "_alley": "The alley", "_alley_after": "After the alley", "_court": "The Sun Court",
	"_solmaris": "Solmaris", "_trial": "The trial", "_spire": "The spire", "_climb": "The climb", "_spire_after": "After the spire",
	"_vault": "The vault", "_morne": "Morne", "_board": "The notice board",
}


def person_map():
	"""VoiceLines.PERSON: a film's stand-in speaks with the person's voice."""
	src = open(os.path.join(ROOT, "scripts/story/voice_lines.gd")).read()
	m = re.search(r"const PERSON := \{(.*?)\}", src, re.S)
	return dict(re.findall(r'"([a-z_]+)":\s*"([a-z_]+)"', m.group(1))) if m else {}


PERSON = person_map()


def unescape(s):
	return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def normalise(text):
	return re.sub(r"\s+", " ", text.strip())


def line_id(text):
	return hashlib.sha1(normalise(text).encode()).hexdigest()[:8]


def plain(text):
	"""The words without their markup, for the sheet."""
	return normalise(re.sub(r"\[/?[a-z_]+(=[^\]]*)?\]", "", text))


def tokens(src):
	"""GDScript as tokens: ("str", words, line), ("p", one of {}[](),:., line), ("w", word, line)."""
	out = []
	i, n, ln = 0, len(src), 1
	while i < n:
		c = src[i]
		if c == "\n":
			ln += 1
			i += 1
		elif c == "#":
			while i < n and src[i] != "\n":
				i += 1
		elif c in "\"'":
			q = src[i:i + 3] if src[i:i + 3] in ('"""', "'''") else c
			j = i + len(q)
			buf = []
			while j < n and src[j:j + len(q)] != q:
				if src[j] == "\\" and j + 1 < n:
					buf.append(src[j:j + 2])
					j += 2
				else:
					buf.append(src[j])
					j += 1
			out.append(("str", unescape("".join(buf)), ln))
			ln += "".join(buf).count("\n")
			i = j + len(q)
		elif c in "{}[](),:.%+":
			out.append(("p", c, ln))
			i += 1
		elif c.isalnum() or c == "_":
			j = i
			while j < n and (src[j].isalnum() or src[j] == "_"):
				j += 1
			out.append(("w", src[i:j], ln))
			i = j
		else:
			i += 1
	return out


def matches(toks):
	"""The index of the closing bracket for each opening one."""
	stack, match = [], {}
	for i, (k, v, _) in enumerate(toks):
		if k == "p" and v in "{[(":
			stack.append(i)
		elif k == "p" and v in "}])" and stack:
			match[stack.pop()] = i
	return match


def args_of(toks, match, open_i):
	"""The arguments of a call, each a slice of tokens (top-level commas split them)."""
	args, cur, depth = [], [], 0
	for i in range(open_i + 1, match[open_i]):
		k, v, _ = toks[i]
		if k == "p" and v in "{[(":
			depth += 1
		elif k == "p" and v in "}])":
			depth -= 1
		if k == "p" and v == "," and depth == 0:
			args.append(cur)
			cur = []
		else:
			cur.append(toks[i])
	if cur:
		args.append(cur)
	return args


def literal(arg):
	"""The string an argument is, or None; built words ("..." % x) count as None."""
	if len(arg) == 1 and arg[0][0] == "str":
		return arg[0][1]
	return None


def built(arg):
	return len(arg) >= 2 and arg[0][0] == "str" and arg[1] == ("p", arg[1][1], arg[1][2]) and arg[1][1] in "%+"


def alternatives(arg):
	"""The strings of a choice between lines ("won" if x else "lost"), or None."""
	if any(t == ("w", "if", t[2]) for t in arg) and any(t == ("w", "else", t[2]) for t in arg):
		strs = [t[1] for t in arg if t[0] == "str"]
		return strs if len(strs) >= 2 else None
	return None


def strings_in(arg):
	"""A list literal's strings (["a", "b"]), or the one string."""
	if literal(arg) is not None:
		return [literal(arg)]
	if arg and arg[0] == ("p", "[", arg[0][2]) and all(t[0] == "str" or t == ("p", ",", t[2]) for t in arg[1:-1]):
		return [t[1] for t in arg[1:-1] if t[0] == "str"]
	return None


def dict_pairs(toks, match, open_i):
	"""A dictionary literal's top-level "key": value pairs with a one-token value."""
	pairs, depth, i = {}, 0, open_i + 1
	end = match[open_i]
	while i < end:
		k, v, _ = toks[i]
		if k == "p" and v in "{[(":
			depth += 1
		elif k == "p" and v in "}])":
			depth -= 1
		elif depth == 0 and k == "str" and i + 2 < end and toks[i + 1] == ("p", ":", toks[i + 1][2]):
			val = toks[i + 2]
			nxt = toks[i + 3] if i + 3 < end else None
			if nxt is not None and nxt[0] == "p" and nxt[1] in "%+" and val[0] == "str":
				pairs[v] = ("built", val[1])
			elif val[0] == "str":
				pairs[v] = ("str", val[1])
			else:
				pairs[v] = ("other", val[1])
			i += 2
		i += 1
	return pairs


def lines_of(path, is_film_data):
	"""[(scene, who, words, id or "", note)] in script order."""
	toks = tokens(open(os.path.join(ROOT, path)).read())
	match = matches(toks)
	out = []
	fn = ""
	i = 0

	def add(who, words, lid=None, note=""):
		if words is None:
			return
		if "{name}" in words and "name" not in note:
			note = (note + "; " if note else "") + "{name} is the player's name"
		if "{menu}" in words:
			note = (note + "; " if note else "") + "{menu} is how the menu opens on this device"
		out.append((fn, who, words, line_id(words) if lid is None else lid, note))

	while i < len(toks):
		k, v, _ = toks[i]
		if k == "w" and v == "func" and i + 1 < len(toks):
			fn = toks[i + 1][1]
		elif k == "w" and v == "Cine" and i + 3 < len(toks) and toks[i + 1][1] == "." and toks[i + 2][1] == "say" and toks[i + 3][1] == "(":
			a = args_of(toks, match, i + 3)
			if len(a) >= 3 and literal(a[1]) is not None:
				if literal(a[2]) is not None:
					add(literal(a[1]) or "narrator", literal(a[2]))
				elif alternatives(a[2]) is not None:
					for alt in alternatives(a[2]):   # one of these, as the duel went
						add(literal(a[1]) or "narrator", alt)
				elif built(a[2]):
					add(literal(a[1]) or "narrator", a[2][0][1], "", "built as it's said: no recording")
			i = match[i + 3]
		elif k == "w" and v in ("_say", "_narrate", "_voice", "_herald_say") and i + 1 < len(toks) and toks[i + 1][1] == "(" \
				and not (i > 0 and toks[i - 1][1] == "."):
			a = args_of(toks, match, i + 1)
			if v == "_narrate" and len(a) == 2 and literal(a[1]) is not None:
				add("narrator", literal(a[1]))
			elif v == "_say" and len(a) == 3 and literal(a[1]) is not None and strings_in(a[2]) is not None:
				for part in strings_in(a[2]):
					for piece in part.split(" | "):
						add(literal(a[1]), piece)
			elif v == "_voice" and len(a) == 4 and literal(a[1]) is not None and literal(a[2]) is not None and strings_in(a[3]) is not None:
				add(literal(a[2]), " ".join(strings_in(a[3])), literal(a[1]), "recorded already: %s" % literal(a[1]))
			elif v == "_herald_say" and len(a) >= 3 and literal(a[2]) is not None and len(a[1]) == 1 and a[1][0][0] == "w" and a[1][0][1].isdigit():
				add("herald", literal(a[2]), "herald_%02d" % int(a[1][0][1]), "recorded already: herald_%02d" % int(a[1][0][1]))
			i = match[i + 1]
		elif k == "p" and v == "{" and i in match:
			d = dict_pairs(toks, match, i)
			if "say" in d:
				lesson = any(key in d for key in ("do", "focus", "learn")) or (fn == "" and not is_film_data and "at" not in d)
				if not lesson:
					who = d["who"][1] if d.get("who", ("", ""))[0] == "str" else "narrator"
					who = who or "narrator"
					vo = d["vo"][1] if d.get("vo", ("", ""))[0] == "str" else ""
					if d["say"][0] == "str":
						if vo:
							add(who, d["say"][1], vo, "recorded already: %s" % vo)
						else:
							add(who, d["say"][1])
					elif d["say"][0] == "built":
						add(who, d["say"][1], "", "built as it's said: no recording")
		i += 1
	return out


def speaker_of(who):
	return PERSON.get(who, who)


def name_of(speaker):
	return NAMES.get(speaker, speaker.replace("_", " ").capitalize())


def scene_of(fn):
	return SCENES.get(fn, fn.strip("_").replace("_", " ").capitalize() if fn else "")


def gather():
	rows, seen = [], {}
	for area, path, what in SOURCES:
		for fn, who, words, lid, note in lines_of(path, path.endswith("story_film.gd")):
			speaker = speaker_of(who)
			key = (speaker, lid or words)
			if key in seen:
				seen[key]["places"] += 1
				continue
			row = {"area": area, "where": what, "scene": scene_of(fn), "speaker": speaker, "id": lid, "words": words,
				"note": note, "places": 1, "file": ""}
			if lid and "recorded already" not in note:
				row["file"] = "assets/audio/vo/%s/%s/%s.ogg" % (area, speaker, lid)
			elif lid:
				row["file"] = "assets/audio/vo/%s.ogg" % lid
			# "recorded already" only when the recording is really there: a
			# line named by its file (the Herald's, Solmaris's, Morne's) may
			# not be made yet
			if row["file"]:
				there = any(os.path.exists(os.path.join(ROOT, os.path.splitext(row["file"])[0] + "." + e)) for e in ("ogg", "mp3", "wav"))
				named = note.split("recorded already: ", 1)[1].split(";")[0] if "recorded already: " in note else ""
				if named and not there:
					row["note"] = note.replace("recorded already: " + named, "to record, as %s.wav" % named)
				elif there and not named:
					row["note"] = (note + "; " if note else "") + "recorded already"
			seen[key] = row
			rows.append(row)
	for n, r in enumerate(rows, 1):
		r["no"] = "%04d" % n
	return rows


def stamp():
	try:
		return subprocess.run(["git", "log", "-1", "--format=%ad (%h)", "--date=short"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
	except OSError:
		return ""


def write_md(rows):
	o = io.StringIO()
	o.write("# The lines, for recording\n\n")
	o.write("Every line the game speaks, in the order it's played: %d lines, %d of them recorded already. "
		"A line marked \"to record, as <name>.wav\" is looked for by that name. Written by `tools/vo_sheet.py` from the scripts as of %s; "
		"run it again after the words change.\n\n" % (len(rows), sum(1 for r in rows if "recorded already" in r["note"]), stamp()))
	o.write("**How to record.** One file a line, named by its number here (`0042.wav`) or its id (`c5ab712b.wav`): any "
		"format. Then `python3 tools/vo_master.py --lines <folder>` levels them and puts each in its place "
		"(`assets/audio/vo/<area>/<speaker>/<id>.ogg`). A line with a recording plays it and moves on by itself when it "
		"ends; a tap skips it. A line without one waits for a tap, as now. Narrator lines are the words in italics on "
		"screen with nobody speaking. `{name}` is whatever the player called themselves: say \"you\", or leave that "
		"line out. Who to voice is Gary's call: everyone, or the cutscenes first (the films' lines are marked by scene).\n\n")
	last_where = last_scene = None
	for r in rows:
		if r["where"] != last_where:
			o.write("\n## %s\n" % r["where"])
			last_where, last_scene = r["where"], None
		if r["scene"] != last_scene:
			o.write("\n### %s\n\n" % (r["scene"] or "Lines"))
			o.write("| No. | Who | Line | Id |\n|---|---|---|---|\n")
			last_scene = r["scene"]
		words = plain(r["words"]).replace("|", "\\|")
		note = ""
		if r["note"]:
			note = " *(%s)*" % r["note"]
		if r["places"] > 1:
			note += " *(said in %d places: one recording)*" % r["places"]
		o.write("| %s | %s | %s%s | `%s` |\n" % (r["no"], name_of(r["speaker"]), words, note, r["id"] or "—"))
	return o.getvalue()


def write_csv(rows):
	o = io.StringIO()
	w = csv.writer(o, lineterminator="\n")
	w.writerow(["no", "area", "speaker", "id", "words", "file", "scene", "note"])
	for r in rows:
		w.writerow([r["no"], r["area"], r["speaker"], r["id"], normalise(r["words"]), r["file"], r["scene"], r["note"]])
	return o.getvalue()


def main():
	rows = gather()
	md, cs = write_md(rows), write_csv(rows)
	changed = []
	for path, text in ((OUT_MD, md), (OUT_CSV, cs)):
		full = os.path.join(ROOT, path)
		old = open(full).read() if os.path.exists(full) else None
		if old != text:
			changed.append(path)
			if "--check" not in sys.argv:
				open(full, "w").write(text)
	by_area = {}
	for r in rows:
		by_area[r["area"]] = by_area.get(r["area"], 0) + 1
	speakers = sorted({r["speaker"] for r in rows})
	print("%d lines (%s); %d recorded already; %d speakers: %s" % (
		len(rows), ", ".join("%s %d" % kv for kv in by_area.items()),
		sum(1 for r in rows if "recorded already" in r["note"]), len(speakers), " ".join(speakers)))
	unknown = sorted(s for s in speakers if s not in NAMES)
	if unknown:
		print("speakers with no name in NAMES (shown by their id):", " ".join(unknown))
	if changed:
		print(("would change: " if "--check" in sys.argv else "written: ") + ", ".join(changed))
	return 1 if ("--check" in sys.argv and changed) else 0


if __name__ == "__main__":
	sys.exit(main())
