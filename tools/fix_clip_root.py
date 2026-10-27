"""Puts a clip's root motion (the Hips' translation) right, taken from the
same clip on the model it was borrowed from, scaled by the two hip heights:

  python3 tools/fix_clip_root.py MODEL.glb SOURCE.glb CLIP [OUT.glb]

rig_character.py --borrow gave Player A Hob's get_out_of_bed (26 October)
with its root motion 7.6 times too big (the Hips dropped 3 m below the floor
and he rose 3.3 m to one side), so in the game he lay under the attic; the
turns of every joint were right. The keys must line up (the same clip).
"""
import json, struct, sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from rig_character import load, acc, Rig, standard_names


def hips_channel(j, b, clip):
    rig = Rig(j, b)
    names = standard_names(rig)
    hips = next(i for i in rig.joints if names[i] == "Hips")
    an = next(a for a in j["animations"] if a["name"] == clip)
    for c in an["channels"]:
        if c["target"]["node"] == hips and c["target"]["path"] == "translation":
            return hips, an, an["samplers"][c["sampler"]]
    raise SystemExit("%s has no Hips translation in %s" % (clip, clip))


def main():
    model, source, clip = sys.argv[1:4]
    out = sys.argv[4] if len(sys.argv) > 4 else model
    j, b = load(model)
    sj, sb = load(source)
    hips, _, samp = hips_channel(j, b, clip)
    ships, _, ssamp = hips_channel(sj, sb, clip)
    rest = np.array(j["nodes"][hips].get("translation", [0, 0, 0]), dtype=np.float64)
    srest = np.array(sj["nodes"][ships].get("translation", [0, 0, 0]), dtype=np.float64)
    st = acc(sj, sb, ssamp["output"]).astype(np.float64)
    n_own = j["accessors"][samp["output"]]["count"]
    if len(st) != n_own:
        raise SystemExit("the keys don't line up (%d against %d)" % (n_own, len(st)))
    k = rest[1] / srest[1]
    new = rest + (st - srest) * k
    new = new.astype(np.float32)
    print("%s: Hips from %s scaled by %.3f; first %s last %s" % (clip, source, k, np.round(new[0], 3), np.round(new[-1], 3)))
    bins = bytearray(b)
    while len(bins) % 4:
        bins.append(0)
    data = new.tobytes()
    j["bufferViews"].append({"buffer": 0, "byteOffset": len(bins), "byteLength": len(data)})
    bins.extend(data)
    j["accessors"].append({"bufferView": len(j["bufferViews"]) - 1, "componentType": 5126, "count": int(len(new)),
                           "type": "VEC3", "min": new.min(0).tolist(), "max": new.max(0).tolist()})
    samp["output"] = len(j["accessors"]) - 1
    j["buffers"] = [{"byteLength": len(bins)}]
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(bins) % 4:
        bins.append(0)
    with open(out, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bins)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(bins), 0x004E4942))
        f.write(bytes(bins))
    print("wrote", out)


if __name__ == "__main__":
    main()
