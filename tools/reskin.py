"""Puts a new mesh of a character onto the game's skeleton, for a model whose
own rig can't be used (Tripo3D's Player A of 25 October came with its
skeleton turned 90 degrees to the mesh, so every clip mangled him; its Bram
came with every vertex bound to the hips alone), so that rig_character.py can
then dress it with the clips of the model it replaces:

  python3 tools/reskin.py NEW.glb REF.glb OUT.glb [--height 1.76]
  python3 tools/rig_character.py OUT.glb assets/models/characters/<id>.glb --name ... --height ... \\
      --borrow REF.glb:idle,walk,...   (every clip of the model it replaces)

REF is a game model (assets/models/characters/<id>.glb: the standard skeleton,
square to the world, feet at y=0) of about the same build and pose; the new
mesh (one skinned or unskinned mesh, one material, facing +Z) is scaled to
REF's height, feet on the ground, and:
  - the skeleton is REF's, each joint moved by the offset found between
    REF's flesh round that joint and the nearest points of the new mesh, so
    the knees, elbows and hands sit where the new figure's are;
  - the weights are made afresh from that skeleton: each vertex bound to the
    bones nearest to it (the distance to each bone's length, the hips to the
    head, the arms, the fingers, the legs), the nearest strongly and the next
    few fading with distance, then smoothed over the mesh so the blends at the
    joints are soft; a bone's reach stops at a few times the nearest bone's
    distance, so a hand hanging by a thigh keeps to the hand.
The output keeps the new model's material and textures as they are (embedded),
with bind pose = rest pose, for rig_character.py.
"""
import argparse, json, os, struct, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc, Rig, standard_names, CANON  # noqa: E402

import trimesh


def mesh_of(j, b):
    mesh_nodes = [i for i, n in enumerate(j["nodes"]) if "mesh" in n]
    assert len(mesh_nodes) == 1, "expected one mesh"
    mn = mesh_nodes[0]
    prims = j["meshes"][j["nodes"][mn]["mesh"]]["primitives"]
    assert len(prims) == 1, "expected one primitive (one material)"
    pr = prims[0]
    pos = acc(j, b, pr["attributes"]["POSITION"]).astype(np.float64)
    idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
    return mn, pr, pos, idx


def seg_dist(p, a, bb):
    """Distance from points p (n,3) to the segment a-b."""
    ab = bb - a
    L2 = max(float(ab @ ab), 1e-12)
    t = np.clip(((p - a) @ ab) / L2, 0.0, 1.0)
    q = a + t[:, None] * ab
    return np.linalg.norm(p - q, axis=1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("new")
    ap.add_argument("ref")
    ap.add_argument("out")
    ap.add_argument("--height", type=float, default=0.0, help="metres (default: REF's)")
    ap.add_argument("--bones", type=int, default=4, help="bones a vertex may blend")
    ap.add_argument("--reach", type=float, default=2.2, help="a bone further than this times the nearest bone's distance gets no weight")
    ap.add_argument("--smooth", type=int, default=6, help="smoothing passes over the mesh")
    args = ap.parse_args()

    rj, rb = load(args.ref)
    ref = Rig(rj, rb)
    rnames = standard_names(ref)
    by = {v: k for k, v in rnames.items()}
    _, rpr, rpos, ridx = mesh_of(rj, rb)
    rjn = acc(rj, rb, rpr["attributes"]["JOINTS_0"]).astype(np.int64)
    rw = acc(rj, rb, rpr["attributes"]["WEIGHTS_0"]).astype(np.float64)
    rjoints = ref.joints
    ref_h = rpos[:, 1].max() - rpos[:, 1].min()
    height = args.height or ref_h

    nj, nb = load(args.new)
    mn, npr, npos, nidx = mesh_of(nj, nb)
    lo, hi = npos.min(0), npos.max(0)
    s = height / (hi[1] - lo[1])
    npos = npos * s
    npos[:, 1] -= lo[1] * s
    # centred side to side and front to back where REF is (hips over the feet)
    rc = (rpos.min(0) + rpos.max(0)) * 0.5
    nc = (npos.min(0) + npos.max(0)) * 0.5
    npos[:, 0] += rc[0] - nc[0]
    npos[:, 2] += rc[2] - nc[2]
    rs = height / ref_h   # REF scaled to the asked height too
    rpos_s = rpos * rs
    ref_wp = {nm: ref.wp[by[nm]] * rs for nm in by}
    print("new mesh: %d vertices, %d triangles, scaled by %.3f to %.2f m; REF %s at %.2f m" % (
        len(npos), len(nidx), s, height, os.path.basename(args.ref), ref_h * rs))

    # ---- the skeleton: REF's joints moved by the flesh round them
    new_tm = trimesh.Trimesh(npos, nidx, process=False)
    closest, dist, _ = trimesh.proximity.closest_point(new_tm, rpos_s)
    disp = closest - rpos_s
    dense_r = np.zeros((len(rpos), len(rjoints)))
    for k in range(rjn.shape[1]):
        np.add.at(dense_r, (np.arange(len(rpos)), rjn[:, k]), rw[:, k])
    wp = {}
    order = [nm for nm in CANON if nm in by] + [nm for nm in by if nm not in CANON]
    parent = {}
    for nm in order:
        p = ref.bone_parent(by[nm])
        parent[nm] = rnames[p] if p is not None else None
    for nm in order:
        k = rjoints.index(by[nm])
        flesh = dense_r[:, k] >= 0.3
        if flesh.sum() >= 12:
            d = np.median(disp[flesh], axis=0)
        else:
            # a joint with no flesh of its own (a finger tip): its parent's move
            d = wp[parent[nm]] - ref_wp[parent[nm]] if parent.get(nm) in wp else np.zeros(3)
        wp[nm] = ref_wp[nm] + d
    # the hips and the feet stay level; nothing below the ground
    for nm in wp:
        wp[nm][1] = max(wp[nm][1], 0.01)

    # ---- bones as segments: each joint to its children (a leaf: on a little
    # past itself, the way its parent points)
    segs = []   # (name, a, b)
    kids = {nm: [c for c in order if parent.get(c) == nm] for nm in order}
    for nm in order:
        if parent.get(nm) is None:
            continue   # the root (on the ground under the hips) moves nothing
        a = wp[nm]
        if kids[nm]:
            for c in kids[nm]:
                segs.append((nm, a, wp[c]))
        else:
            p = parent.get(nm)
            dirn = (a - wp[p]) if p else np.array([0, 0.05, 0])
            n = np.linalg.norm(dirn)
            dirn = dirn / n * min(max(n * 0.6, 0.02), 0.08) if n > 1e-6 else np.array([0, 0.03, 0])
            segs.append((nm, a, a + dirn))
    # the weights are found on the mesh's unique positions (a vertex is split
    # along a texture seam, and the two copies must move as one or the seam
    # opens into a crack)
    upos, inv = np.unique(np.round(npos, 5), axis=0, return_inverse=True)
    inv = inv.reshape(-1)
    D = np.stack([seg_dist(upos, a, bb) for _, a, bb in segs], 1)   # (unique, segs)
    seg_bone = [sg[0] for sg in segs]
    # the distance to a bone = its nearest segment
    bone_names = [nm for nm in order if parent.get(nm) is not None]
    bd = np.full((len(upos), len(bone_names)), np.inf)
    for si, nm in enumerate(seg_bone):
        k = bone_names.index(nm)
        bd[:, k] = np.minimum(bd[:, k], D[:, si])
    # the hips' bone (hips to spine) is the pelvis: a little wider than a
    # line, so the seat and the belly don't go to the thighs
    nearest = bd.min(1, keepdims=True)
    w = np.where(bd <= nearest * args.reach, 1.0 / np.maximum(bd, 0.004) ** 3, 0.0)
    # keep the strongest few
    top = np.argsort(-w, axis=1)[:, :args.bones]
    keep = np.zeros_like(w, dtype=bool)
    np.put_along_axis(keep, top, True, axis=1)
    w = np.where(keep, w, 0.0)
    w /= w.sum(1, keepdims=True)
    # smoothing over the mesh's edges (vertex neighbours), a few passes
    uidx = inv[nidx]
    e0 = np.concatenate([uidx[:, 0], uidx[:, 1], uidx[:, 2], uidx[:, 1], uidx[:, 2], uidx[:, 0]])
    e1 = np.concatenate([uidx[:, 1], uidx[:, 2], uidx[:, 0], uidx[:, 0], uidx[:, 1], uidx[:, 2]])
    cnt = np.zeros(len(upos))
    np.add.at(cnt, e0, 1.0)
    for _ in range(args.smooth):
        avg = np.zeros_like(w)
        np.add.at(avg, e0, w[e1])
        avg /= np.maximum(cnt[:, None], 1.0)
        w = 0.5 * w + 0.5 * avg
        top = np.argsort(-w, axis=1)[:, :args.bones]
        keep = np.zeros_like(w, dtype=bool)
        np.put_along_axis(keep, top, True, axis=1)
        w = np.where(keep, w, 0.0)
        w /= np.maximum(w.sum(1, keepdims=True), 1e-9)
    w = w[inv]   # back onto every vertex, seam copies alike
    top = np.argsort(-w, axis=1)[:, :4]
    tw = np.take_along_axis(w, top, axis=1)
    tw /= np.maximum(tw.sum(1, keepdims=True), 1e-9)
    print("weights: %d bones; a vertex blends %.2f bones on average" % (len(bone_names), (tw > 0.01).sum(1).mean()))
    for nm in ["Hips", "Spine2", "Head", "LeftArm", "LeftForeArm", "LeftHand", "LeftUpLeg", "LeftLeg", "LeftFoot"]:
        if nm in bone_names:
            k = bone_names.index(nm)
            print("  %-12s at %s, %5d vertices mostly its" % (nm, np.round(wp[nm], 3), int((top[:, 0] == k).sum())))

    # ---- write: the new model's json with its mesh re-skinned and a new skeleton
    j = json.loads(json.dumps(nj))
    nodes = [{"name": "Character", "mesh": j["nodes"][mn]["mesh"], "skin": 0}]
    node_of = {}
    for nm in order:
        node_of[nm] = len(nodes)
        nd = {"name": nm}
        p = parent.get(nm)
        off = wp[nm] - (wp[p] if p else np.zeros(3))
        nd["translation"] = [float(x) for x in off]
        nodes.append(nd)
    for nm in order:
        ch = [node_of[c] for c in kids[nm]]
        if ch:
            nodes[node_of[nm]]["children"] = ch
    roots = [node_of[nm] for nm in order if parent.get(nm) is None]
    nodes[0]["children"] = roots
    j["nodes"] = nodes
    j["scenes"] = [{"nodes": [0]}]
    j["scene"] = 0
    j.pop("animations", None)
    # buffers: keep the old binary (images, indices, uvs, normals) and append new accessors
    bins = bytearray(nb)
    views = j["bufferViews"]
    accs = j["accessors"]

    def add(arr, ctype, atype, target=None, minmax=False):
        data = np.ascontiguousarray(arr).tobytes()
        while len(bins) % 4:
            bins.append(0)
        views.append({"buffer": 0, "byteOffset": len(bins), "byteLength": len(data)} | ({"target": target} if target else {}))
        bins.extend(data)
        a = {"bufferView": len(views) - 1, "componentType": ctype, "count": int(arr.shape[0]), "type": atype}
        if minmax:
            a["min"] = [float(x) for x in arr.min(0)]
            a["max"] = [float(x) for x in arr.max(0)]
        accs.append(a)
        return len(accs) - 1
    skin_order = order   # skin joint k = order[k]
    jn = np.array([[skin_order.index(bone_names[t]) for t in row] for row in top], np.uint8)
    npr["attributes"]["POSITION"] = add(npos.astype(np.float32), 5126, "VEC3", 34962, True)
    npr["attributes"]["JOINTS_0"] = add(jn, 5121, "VEC4", 34962)
    npr["attributes"]["WEIGHTS_0"] = add(tw.astype(np.float32), 5126, "VEC4", 34962)
    j["meshes"][j["nodes"][0]["mesh"]]["primitives"] = [npr]
    ibms = np.stack([np.eye(4) for _ in skin_order])
    for k, nm in enumerate(skin_order):
        ibms[k, :3, 3] = -wp[nm]
    ibm = add(ibms.transpose(0, 2, 1).reshape(-1, 16).astype(np.float32), 5126, "MAT4")
    j["skins"] = [{"name": "skin", "joints": [node_of[nm] for nm in skin_order], "inverseBindMatrices": ibm}]
    j["buffers"] = [{"byteLength": len(bins)}]
    j["asset"] = {"version": "2.0", "generator": "covenant-war reskin.py on " + nj.get("asset", {}).get("generator", "?")}
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(bins) % 4:
        bins.append(0)
    with open(args.out, "wb") as f:
        total = 12 + 8 + len(js) + 8 + len(bins)
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(bins), 0x004E4942))
        f.write(bytes(bins))
    print("wrote", args.out, "%d KB" % (os.path.getsize(args.out) // 1024))


if __name__ == "__main__":
    main()
