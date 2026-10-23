"""Smooths a bad patch of a model's surface, in place.

An AssetFurnace mesh can carry a patch of sliver triangles whose UVs point
all over the atlas and whose normals point every way (Corin's shoulder
blade, 23 October: "a hole in the back of him"). The vertices within `r`
of the spot are smoothed towards their neighbours, given the normal of the
ring of surface round them, and mapped to that ring's place on the atlas,
so the patch takes the colour of the cloth round it; then every triangle
is wound to face the way its normals now say (mend_winding).
    python3 tools/mend_patch.py assets/models/characters/corin.glb 0.066,1.53,-0.09 0.035
"""
import json, struct, sys, os
import numpy as np

CT = {5126: ("<f4", 4), 5123: ("<u2", 2), 5125: ("<u4", 4), 5121: ("<u1", 1)}
N_OF = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def mend(path, at, r):
    d = open(path, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    b = bytearray(d[off + 8:off + 8 + bl])

    def span(i):
        a = j["accessors"][i]
        v = j["bufferViews"][a["bufferView"]]
        o = v.get("byteOffset", 0) + a.get("byteOffset", 0)
        dt, sz = CT[a["componentType"]]
        n = N_OF[a["type"]]
        return o, a["count"], n, dt, sz

    def read(i):
        o, c, n, dt, sz = span(i)
        return np.frombuffer(bytes(b[o:o + c * n * sz]), dtype=dt).reshape(c, n).astype(np.float64)

    def write(i, arr):
        o, c, n, dt, sz = span(i)
        b[o:o + c * n * sz] = arr.astype(dt).tobytes()

    touched = 0
    for m in j["meshes"]:
        for p in m["primitives"]:
            P = read(p["attributes"]["POSITION"])
            N = read(p["attributes"]["NORMAL"])
            UV = read(p["attributes"]["TEXCOORD_0"])
            I = read(p["indices"]).reshape(-1, 3).astype(np.int64)
            dist = np.linalg.norm(P - np.asarray(at), axis=1)
            inside = np.where(dist < r)[0]
            ring = np.where((dist >= r) & (dist < r * 1.8))[0]
            if len(inside) == 0 or len(ring) == 0:
                continue
            touched += len(inside)
            # neighbours over the triangles, for the smoothing
            nb = {}
            for tri in I:
                for a_, b_ in [(0, 1), (1, 2), (2, 0)]:
                    nb.setdefault(tri[a_], set()).add(tri[b_])
                    nb.setdefault(tri[b_], set()).add(tri[a_])
            w = np.clip(1.0 - dist[inside] / r, 0.0, 1.0)
            w = w * w * (3 - 2 * w)
            for _ in range(3):
                Q = P.copy()
                for k, vi in enumerate(inside):
                    ns = list(nb.get(vi, []))
                    if ns:
                        Q[vi] = P[vi] + (P[ns].mean(0) - P[vi]) * w[k]
                P = Q
            ring_n = N[ring].mean(0)
            ring_n /= max(np.linalg.norm(ring_n), 1e-9)
            for k, vi in enumerate(inside):
                N[vi] = N[vi] * (1 - w[k]) + ring_n * w[k]
                N[vi] /= max(np.linalg.norm(N[vi]), 1e-9)
            # the ring's place on the atlas, where its UVs agree (the median:
            # a ring vertex mapped off elsewhere doesn't pull it)
            uv0 = np.median(UV[ring], axis=0)
            for k, vi in enumerate(inside):
                UV[vi] = UV[vi] * (1 - w[k]) + uv0 * w[k]
            write(p["attributes"]["POSITION"], P)
            write(p["attributes"]["NORMAL"], N)
            write(p["attributes"]["TEXCOORD_0"], UV)
    out = bytearray(d[:off + 8]) + b
    open(path, "wb").write(bytes(out))
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from mend_winding import mend as wind
    return touched, wind(path)


if __name__ == "__main__":
    path = sys.argv[1]
    at = [float(x) for x in sys.argv[2].split(",")]
    r = float(sys.argv[3]) if len(sys.argv) > 3 else 0.03
    n, flipped = mend(path, at, r)
    print("%s: %d vertices smoothed round %s, %d triangles then turned round" % (path, n, at, flipped))
