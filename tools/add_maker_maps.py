"""Puts a Tripo3D model's own normal and roughness-metal maps back onto the
copy of it already in the game (18 November: Gary's originals of the
Brookfin, the River Hound and the Cinderpup, from his Downloads).

tools/split_creature.py dropped them until 18 November. The game's model is
the same mesh as Gary's file (the same vertices and the same UVs: checked
here, and nothing is changed if they differ), so his maps fit it as they
are: written beside it as <id>_normal.png (2048) and <id>_mr.png (1024),
with their import settings, and put on its material (metal and roughness
from the map, its factors 1). A normal map this repo's derive_creature_maps.py
made for it (a stand-in) is replaced; the duel then leaves the model's own
alone (DuelField3D._skin).

    python3 tools/add_maker_maps.py <gary's original.glb> assets/models/creatures/<id>.glb [--metal 0.15]

--metal: how much of the map's metal is kept (the material's metal factor;
1 as Tripo3D made it). The Unspent Hour is the case (18 November): Tripo3D
painted its pale glass as polished metal (0.86 metal, 0.14 rough on
average), and metal has no colour of its own, only what it mirrors: under
an arena's night sky it stood as black chrome, nothing like its painting.
At 0.15 it is glass again: its own pale colour, its maker's fine shape and
shine.
"""
import io, json, os, struct, sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from derive_creature_maps import accessor, read_glb  # noqa: E402
from derive_maps import write_import  # noqa: E402


def uvs(j, b):
    out = []
    for m in j["meshes"]:
        for p in m["primitives"]:
            out.append(accessor(j, b, p["attributes"]["TEXCOORD_0"]))
    return out


def picture(j, b, info):
    im = j["images"][j["textures"][info["index"]]["source"]]
    v = j["bufferViews"][im["bufferView"]]
    o = v.get("byteOffset", 0)
    return Image.open(io.BytesIO(b[o:o + v["byteLength"]])).convert("RGB")


def main():
    args = sys.argv[1:]
    metal = 1.0
    if "--metal" in args:
        i = args.index("--metal")
        metal = float(args[i + 1])
        del args[i:i + 2]
    src, dst = args[0], args[1]
    js, bs = read_glb(src)
    jd, bd = read_glb(dst)
    us, ud = uvs(js, bs), uvs(jd, bd)
    if len(us) != len(ud) or any(a.shape != c.shape or float(np.abs(a - c).max()) > 1e-5 for a, c in zip(us, ud)):
        sys.exit("%s isn't the same mesh as %s (its UVs differ): nothing changed" % (src, dst))
    ms = js["materials"][0]
    pbr_s = ms.get("pbrMetallicRoughness", {})
    stem = os.path.basename(dst)[:-4]
    out_dir = os.path.dirname(dst)
    raw = open(dst, "rb").read()
    ln = struct.unpack_from("<I", raw, 12)[0]
    j = json.loads(raw[20:20 + ln])
    rest = raw[20 + ln:]
    if len(j["materials"]) != 1:
        sys.exit("%s has %d materials (expected the one split_creature.py leaves)" % (dst, len(j["materials"])))
    mat = j["materials"][0]
    pbr = mat.setdefault("pbrMetallicRoughness", {})
    for key, suffix, lim, normal in [("normalTexture", "normal", 2048, True), ("metallicRoughnessTexture", "mr", 1024, False)]:
        info = ms.get(key) if key == "normalTexture" else pbr_s.get(key)
        if info is None:
            print("%s: no %s map in the original" % (stem, suffix))
            continue
        pic = picture(js, bs, info)
        if pic.width > lim:
            pic = pic.resize((lim, lim), Image.LANCZOS)
        name = "%s_%s.png" % (stem, suffix)
        pic.save(os.path.join(out_dir, name), "PNG", optimize=True)
        write_import(os.path.join(out_dir, name), normal)
        # the picture on the material, once (a second run finds it there)
        idx = next((i for i, im in enumerate(j["images"]) if im.get("uri") == name), None)
        if idx is None:
            j["images"].append({"name": suffix, "uri": name})
            idx = len(j["images"]) - 1
        tex = next((i for i, t in enumerate(j["textures"]) if t.get("source") == idx), None)
        if tex is None:
            j["textures"].append({"sampler": 0, "source": idx})
            tex = len(j["textures"]) - 1
        if normal:
            mat["normalTexture"] = {"index": tex}
        else:
            pbr["metallicRoughnessTexture"] = {"index": tex}
            pbr["metallicFactor"] = metal
            pbr["roughnessFactor"] = 1.0
            a = np.asarray(pic, dtype=np.float32) / 255.0
            print("%s: roughness %.2f on average, metal %.2f%s" % (stem, a[..., 1].mean(), a[..., 2].mean(),
                  "" if metal == 1.0 else " (kept at %.2f of it: %.2f)" % (metal, a[..., 2].mean() * metal)))
        print("%s: the maker's %s map put back (%s, %d)" % (stem, suffix, name, pic.width))
    js_out = json.dumps(j, separators=(",", ":")).encode()
    while len(js_out) % 4:
        js_out += b" "
    total = 12 + 8 + len(js_out) + len(rest)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js_out), 0x4E4F534A))
        f.write(js_out)
        f.write(rest)


if __name__ == "__main__":
    main()
