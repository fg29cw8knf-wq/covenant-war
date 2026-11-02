"""Bakes a turn that sits on the nodes above a skinned figure into the figure
itself, so its bind pose is its rest pose and its mesh sits at the origin, as
tools/rig_character.py expects of a model it rigs. Tripo3D's Mixamo-rigged
exports (Warden Hale and the Ironvault enforcer, 2 November) put a quarter
turn about Y in a matrix on the node over the armature: the skin was bound
facing +X and the turn stands the figure facing +Z.

  python3 tools/glb_bake_turn.py in.glb out.glb

Matrices become translation, rotation and scale (tools/glb_trs.py); the skinned
mesh's vertices and normals are turned by what joint-world x inverse-bind
comes to at rest, the inverse binds are turned back to match, and the mesh's
node goes to the top of the scene (a skinned mesh's own node doesn't move it).
The joints, their clips and the weights are left as they are.
"""
import json, os, struct, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_trs import mat_to_trs  # noqa: E402

COMP = {5126: ("<f4", 4)}
NCOMP = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def qmat(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def local(n):
    m = np.eye(4)
    if "matrix" in n:
        return np.array(n["matrix"], np.float64).reshape(4, 4).T
    m[:3, :3] = qmat(n.get("rotation", [0, 0, 0, 1])) @ np.diag(n.get("scale", [1, 1, 1]))
    m[:3, 3] = n.get("translation", [0, 0, 0])
    return m


def main(src, dst):
    b = open(src, "rb").read()
    off, chunks = 12, []
    while off < len(b):
        cl, ct = struct.unpack_from("<II", b, off)
        chunks.append([ct, bytearray(b[off + 8:off + 8 + cl])])
        off += 8 + cl
    j = json.loads(bytes(chunks[0][1]))
    binc = chunks[1][1]
    nodes = j["nodes"]
    parent = {c: i for i, n in enumerate(nodes) for c in n.get("children", [])}

    def world(i):
        m = local(nodes[i])
        while i in parent:
            i = parent[i]
            m = local(nodes[i]) @ m
        return m

    def view(acc_i):
        a = j["accessors"][acc_i]
        bv = j["bufferViews"][a["bufferView"]]
        assert a["componentType"] == 5126 and "byteStride" not in bv, "expected tightly packed floats"
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        k = NCOMP[a["type"]]
        arr = np.frombuffer(bytes(binc[start:start + a["count"] * k * 4]), "<f4").reshape(a["count"], k).astype(np.float64)
        return a, start, arr

    def write(start, arr):
        binc[start:start + arr.size * 4] = arr.astype("<f4").tobytes()

    skin = j["skins"][0]
    _, ibm_at, ibm = view(skin["inverseBindMatrices"])
    ibms = [m.reshape(4, 4).T for m in ibm]
    turns = [world(jt) @ ibms[k] for k, jt in enumerate(skin["joints"])]
    T = np.mean(turns, axis=0)
    spread = max(np.abs(t - T).max() for t in turns)
    assert spread < 1e-3, "the joints don't agree on one rest turn (%.4f)" % spread
    if np.allclose(T, np.eye(4), atol=1e-4):
        print("bind pose is already the rest pose")
    R = T[:3, :3]
    # the skinned mesh: vertices and normals turned, bound back to the joints as before
    mesh_nodes = [i for i, n in enumerate(nodes) if "skin" in n]
    done = set()
    for mi in mesh_nodes:
        for prim in j["meshes"][nodes[mi]["mesh"]]["primitives"]:
            for key in ("POSITION", "NORMAL"):
                acc_i = prim["attributes"].get(key)
                if acc_i is None or acc_i in done:
                    continue
                done.add(acc_i)
                a, at, arr = view(acc_i)
                arr = arr @ R.T + (T[:3, 3] if key == "POSITION" else 0)
                write(at, arr)
                if key == "POSITION":
                    a["min"], a["max"] = arr.min(0).tolist(), arr.max(0).tolist()
            acc_i = prim["attributes"].get("TANGENT")
            if acc_i is not None and acc_i not in done:
                done.add(acc_i)
                a, at, arr = view(acc_i)
                arr[:, :3] = arr[:, :3] @ R.T
                write(at, arr)
    Ti = np.linalg.inv(T)
    new_ibm = np.array([(m @ Ti).T.reshape(16) for m in ibms])
    write(ibm_at, new_ibm)
    # the mesh's node to the top of the scene, unturned
    scene = j["scenes"][j.get("scene", 0)]
    for mi in mesh_nodes:
        if mi in parent:
            nodes[parent[mi]]["children"].remove(mi)
            scene["nodes"].append(mi)
        for k in ("matrix", "translation", "rotation", "scale"):
            nodes[mi].pop(k, None)
    for n in nodes:
        if "matrix" in n:
            t, r, s = mat_to_trs(n.pop("matrix"))
            n["translation"], n["rotation"], n["scale"] = t, r, s
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = [struct.pack("<II", len(js), 0x4E4F534A) + js]
    for ct, data in chunks[1:]:
        data = bytes(data) + b"\0" * ((4 - len(data) % 4) % 4)
        out.append(struct.pack("<II", len(data), ct) + data)
    body = b"".join(out)
    open(dst, "wb").write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)
    print("%s: rest turn baked in (%s)" % (dst, np.round(T[:3, :3], 3).tolist()))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
