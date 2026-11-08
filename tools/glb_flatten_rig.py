"""Folds the turns on the nodes above a skeleton (Tripo3D's node_0 / RootNode /
Armature, a quarter turn each about Y and X) down into the skeleton's root
joints, so those nodes stand at the identity and Godot's Skeleton3D sits
square in the world.

Why: Godot puts a skinned mesh under its Skeleton3D and draws it where the
bones put it, but measures it (MeshInstance3D.get_aabb, which
DuelField3D._merged_aabb walks up through the parents) as the mesh's own
bounds turned by the nodes above the skeleton. After tools/glb_bake_turn.py
the mesh's bounds are its rest pose, so with those nodes at the identity the
measure and the picture agree, and a Totem stands on the field's floor
instead of floating half its height above it (8 November: the Scrivener,
Loomwarden, the Unspent Hour and the Weft Serpent, Gary's Tripo3D creatures,
measured as centred on the origin while their bones lifted them to stand on
it).

  python3 tools/glb_flatten_rig.py in.glb out.glb

Run it after glb_bake_turn.py and before split_creature.py. A root joint's
clips (its translation and rotation keys) are turned with it, so nothing
moves. The nodes' turns must be rotations with a uniform scale.
"""
import json, os, struct, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_trs import mat_to_trs  # noqa: E402

NCOMP = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def qmat(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def local(n):
    if "matrix" in n:
        return np.array(n["matrix"], np.float64).reshape(4, 4).T
    m = np.eye(4)
    m[:3, :3] = qmat(n.get("rotation", [0, 0, 0, 1])) @ np.diag(n.get("scale", [1, 1, 1]))
    m[:3, 3] = n.get("translation", [0, 0, 0])
    return m


def trs_of(m):
    """A 4x4 (row-major, as our matrices are) as translation, rotation (x,y,z,w), scale."""
    return mat_to_trs(m.T.reshape(16).tolist())   # mat_to_trs takes glTF's column-major list


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
    joints = set()
    for sk in j.get("skins", []):
        joints.update(sk["joints"])
    # the topmost joints: those with no joint anywhere above them (a Tripo
    # rig can have plain nodes between joints, bone_4 under Spine_2 with
    # bone_5 under that; Godot makes bones of those too, so they stay)
    def joint_above(i):
        p = parent.get(i)
        while p is not None:
            if p in joints:
                return True
            p = parent.get(p)
        return False
    roots = [i for i in sorted(joints) if not joint_above(i)]
    # the nodes above the root joints, up to the scene
    above = set()
    for r in roots:
        p = parent.get(r)
        while p is not None:
            above.add(p)
            p = parent.get(p)
    if not above:
        print("%s: nothing above the skeleton to fold in" % src)
    # every node hanging directly off those (the root joints, and anything
    # else parented there that isn't itself one of them) takes its parents' turn
    def chain(i):
        m = np.eye(4)
        p = parent.get(i)
        while p is not None:
            m = local(nodes[p]) @ m
            p = parent.get(p)
        return m
    folded = []
    for i, n in enumerate(nodes):
        if i in above or parent.get(i) not in above:
            continue
        P = chain(i)
        if np.allclose(P, np.eye(4), atol=1e-6):
            continue
        t, r, s = trs_of(P)
        assert max(s) - min(s) < 1e-4, "%s: the turn above %s scales unevenly (%s)" % (src, n.get("name"), s)
        R, su = P[:3, :3] / s[0], s[0]
        Rq = np.array(r)
        new = trs_of(P @ local(n))
        for k in ("matrix",):
            n.pop(k, None)
        n["translation"], n["rotation"], n["scale"] = new
        folded.append((i, P, R, Rq, su))
    folded_i = {f[0]: f for f in folded}

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

    def qmul(a, q):
        ax, ay, az, aw = a
        qx, qy, qz, qw = q[:, 0], q[:, 1], q[:, 2], q[:, 3]
        return np.stack([aw * qx + ax * qw + ay * qz - az * qy,
                         aw * qy - ax * qz + ay * qw + az * qx,
                         aw * qz + ax * qy - ay * qx + az * qw,
                         aw * qw - ax * qx - ay * qy - az * qz], axis=1)

    # the clips of a folded node turn with it
    done = set()
    nkeys = 0
    for anim in j.get("animations", []):
        for ch in anim["channels"]:
            tgt = ch["target"]
            if tgt.get("node") not in folded_i:
                continue
            _, P, R, Rq, su = folded_i[tgt["node"]]
            out_i = anim["samplers"][ch["sampler"]]["output"]
            if out_i in done:
                continue
            done.add(out_i)
            a, at, arr = view(out_i)
            path = tgt["path"]
            if path == "translation":
                arr = (arr * su) @ R.T + P[:3, 3]
            elif path == "rotation":
                arr = qmul(Rq, arr)
                arr /= np.linalg.norm(arr, axis=1, keepdims=True)
            elif path == "scale":
                arr = arr * su
            else:
                continue
            write(at, arr)
            nkeys += len(arr)
    for i in above:
        for k in ("matrix", "translation", "rotation", "scale"):
            nodes[i].pop(k, None)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = [struct.pack("<II", len(js), 0x4E4F534A) + js]
    for ct, data in chunks[1:]:
        data = bytes(data) + b"\0" * ((4 - len(data) % 4) % 4)
        out.append(struct.pack("<II", len(data), ct) + data)
    body = b"".join(out)
    open(dst, "wb").write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)
    print("%s: %d node(s) above the skeleton set square, their turn folded into %s; %d clip keys turned" % (
        dst, len(above), ", ".join(nodes[f[0]].get("name", "?") for f in folded), nkeys))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
