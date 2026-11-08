#!/usr/bin/env python3
"""Build Gary's Card Prompt Kit page from the game's own files.

    python3 tools/prompt_kit.py [out.html]      (default: build/prompt_kit.html)

Reads:
  docs/card-prompts.md         every prompt, round by round (the source of truth)
  docs/prompt-kit-extra.json   the few kit cards whose prompts live nowhere else
                               (River Hound, Ser Aldric's three, the condition Rites)
  scripts/duel/duel_cards.gd   each card's tier, stage and what it ascends from
  the repo's file list         what's already in the game (works in a sparse clone)
  tools/prompt_kit.html        the page template

Whenever a round is added to docs/card-prompts.md, run this and republish the
page to the Card Prompt Kit artifact (slug 0bcd5063-2337-4b92-9c71-625a00c4a325),
so Gary can find the new prompts there. The .md alone isn't what he reads.
"""
import datetime
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TIER_NAMES = ["", "Spark", "Glimmer", "Crystal", "Relic", "Legend", "Demigod", "Divine"]
ELEMENTS = {"fire", "storm", "tide", "verdant", "earth", "metal", "psychic", "venom", "spirit",
            "mystic", "frost", "wind", "radiant", "astral", "umbral", "any"}
MODEL_NOTE = ("No prompt to paste: in Tripo3D, choose image to 3D and give it the cut-out (or the card "
              "painting if the cut-out isn't made yet). Rig it with idle, spawn, attack, hit, defeat, "
              "victory and run; 20,000 to 30,000 triangles and a 4K texture. Any file name is fine.")


def rel(p):
    return os.path.join(ROOT, p)


def repo_files():
    """Every tracked path, without fetching any blob (safe in the blob-filtered clone)."""
    try:
        out = subprocess.run(["git", "-C", ROOT, "ls-files"], capture_output=True, text=True,
                             check=True, env=dict(os.environ, GIT_NO_LAZY_FETCH="1")).stdout
        return set(out.split("\n"))
    except Exception:
        found = set()
        for d, _, fs in os.walk(rel("assets")):
            for f in fs:
                found.add(os.path.relpath(os.path.join(d, f), ROOT))
        return found


def game_cards():
    src = open(rel("scripts/duel/duel_cards.gd"), encoding="utf-8").read()
    cards = {}
    for m in re.finditer(r'^\t"(\w+)": \{\s*"kind": "(\w+)", "name": "([^"]+)", "element": "(\w+)", "tier": (\d+)'
                         r'(?:, "stage": (\d+))?(?=(.{0,200}))', src, re.M | re.S):
        cid, kind, name, el, tier, stage, tail = m.groups()
        asc = re.search(r'"ascends_from": "(\w+)"', tail)
        cards[cid] = {"kind": kind, "name": name, "el": el, "tier": int(tier),
                      "stage": int(stage or 0), "from": asc.group(1) if asc else ""}
    return cards


def has_file(files, path):
    """path like 'cards/x.png' or 'models/creatures/x.glb': in the game under any image extension."""
    if path.startswith(("models/", "audio/")):
        base = "assets/" + path
    else:
        base = "assets/art/" + path
    stem = os.path.splitext(base)[0]
    if path.startswith("audio/"):
        return any(stem + ext in files for ext in (".ogg", ".mp3", ".wav"))
    if path.startswith("models/"):
        return stem + ".glb" in files
    return any(stem + ext in files for ext in (".png", ".webp", ".jpg", ".jpeg"))


PART = [("Card painting", "painting"), ("God painting", "god"), ("Battlefield cut-out", "cutout"),
        ("Summon cut-out", "cutout"), ("Summon sky scene", "scene"), ("3D model", "model"),
        ("Summon stinger", "music"), ("Music", "music")]


def part_of(label):
    for prefix, part in PART:
        if label.startswith(prefix):
            return part
    return "painting"


def parse_doc():
    lines = open(rel("docs/card-prompts.md"), encoding="utf-8").read().split("\n")
    groups, entries = {}, []
    round_titles, round_intro = {}, {}
    cur, i = None, 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r"^# Round (\d+): (.+)$", ln)
        if m:
            n = int(m.group(1))
            round_titles[n] = "Round %d: %s" % (n, re.sub(r"\s*\(.*\)\s*$", "", m.group(2)))
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines) and not lines[j].startswith("#"):
                round_intro[n] = lines[j].strip()
            i += 1
            continue
        m = re.match(r"^## (.+?) \((round (\d+)[^)]*)\)\s*$", ln)
        if m:
            bits = [b.strip() for b in m.group(2).split(",")]
            kind = bits[1] if len(bits) > 1 else "rite"
            if kind.startswith("god"):
                kind = "god"
            el = bits[2] if len(bits) > 2 and bits[2] in ELEMENTS else "any"
            if kind == "music":
                el = "any"
            cur = {"name": m.group(1), "round": int(m.group(3)), "kind": kind, "el": el,
                   "extra": [b for b in bits[3:]], "blocks": []}
            entries.append(cur)
            i += 1
            continue
        m = re.match(r"^\*\*(.+?)\*\*\s*(?:\((.*)\))?\s*$", ln)
        if m and cur is not None and " · " in m.group(1):
            parts = [p.strip() for p in m.group(1).split(" · ")]
            label = parts[0]
            file = ""
            if parts[-1].startswith("save as "):
                file = parts[-1][len("save as "):]
                parts = parts[:-1]
            size = " · ".join(parts[1:])
            note = (m.group(2) or "").strip()
            text = ""
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines) and lines[j].startswith("```"):
                k = j + 1
                body = []
                while k < len(lines) and not lines[k].startswith("```"):
                    body.append(lines[k])
                    k += 1
                text = "\n".join(body).strip()
                i = k
            if note:
                note = note[0].upper() + note[1:]
                if not note.endswith("."):
                    note += "."
            if label.startswith("3D model") and not text:
                note = MODEL_NOTE if not note or "Tripo" in note or "rigged" in note else note
            cur["blocks"].append({"part": part_of(label), "label": "Cut-out"
                                  if label.startswith("Battlefield") else label,
                                  "size": size, "file": file, "text": text, "note": note})
        i += 1
    return entries, round_titles, round_intro


def card_id(entry):
    for b in entry["blocks"]:
        if b["file"]:
            stem = os.path.splitext(os.path.basename(b["file"]))[0]
            if b["part"] == "music":
                return stem
            return stem
    return re.sub(r"\W+", "_", entry["name"].lower()).strip("_")


def old_blocks(c):
    """The old kit format (card/cut/model + spec list) to blocks."""
    out = []
    specs = c.get("spec", [])

    def spec(n):
        if n >= len(specs):
            return "", ""
        parts = [p.strip() for p in specs[n].split(" · ")]
        file = parts[-1][len("save as "):] if parts[-1].startswith("save as ") else ""
        return " · ".join(parts[1:-1] if file else parts[1:]), file

    size, file = spec(0)
    out.append({"part": "painting", "label": "Card painting", "size": size, "file": file,
                "text": c.get("card", ""), "note": ""})
    if c.get("cut"):
        size, file = spec(1)
        out.append({"part": "cutout", "label": "Summon cut-out" if c["kind"] == "summon" else "Cut-out",
                    "size": size, "file": file, "text": c["cut"],
                    "note": "Attach this card's painting as the reference, then remove the grey background."})
    if c.get("model"):
        size, file = spec(2)
        if file and not file.startswith("models/"):
            file = "models/" + (file if "/" in file else
                                ("summons/" if c["kind"] == "summon" else "creatures/") + file)
        out.append({"part": "model", "label": "3D model", "size": size, "file": file,
                    "text": c["model"], "note": c.get("modelNote", "")})
    return out


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else rel("build/prompt_kit.html")
    files = repo_files()
    game = game_cards()
    entries, round_titles, round_intro = parse_doc()
    newest = max(round_titles) if round_titles else 0

    def group_of(rnd):
        return "round-%d" % rnd if rnd in round_titles else "rounds-1-3"

    cards, seen = [], set()
    for e in entries:
        cid = card_id(e)
        if e["kind"] == "music":
            cid = "music_" + cid
        if cid in seen:
            continue
        seen.add(cid)
        g = game.get(cid, {})
        kind = e["kind"]
        blocks = e["blocks"]
        if kind in ("totem", "summon") and not any(b["part"] == "model" for b in blocks):
            folder = "models/summons/" if kind == "summon" else "models/creatures/"
            blocks.append({"part": "model", "label": "3D model", "size": "Tripo3D", "file": folder + cid + ".glb",
                           "text": "", "note": MODEL_NOTE})
        status = {}
        for b in blocks:
            if b["file"]:
                status[b["part"]] = status.get(b["part"], True) and has_file(files, b["file"])
        prev = game[g["from"]]["name"] if g.get("from") in game else ""
        tier = g.get("tier", 0) if kind not in ("god", "music") else 0
        cards.append({"id": cid, "name": e["name"], "kind": kind, "el": g.get("el", e["el"]) if kind != "music" else "any",
                      "tier": tier, "tierName": TIER_NAMES[tier] if tier < len(TIER_NAMES) else "",
                      "stage": g.get("stage", 0), "prev": prev, "first": False, "refNote": "",
                      "group": group_of(e["round"]), "blocks": blocks, "status": status})

    extra_path = rel("docs/prompt-kit-extra.json")
    if os.path.exists(extra_path):
        for c in json.load(open(extra_path, encoding="utf-8")):
            if c["id"] in seen:
                continue
            seen.add(c["id"])
            blocks = old_blocks(c)
            status = {}
            for b in blocks:
                if b["file"]:
                    status[b["part"]] = has_file(files, b["file"])
            story = bool(c.get("refNote")) or c["kind"] in ("totem", "summon") and len(blocks) > 1
            g = game.get(c["id"], {})
            tier = g.get("tier", c.get("tier", 0))
            cards.append({"id": c["id"], "name": c["name"], "kind": c["kind"], "el": c.get("el", "any"),
                          "tier": tier, "tierName": TIER_NAMES[tier] if tier < len(TIER_NAMES) else "",
                          "stage": c.get("stage", 0), "prev": c.get("prev", ""), "first": c.get("first", False),
                          "refNote": c.get("refNote", ""), "group": "story" if story else "rounds-1-3",
                          "blocks": blocks, "status": status})

    # A god painting or music takes its round's element (Kaethis's round is all Astral).
    for c in cards:
        if c["kind"] in ("god", "music"):
            els = [d["el"] for d in cards if d["group"] == c["group"] and d["el"] != "any" and d is not c]
            if els:
                c["el"] = max(set(els), key=els.count)

    groups = []
    for n in sorted(round_titles, reverse=True):
        groups.append({"key": "round-%d" % n, "title": round_titles[n], "intro": round_intro.get(n, ""),
                       "isNew": n == newest})
    groups.append({"key": "story", "title": "Story cards: River Hound and Ser Aldric's three",
                   "intro": "River Hound is Tam's Totem in the Prologue. The three Radiant cards are for Ser Aldric's duel in Chapter 1.",
                   "isNew": False})
    groups.append({"key": "rounds-1-3", "title": "Rounds 1 to 3: the first cards",
                   "intro": "The starter Totems, Summons, Rites and Wards, and the Rites that bring the status conditions.",
                   "isNew": False})
    used = {c["group"] for c in cards}
    groups = [g for g in groups if g["key"] in used]

    today = datetime.date.today()
    checked = "%d %s %d" % (today.day, today.strftime("%B"), today.year)
    tpl = open(rel("tools/prompt_kit.html"), encoding="utf-8").read()
    data = json.dumps(cards, ensure_ascii=False).replace("</", "<\\/")
    page = (tpl.replace("/*CARDS*/[]", data)
               .replace("/*GROUPS*/[]", json.dumps(groups, ensure_ascii=False).replace("</", "<\\/"))
               .replace("/*CHECKED*/", checked))
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    open(out_path, "w", encoding="utf-8").write(page)
    todo = [c for c in cards if not all(c["status"].values())]
    print("%d cards in %d rounds, %d still to make; wrote %s" % (len(cards), len(groups), len(todo), out_path))


if __name__ == "__main__":
    main()
