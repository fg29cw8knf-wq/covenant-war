#!/usr/bin/env python3
"""How big the game's textures are once imported, under one switch.

Every texture under assets/ has a Godot .import file beside it. This sets
`process/size_limit` in them by what the texture is for (its folder), from
the table below, under a named profile:

  full    no limits: every texture at the size Gary made it (today's state;
          Gary, 2 November: his 4K models in at full size)
  launch  people and the star creatures 2048, props and scenery 1024 (the
          Before-launch list), for when the store build needs to be smaller

A texture still stored lossless (`compress/mode=0`) on a 3D model is moved to
VRAM compression under `launch` too (ASTC on iPhone: project.godot already
has textures/vram_compression/import_etc2_astc=true). Card paintings and the
UI (assets/art/) are left alone by every profile unless the table says so.
The size limit only shrinks what Godot imports; the source files are never
touched, so going back to `full` brings every texture back at full size.

Dry run by default: prints what would change, and the textures' pixels per
class before and after. --apply writes the .import files (Godot then
re-imports what changed the next time the editor or `godot --import` runs).

  python3 tools/texture_sizes.py                          # what `full` would change
  python3 tools/texture_sizes.py --profile launch         # what `launch` would change
  python3 tools/texture_sizes.py --profile launch --apply # and do it
  python3 tools/texture_sizes.py --profile full --apply   # back to full size
"""

import argparse
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# What a texture is for, by its folder (the first match wins).
CLASSES = [
    ("people", ["assets/models/characters/"]),
    ("stars", ["assets/models/creatures/", "assets/models/summons/"]),
    ("props", ["assets/models/"]),            # the rest of the models: props and scenery
    ("art", ["assets/art/"]),                 # card paintings, portraits, the UI
    ("other", ["assets/"]),
]

# The longest side each class is imported at: 0 is no limit, None leaves the
# class's files exactly as they are.
PROFILES = {
    "full": {"people": 0, "stars": 0, "props": 0, "art": None, "other": None},
    "launch": {"people": 2048, "stars": 2048, "props": 1024, "art": None, "other": None},
}
# What a still-lossless 3D model texture is stored as, by profile
# (None: as it is; 2: VRAM compressed, ASTC on the phone).
LOSSLESS_TO = {"full": None, "launch": 2}
THREE_D = ("people", "stars", "props")


def classify(rel):
    for name, prefixes in CLASSES:
        if any(rel.startswith(p) for p in prefixes):
            return name
    return None


def image_size(path):
    """(width, height) of a PNG, JPEG or WebP, read from its header; None if unknown."""
    try:
        with open(path, "rb") as f:
            head = f.read(32)
            if head[:8] == b"\x89PNG\r\n\x1a\n":
                return struct.unpack(">II", head[16:24])
            if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
                kind = head[12:16]
                f.seek(0)
                data = f.read(40)
                if kind == b"VP8 ":
                    w, h = struct.unpack("<HH", data[26:30])
                    return w & 0x3FFF, h & 0x3FFF
                if kind == b"VP8L":
                    b = data[21:25]
                    w = 1 + (((b[1] & 0x3F) << 8) | b[0])
                    h = 1 + (((b[3] & 0xF) << 10) | (b[2] << 2) | ((b[1] & 0xC0) >> 6))
                    return w, h
                if kind == b"VP8X":
                    w = 1 + int.from_bytes(data[24:27], "little")
                    h = 1 + int.from_bytes(data[27:30], "little")
                    return w, h
                return None
            if head[:2] == b"\xff\xd8":
                f.seek(2)
                while True:
                    m = f.read(2)
                    if len(m) < 2 or m[0] != 0xFF:
                        return None
                    while m[1] == 0xFF:
                        m = m[:1] + f.read(1)
                    if 0xC0 <= m[1] <= 0xCF and m[1] not in (0xC4, 0xC8, 0xCC):
                        f.read(3)
                        h, w = struct.unpack(">HH", f.read(4))
                        return w, h
                    seg = struct.unpack(">H", f.read(2))[0]
                    f.seek(seg - 2, 1)
    except (OSError, struct.error):
        return None
    return None


def limited(size, limit):
    """The size Godot imports at under a longest-side limit (0: none)."""
    w, h = size
    if not limit or max(w, h) <= limit:
        return w, h
    k = limit / max(w, h)
    return max(1, int(w * k)), max(1, int(h * k))


def get(text, key):
    m = re.search(r"^%s=(.*)$" % re.escape(key), text, re.M)
    return m.group(1).strip() if m else None


def put(text, key, value):
    if re.search(r"^%s=" % re.escape(key), text, re.M):
        return re.sub(r"^%s=.*$" % re.escape(key), "%s=%s" % (key, value), text, count=1, flags=re.M)
    return text.rstrip("\n") + "\n%s=%s\n" % (key, value)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--profile", default="full", choices=sorted(PROFILES))
    ap.add_argument("--apply", action="store_true", help="write the .import files (default: a dry run)")
    args = ap.parse_args()
    table = PROFILES[args.profile]
    to_mode = LOSSLESS_TO[args.profile]

    changes = []
    budget = {}   # class -> [files, source pixels, pixels after]
    for dirpath, _dirs, files in os.walk(os.path.join(ROOT, "assets")):
        for fn in sorted(files):
            if not fn.endswith(".import"):
                continue
            ip = os.path.join(dirpath, fn)
            rel = os.path.relpath(ip, ROOT).replace(os.sep, "/")
            with open(ip, encoding="utf-8") as f:
                text = f.read()
            if get(text, "importer") != '"texture"':
                continue
            cls = classify(rel)
            src = ip[: -len(".import")]
            size = image_size(src)
            limit = table.get(cls)
            old_limit = int(get(text, "process/size_limit") or 0)
            new_text = text
            what = []
            if limit is not None and old_limit != limit:
                new_text = put(new_text, "process/size_limit", limit)
                w = "limit %s -> %s" % (old_limit or "none", limit or "none")
                if size:
                    before, after = limited(size, old_limit), limited(size, limit)
                    w += ": imports at %dx%d" % after if after != before else " (its size doesn't change)"
                what.append(w)
            mode = get(text, "compress/mode")
            if to_mode is not None and cls in THREE_D and mode == "0":
                new_text = put(new_text, "compress/mode", to_mode)
                what.append("lossless -> VRAM compressed")
            b = budget.setdefault(cls, [0, 0, 0])
            if size:
                eff = limit if limit is not None else old_limit
                after = limited(size, eff)
                b[0] += 1
                b[1] += size[0] * size[1]
                b[2] += after[0] * after[1]
            if new_text != text:
                changes.append((rel[: -len(".import")], cls, size, ", ".join(what)))
                if args.apply:
                    with open(ip, "w", encoding="utf-8") as f:
                        f.write(new_text)

    verb = "Changed" if args.apply else "Would change"
    print("Profile: %s%s" % (args.profile, "" if args.apply else "  (dry run: add --apply to write)"))
    if changes:
        print("\n%s %d texture%s:" % (verb, len(changes), "" if len(changes) == 1 else "s"))
        print("  %-62s %-7s %-11s %s" % ("texture", "class", "source", "change"))
        for rel, cls, size, what in changes:
            print("  %-62s %-7s %-11s %s" % (rel[-62:], cls, "%dx%d" % size if size else "?", what))
    else:
        print("\nNothing to change: every texture is already as the %s profile wants it." % args.profile)
    print("\nPixel budget by class (megapixels of source images, and as imported under %s):" % args.profile)
    print("  %-8s %-14s %6s %10s %10s" % ("class", "limit", "files", "source", "imported"))
    for name, _p in CLASSES:
        if name not in budget:
            continue
        n, srcpx, after = budget[name]
        lim = table.get(name)
        lim_t = "left alone" if lim is None else ("none" if lim == 0 else "%d" % lim)
        print("  %-8s %-14s %6d %9.1fM %9.1fM" % (name, lim_t, n, srcpx / 1e6, after / 1e6))
    tot = [sum(b[i] for b in budget.values()) for i in range(3)]
    print("  %-8s %-14s %6d %9.1fM %9.1fM" % ("all", "", tot[0], tot[1] / 1e6, tot[2] / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
