"""Tips the head of every clip of a finished game model up or down by a few
degrees (two fifths at the neck, the rest at the head, as rig_character.py's
--head-up does), in place of rebuilding the model:

  python3 tools/head_level.py MODEL.glb DEG [OUT.glb] [--only clip,clip] [--skip clip,clip]

DEG > 0 lifts the chin, DEG < 0 lowers it. A clip with no turn on the neck
or the head (it leaves the head at rest) is left alone.

Why (28 October): the clips Player A plays were made for the AssetFurnace
faces, which are sculpted looking down (about 12 degrees) at rest, so those
clips lift the head (`--head-up 10` in rig_player.sh, and the walk tips it
back by itself). Gary's Tripo3D Player A (26 October) has his face level at
rest, and he took those clips over as they were: his chin was up in every
clip, the neck stretched long under it, and the face seen from below ("his
face still looks deformed, it's not like the model I gave you").
"""
import argparse, json, math, struct, sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from rig_character import load, acc, Rig, standard_names, qmul, qnorm  # noqa: E402

PARTS = (("Neck", 0.4), ("Head", 0.6))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("deg", type=float)
    ap.add_argument("out", nargs="?")
    ap.add_argument("--only", default="")
    ap.add_argument("--skip", default="")
    a = ap.parse_args()
    out = a.out or a.model
    only = {s for s in a.only.split(",") if s}
    skip = {s for s in a.skip.split(",") if s}
    j, b = load(a.model)
    rig = Rig(j, b)
    names = standard_names(rig)
    node = {names[i]: i for i in rig.joints}
    bins = bytearray(b)
    while len(bins) % 4:
        bins.append(0)
    done = []
    seen = set()
    for an in j["animations"]:
        if (only and an["name"] not in only) or an["name"] in skip:
            continue
        hit = False
        for nm, part in PARTS:
            if nm not in node:
                continue
            h = -math.radians(a.deg * part) / 2
            q = np.array([math.sin(h), 0.0, 0.0, math.cos(h)])
            for c in an["channels"]:
                if c["target"]["node"] != node[nm] or c["target"]["path"] != "rotation":
                    continue
                s = an["samplers"][c["sampler"]]
                if s["output"] in seen:
                    continue
                v = acc(j, b, s["output"]).astype(np.float64)
                cubic = s.get("interpolation") == "CUBICSPLINE"
                if cubic:
                    v[1::3] = qnorm(qmul(np.repeat(q[None], len(v[1::3]), 0), v[1::3]))
                else:
                    v = qnorm(qmul(np.repeat(q[None], len(v), 0), v))
                old = j["accessors"][s["output"]]
                bv = j["bufferViews"][old["bufferView"]]
                assert old["componentType"] == 5126 and bv.get("byteStride", 16) == 16, "float rotations expected"
                if s["output"] in seen:
                    continue
                seen.add(s["output"])
                # (written over the keys where they are: the same count and size)
                off = bv.get("byteOffset", 0) + old.get("byteOffset", 0)
                data = v.astype(np.float32).tobytes()
                bins[off:off + len(data)] = data
                hit = True
        if hit:
            done.append(an["name"])
    j["buffers"] = [{"byteLength": len(bins)}]
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    with open(out, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bins)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(bins), 0x004E4942))
        f.write(bytes(bins))
    print("head %+.1f deg in %d clips: %s" % (a.deg, len(done), ", ".join(done)))
    print("wrote", out)


if __name__ == "__main__":
    main()
