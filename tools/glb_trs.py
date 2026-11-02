"""Rewrites every node of a .glb that's placed by a 4x4 "matrix" as translation,
rotation and scale instead, which is how tools/rig_character.py and
tools/reskin.py read a node. Tripo3D's Mixamo-rigged exports (Warden Hale and
the Ironvault enforcer, 2 November) turn the whole figure a quarter round in a
matrix on the node above the armature; read as TRS that turn is kept, so the
figure faces +Z as it should and the rig tool sees it the right way round.

  python3 tools/glb_trs.py in.glb out.glb
"""
import json, struct, sys
import numpy as np


def mat_to_trs(m):
    m = np.array(m, np.float64).reshape(4, 4).T   # glTF matrices are column-major
    t = m[:3, 3]
    a = m[:3, :3]
    s = np.linalg.norm(a, axis=0)
    r = a / s
    if np.linalg.det(r) < 0:
        s[0] = -s[0]
        r[:, 0] = -r[:, 0]
    # rotation matrix -> quaternion (x, y, z, w)
    tr = np.trace(r)
    if tr > 0:
        k = np.sqrt(tr + 1.0) * 2
        q = [(r[2, 1] - r[1, 2]) / k, (r[0, 2] - r[2, 0]) / k, (r[1, 0] - r[0, 1]) / k, 0.25 * k]
    elif r[0, 0] > r[1, 1] and r[0, 0] > r[2, 2]:
        k = np.sqrt(1.0 + r[0, 0] - r[1, 1] - r[2, 2]) * 2
        q = [0.25 * k, (r[0, 1] + r[1, 0]) / k, (r[0, 2] + r[2, 0]) / k, (r[2, 1] - r[1, 2]) / k]
    elif r[1, 1] > r[2, 2]:
        k = np.sqrt(1.0 + r[1, 1] - r[0, 0] - r[2, 2]) * 2
        q = [(r[0, 1] + r[1, 0]) / k, 0.25 * k, (r[1, 2] + r[2, 1]) / k, (r[0, 2] - r[2, 0]) / k]
    else:
        k = np.sqrt(1.0 + r[2, 2] - r[0, 0] - r[1, 1]) * 2
        q = [(r[0, 2] + r[2, 0]) / k, (r[1, 2] + r[2, 1]) / k, 0.25 * k, (r[1, 0] - r[0, 1]) / k]
    q = np.array(q)
    q /= np.linalg.norm(q)
    return t.tolist(), q.tolist(), s.tolist()


def main(src, dst):
    b = open(src, "rb").read()
    off, chunks = 12, []
    while off < len(b):
        cl, ct = struct.unpack_from("<II", b, off)
        chunks.append([ct, b[off + 8:off + 8 + cl]])
        off += 8 + cl
    j = json.loads(chunks[0][1])
    n = 0
    for node in j.get("nodes", []):
        if "matrix" in node:
            t, r, s = mat_to_trs(node.pop("matrix"))
            node["translation"], node["rotation"], node["scale"] = t, r, s
            n += 1
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = [struct.pack("<II", len(js), 0x4E4F534A) + js]
    for ct, data in chunks[1:]:
        data += b"\0" * ((4 - len(data) % 4) % 4)
        out.append(struct.pack("<II", len(data), ct) + data)
    body = b"".join(out)
    open(dst, "wb").write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)
    print("%s: %d node matrices written as translation, rotation and scale" % (dst, n))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
