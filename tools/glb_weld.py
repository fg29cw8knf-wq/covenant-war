"""Welds a skinned model's doubled vertices before tools/rig_character.py
rigs it, and (--drop-clips) leaves its own clips out.

Tripo3D's Smart Mesh exports (Player A, 25 November) are quads, and every
quad comes with its own four corners: 113,956 vertices for 27,393 places on
the body. Corners that are the same in every way (place, normal, where they
sit on the picture, bones and weights) are made one here, which nothing on
screen can tell, and triangles with no area are dropped: 60,310 vertices, so
the phone skins about half as many each frame.

  python3 tools/glb_weld.py in.glb out.glb [--drop-clips]

--drop-clips: the model's own animations are left out, for a model that takes
every clip from another (Player A keeps the clips he had: `--borrow` only
fits a clip the model doesn't have itself).

The new arrays are added to the end of the file's buffer and the mesh pointed
at them; the old ones stay as dead weight until rig_character.py writes the
model afresh, so this is a step on the way, not a file for the game.
"""
import json, struct, sys
import numpy as np

NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
DT = {5126: np.float32, 5123: np.uint16, 5121: np.uint8, 5125: np.uint32, 5122: np.int16, 5120: np.int8}


def acc(j, b, i):
    a = j["accessors"][i]
    n, dt = NC[a["type"]], DT[a["componentType"]]
    bv = j["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    isz = np.dtype(dt).itemsize
    stride = bv.get("byteStride", n * isz)
    raw = np.frombuffer(b, np.uint8, stride * (a["count"] - 1) + n * isz, off)
    return np.lib.stride_tricks.as_strided(raw, (a["count"], n * isz), (stride, 1)).copy().view(dt).reshape(a["count"], n)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    drop_clips = "--drop-clips" in sys.argv
    src, dst = args
    raw = open(src, "rb").read()
    off, chunks = 12, []
    while off < len(raw):
        cl, ct = struct.unpack_from("<II", raw, off)
        chunks.append([ct, bytearray(raw[off + 8:off + 8 + cl])])
        off += 8 + cl
    j = json.loads(bytes(chunks[0][1]))
    b = chunks[1][1]
    nodes = [n for n in j["nodes"] if "mesh" in n and "skin" in n]
    assert len(nodes) == 1, "expected one skinned mesh"
    prims = j["meshes"][nodes[0]["mesh"]]["primitives"]
    assert len(prims) == 1, "expected one material"
    pr = prims[0]
    at = pr["attributes"]
    pos = acc(j, bytes(b), at["POSITION"]).astype(np.float32)
    nrm = acc(j, bytes(b), at["NORMAL"]).astype(np.float32)
    uv = acc(j, bytes(b), at["TEXCOORD_0"]).astype(np.float32)
    jn = acc(j, bytes(b), at["JOINTS_0"])
    wt = acc(j, bytes(b), at["WEIGHTS_0"]).astype(np.float32)
    idx = acc(j, bytes(b), pr["indices"]).astype(np.int64).reshape(-1, 3)
    key = np.concatenate([np.round(pos, 6), np.round(nrm, 3), np.round(uv, 6), jn.astype(np.float32), np.round(wt, 5)], 1)
    _, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    inv = inv.reshape(-1)
    # keep the file's own order (the first of each group)
    order = np.argsort(first)
    rank = np.empty(len(order), np.int64)
    rank[order] = np.arange(len(order))
    keep = first[order]
    idx2 = rank[inv][idx]
    a, c, d = pos[keep][idx2[:, 0]], pos[keep][idx2[:, 1]], pos[keep][idx2[:, 2]]
    area = np.linalg.norm(np.cross(c - a, d - a), axis=1)
    flat = (area < 1e-12) | (idx2[:, 0] == idx2[:, 1]) | (idx2[:, 1] == idx2[:, 2]) | (idx2[:, 0] == idx2[:, 2])
    idx2 = idx2[~flat]

    def add(arr, ctype, typ, target=None, minmax=False):
        data = np.ascontiguousarray(arr).tobytes()
        while len(b) % 4:
            b.append(0)
        bv = {"buffer": 0, "byteOffset": len(b), "byteLength": len(data)}
        if target:
            bv["target"] = target
        b.extend(data)
        j["bufferViews"].append(bv)
        a_ = {"bufferView": len(j["bufferViews"]) - 1, "componentType": ctype, "count": int(len(arr)), "type": typ}
        if minmax:
            a_["min"] = [float(x) for x in arr.min(0)]
            a_["max"] = [float(x) for x in arr.max(0)]
        j["accessors"].append(a_)
        return len(j["accessors"]) - 1
    jt = {np.dtype(np.uint8): 5121, np.dtype(np.uint16): 5123}[jn.dtype]
    pr["attributes"] = {
        "POSITION": add(pos[keep], 5126, "VEC3", 34962, True),
        "NORMAL": add(nrm[keep], 5126, "VEC3", 34962),
        "TEXCOORD_0": add(uv[keep], 5126, "VEC2", 34962),
        "JOINTS_0": add(jn[keep], jt, "VEC4", 34962),
        "WEIGHTS_0": add(wt[keep], 5126, "VEC4", 34962),
    }
    pr["indices"] = add(idx2.astype(np.uint32).reshape(-1), 5125, "SCALAR", 34963)
    pr.pop("extensions", None)   # (FB_ngon_encoding: the quads' fans, no use to the game)
    if drop_clips:
        j.pop("animations", None)
    while len(b) % 4:
        b.append(0)
    j["buffers"][0]["byteLength"] = len(b)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(b)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(b), 0x004E4942) + bytes(b))
    print("%s: %d vertices welded to %d, %d triangles (%d with no area dropped)%s"
          % (dst, len(pos), len(keep), len(idx2), int(flat.sum()), ", its own clips left out" if drop_clips else ""))


if __name__ == "__main__":
    main()
