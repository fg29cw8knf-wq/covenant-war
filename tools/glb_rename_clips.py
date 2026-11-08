"""Renames clips inside a .glb so the duel finds them (DuelField3D.CLIP_ALIASES
reads idle, attack, hit, ko/defeat, summon/spawn, victory, run, guard and
rest, by name), leaving everything else as it is. Gary's Tripo3D creatures
(8 November: the Scrivener, Loomwarden, the Unspent Hour) come with their own
clip names: a humanoid's library (sword_swing, fight_stance, death, cheer...)
or a creature's (thread_shield, time_shield...).

  python3 tools/glb_rename_clips.py in.glb out.glb sword_swing=attack fight_stance=guard

A clip named for one that already exists replaces it. Clips can also be
dropped with `name=` (nothing after the equals).
"""
import json, struct, sys


def main(src, dst, pairs):
    b = open(src, "rb").read()
    magic, ver, length = struct.unpack("<III", b[:12])
    assert magic == 0x46546C67
    off, chunks = 12, []
    while off < length:
        cl, ct = struct.unpack("<II", b[off:off + 8])
        chunks.append([ct, b[off + 8:off + 8 + cl]])
        off += 8 + cl
    j = json.loads(chunks[0][1])
    renames = dict(p.split("=", 1) for p in pairs)
    anims = j.get("animations", [])
    # a rename onto an existing name replaces that clip
    taken = {a.get("name") for a in anims}
    for old, new in renames.items():
        if new and new in taken and new not in renames:
            anims = [a for a in anims if a.get("name") != new]
    out = []
    for a in anims:
        nm = a.get("name")
        if nm in renames:
            if renames[nm] == "":
                continue
            a["name"] = renames[nm]
        out.append(a)
    j["animations"] = out
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    binc = bytes(chunks[1][1]) if len(chunks) > 1 else b""
    total = 12 + 8 + len(js) + (8 + len(binc) if binc else 0)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", magic, ver, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        if binc:
            f.write(struct.pack("<II", len(binc), 0x004E4942))
            f.write(binc)
    print(dst, "clips:", ", ".join(a.get("name", "?") for a in out))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
