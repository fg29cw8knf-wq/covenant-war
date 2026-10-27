"""Frees a finished game model's leather (an apron, a bag, a strap) from its
arms, the way rig_character.py --free-of-arms does while a model is built:

  python3 tools/free_arms.py MODEL.glb "R,G,B:TOL" [OUT.glb] [--keep-tris]

The vertices of about that colour (0-1, from the model's colour texture, a
file beside it or in it) bound to an arm or hand lose those bones and take
the body's, and the triangles that would join an arm to what isn't on it are
left out (as there). For a model whose weights were copied or made by
distance after it was built (reweight.py, reskin.py): Bram's 26 October
apron hangs beside his hands, so its sides were bound to them and flapped
out after his hands when he talked (27 October).
"""
import copy, json, os, struct, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc, Rig, standard_names, free_of_arms


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    keep_tris = "--keep-tris" in sys.argv
    model, spec = args[0], args[1]
    out = args[2] if len(args) > 2 else model
    j, b = load(model)
    rig = Rig(j, b)
    names = standard_names(rig)
    skin_names = [names[i] for i in j["skins"][0]["joints"]]
    pr = j["meshes"][0]["primitives"][0]
    # the colour texture into the buffer, if it's a file beside the model
    j2 = copy.deepcopy(j)
    b2 = bytearray(b)
    info = j2["materials"][pr["material"]]["pbrMetallicRoughness"]["baseColorTexture"]
    img = j2["images"][j2["textures"][info["index"]]["source"]]
    if "uri" in img:
        data = open(os.path.join(os.path.dirname(model), img["uri"]), "rb").read()
        while len(b2) % 4:
            b2.append(0)
        j2["bufferViews"].append({"buffer": 0, "byteOffset": len(b2), "byteLength": len(data)})
        b2.extend(data)
        img.clear()
        img.update({"bufferView": len(j2["bufferViews"]) - 1, "mimeType": "image/png"})
    jn = acc(j, b, pr["attributes"]["JOINTS_0"]).astype(np.int64)
    wts = acc(j, b, pr["attributes"]["WEIGHTS_0"]).astype(np.float32)
    wts = wts / np.maximum(wts.sum(1, keepdims=True), 1e-9)
    pos = acc(j, b, pr["attributes"]["POSITION"])
    jn2, w2, drop = free_of_arms(spec, j2, bytes(b2), j2["meshes"][0]["primitives"][0], skin_names, jn, wts,
                                 float(np.ptp(pos[:, 1])))
    bins = bytearray(b)

    def add(arr, ctype, atype, target=None):
        data = np.ascontiguousarray(arr).tobytes()
        while len(bins) % 4:
            bins.append(0)
        j["bufferViews"].append({"buffer": 0, "byteOffset": len(bins), "byteLength": len(data)} | ({"target": target} if target else {}))
        bins.extend(data)
        j["accessors"].append({"bufferView": len(j["bufferViews"]) - 1, "componentType": ctype, "count": int(arr.shape[0]), "type": atype})
        return len(j["accessors"]) - 1
    big = len(skin_names) >= 256
    pr["attributes"]["JOINTS_0"] = add(jn2.astype(np.uint16 if big else np.uint8), 5123 if big else 5121, "VEC4", 34962)
    pr["attributes"]["WEIGHTS_0"] = add(w2.astype(np.float32), 5126, "VEC4", 34962)
    if drop is not None and drop.any() and not keep_tris:
        idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)[~drop].reshape(-1)
        ct = 5125 if idx.max() > 65535 else 5123
        pr["indices"] = add(idx.astype(np.uint32 if ct == 5125 else np.uint16), ct, "SCALAR", 34963)
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
