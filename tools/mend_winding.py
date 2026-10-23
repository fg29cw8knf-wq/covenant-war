"""Turns a model's inside-out triangles the right way round, in place.

An AssetFurnace mesh now and then has a few triangles wound the wrong way:
their face points into the body while their vertices' normals point out, so
with the back faces culled they're see-through from outside (Corin, 23
October: "a hole in the back of him", eleven triangles at his shoulder
blade). Each such triangle has two of its corners swapped here, so it faces
the way its normals say. Nothing else in the file changes.
    python3 tools/mend_winding.py assets/models/characters/corin.glb [more.glb...]
    python3 tools/mend_winding.py --check assets/models/characters/*.glb    (count only)
"""
import json, struct, sys
import numpy as np

CT = {5126: ("<f4", 4), 5123: ("<u2", 2), 5125: ("<u4", 4), 5121: ("<u1", 1)}
N_OF = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def mend(path, write=True):
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

    flipped = 0
    for m in j["meshes"]:
        for p in m["primitives"]:
            if "indices" not in p or "NORMAL" not in p["attributes"]:
                continue
            o, c, n, dt, sz = span(p["attributes"]["POSITION"])
            P = np.frombuffer(bytes(b[o:o + c * n * sz]), dtype=dt).reshape(c, n).astype(np.float64)
            o, c, n, dt, sz = span(p["attributes"]["NORMAL"])
            N = np.frombuffer(bytes(b[o:o + c * n * sz]), dtype=dt).reshape(c, n).astype(np.float64)
            o, c, n, dt, sz = span(p["indices"])
            I = np.frombuffer(bytes(b[o:o + c * sz]), dtype=dt).reshape(-1, 3).astype(np.int64)
            fn = np.cross(P[I[:, 1]] - P[I[:, 0]], P[I[:, 2]] - P[I[:, 0]])
            vn = N[I[:, 0]] + N[I[:, 1]] + N[I[:, 2]]
            bad = ((fn * vn).sum(1) < 0) & (np.linalg.norm(fn, axis=1) > 1e-12)
            if not bad.any():
                continue
            flipped += int(bad.sum())
            I2 = I.copy()
            I2[bad, 1], I2[bad, 2] = I[bad, 2], I[bad, 1]
            b[o:o + c * sz] = I2.astype(dt).tobytes()
    if write and flipped:
        out = bytearray(d[:off + 8])
        out += b
        open(path, "wb").write(bytes(out))
    return flipped


if __name__ == "__main__":
    args = sys.argv[1:]
    check = "--check" in args
    for f in [a for a in args if a != "--check"]:
        n = mend(f, not check)
        print("%s: %d triangle%s wound inside out%s" % (f, n, "" if n == 1 else "s", "" if check or not n else ", turned round"))
