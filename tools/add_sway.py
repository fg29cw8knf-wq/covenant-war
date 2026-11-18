#!/usr/bin/env python3
"""Paints how much each part of a prop moves in the wind into its second UV
set (TEXCOORD_1.x, 0 still .. 1 free), for assets/shaders/village/sway.gdshader
(18 November, Gary's yes to "make the thorn bushes and the bank's ferns sway a
little in the wind").

  --tree   a bush or tree: nothing at the foot, rising with height (the trunk
           and roots still, the outer twigs and leaves most), more the further
           out from the middle.
  --fronds the bank: only what stands out from the bank's own surface (the
           ferns, the bracken, the grass), measured as how far each vertex is
           from the mesh smoothed over and over (a fern's tip far, the moss
           and the earth near), and only where its paint is green or rust
           (the pale roots and the timber stay still).

    python3 tools/add_sway.py assets/models/ashford/thorn_bush.glb --tree
    python3 tools/add_sway.py assets/models/ashford/tunnel_mouth.glb --fronds

Writes the GLB in place (a second run replaces the weights). Prints how much
of the mesh moves.
"""
import io, json, os, struct, sys

import numpy as np
from PIL import Image
from scipy.sparse import coo_matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rebake_glb import accessor  # noqa: E402

Image.MAX_IMAGE_PIXELS = None


def load(path):
    raw = open(path, "rb").read()
    jl = struct.unpack_from("<I", raw, 12)[0]
    j = json.loads(raw[20:20 + jl])
    off = 20 + jl
    bl = struct.unpack_from("<I", raw, off)[0]
    b = bytearray(raw[off + 8:off + 8 + bl])
    return j, b


def save(path, j, b):
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(b) % 4:
        b.append(0)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(b)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(b), 0x004E4942))
        f.write(bytes(b))


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def main():
    path = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "--tree"
    j, b = load(path)
    pr = j["meshes"][0]["primitives"][0]
    P = accessor(j, bytes(b), pr["attributes"]["POSITION"]).astype(np.float64)
    F = accessor(j, bytes(b), pr["indices"]).reshape(-1, 3).astype(np.int64)
    lo, hi = P.min(0), P.max(0)
    size = hi - lo
    if mode == "--tree":
        h = (P[:, 1] - lo[1]) / size[1]
        mid = (lo + hi) * 0.5
        r = np.hypot(P[:, 0] - mid[0], P[:, 2] - mid[2]) / (0.5 * max(size[0], size[2]))
        w = smoothstep(0.22, 0.95, h) ** 1.3 * (0.45 + 0.55 * np.clip(r, 0, 1))
    else:
        # the surface smoothed: each vertex pulled to the mean of its
        # neighbours (welded by place: the unwrap splits them at its seams)
        key = np.round(P * 1e5).astype(np.int64)
        _, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
        inv = inv.ravel()
        Q = P[first].copy()
        Fw = inv[F]
        rows = np.concatenate([Fw[:, 0], Fw[:, 1], Fw[:, 2], Fw[:, 1], Fw[:, 2], Fw[:, 0]])
        cols = np.concatenate([Fw[:, 1], Fw[:, 2], Fw[:, 0], Fw[:, 0], Fw[:, 1], Fw[:, 2]])
        A = coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(len(Q), len(Q))).tocsr()
        A.data[:] = 1.0
        deg = np.asarray(A.sum(1)).ravel()
        deg[deg == 0] = 1.0
        S = Q.copy()
        for _ in range(60):
            S = 0.5 * S + 0.5 * (A @ S) / deg[:, None]
        out = np.linalg.norm(Q - S, axis=1)[inv]
        stick = smoothstep(0.004 * size.max(), 0.03 * size.max(), out)
        # the paint at each vertex: green or rust (leaves), not pale (roots, wood)
        uv = accessor(j, bytes(b), pr["attributes"]["TEXCOORD_0"]).astype(np.float64)
        mat = j["materials"][pr.get("material", 0)]
        ti = mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
        im = j["images"][j["textures"][ti]["source"]]
        if "uri" in im:
            pic = Image.open(os.path.join(os.path.dirname(path), im["uri"])).convert("RGB")
        else:
            v = j["bufferViews"][im["bufferView"]]
            pic = Image.open(io.BytesIO(bytes(b[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]))).convert("RGB")
        pic = pic.resize((1024, 1024), Image.BILINEAR)
        a = np.asarray(pic, np.float32) / 255.0
        px = np.clip((uv[:, 0] * 1024).astype(int), 0, 1023)
        py = np.clip((uv[:, 1] * 1024).astype(int), 0, 1023)
        c = a[py, px]
        mx, mn = c.max(1), c.min(1)
        sat = (mx - mn) / (mx + 1e-6)
        green = (c[:, 1] >= c[:, 0] * 0.95) & (c[:, 1] > c[:, 2])
        rust = (c[:, 0] > c[:, 1] * 1.15) & (sat > 0.45)
        leafy = smoothstep(0.25, 0.45, sat) * (green | rust)
        w = stick * leafy
    w = np.clip(w, 0.0, 1.0).astype(np.float32)
    uv2 = np.stack([w, np.zeros_like(w)], 1).astype(np.float32)
    # the weights as their own buffer view and accessor (replacing an old one)
    while len(b) % 4:
        b.append(0)
    data = uv2.tobytes()
    if "TEXCOORD_1" in pr["attributes"]:
        ai = pr["attributes"]["TEXCOORD_1"]
        vi = j["accessors"][ai]["bufferView"]
        if j["bufferViews"][vi]["byteLength"] == len(data):
            o = j["bufferViews"][vi].get("byteOffset", 0)
            b[o:o + len(data)] = data
            save(path, j, b)
            print("%s: weights replaced; %.0f%% of it moves, %.0f%% freely" % (path, 100 * (w > 0.05).mean(), 100 * (w > 0.5).mean()))
            return
    j["bufferViews"].append({"buffer": 0, "byteOffset": len(b), "byteLength": len(data), "target": 34962})
    b.extend(data)
    j["accessors"].append({"bufferView": len(j["bufferViews"]) - 1, "componentType": 5126, "count": len(uv2), "type": "VEC2"})
    pr["attributes"]["TEXCOORD_1"] = len(j["accessors"]) - 1
    j["buffers"][0]["byteLength"] = len(b)
    save(path, j, b)
    print("%s: %.0f%% of it moves, %.0f%% freely" % (path, 100 * (w > 0.05).mean(), 100 * (w > 0.5).mean()))


if __name__ == "__main__":
    main()
