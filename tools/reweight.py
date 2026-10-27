"""Gives a game model better skin weights, copied from another model of the
same skeleton that was skinned properly (the one it replaced), instead of
the by-distance weights reskin.py makes:

  python3 tools/reweight.py CUR.glb REF.glb OUT.glb [--smooth 2] [--bones 4]

CUR is a finished game model (assets/models/characters/<id>.glb: the standard
skeleton, square to the world, feet at y=0, with its clips) whose weights are
poor; REF is a game model of the same build with the weights to copy (the 17
October Player A under his 26 October mesh, the 20 October Bram under his).
Everything in CUR stays as it is (mesh, skeleton, clips, textures); only
JOINTS_0 and WEIGHTS_0 are made again:

  - each vertex of CUR looks for its counterpart on REF's surface, among the
    bones that could reasonably hold it (the nearest few by distance to the
    bones, as reskin.py found them): for each such bone the vertex is moved
    by that joint's offset between the two skeletons (CUR's hands hang closer
    to his sides than REF's) and the nearest REF vertex that bone mostly holds
    is found; the counterpart is the match with the least distance left over,
    and near-ties are blended;
  - the counterpart's weights become the vertex's (the face is all Head, as
    REF's face was; a hand stays a hand), then a couple of smoothing passes
    over the mesh soften the blends at the joints, seam copies alike.

A vertex no REF bone has a vertex for (REF has fewer fingers, say) keeps the
by-distance weights CUR already has.

With --refit-joints the skeleton is fitted again from those weights: each
joint sits where REF's did, moved by how far the flesh that bone holds moved
between the two meshes (reskin.py put Player A's wrists 4 cm outside his
hands, so his hands hung inside his thighs); sideways and front-to-back for
the body and the legs (the feet stay on the ground and the hips at their
height), in every direction for the arms, the neck and the head. The weights
are then found once more from the fitted skeleton. The clips are untouched
(local turns and the hips' path), and every bind matrix is rewritten.
"""
import argparse, json, os, struct, sys
import numpy as np
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc, Rig, standard_names, CANON  # noqa: E402


def mesh_of(j, b):
    mesh_nodes = [i for i, n in enumerate(j["nodes"]) if "mesh" in n]
    assert len(mesh_nodes) == 1, "expected one mesh"
    mn = mesh_nodes[0]
    prims = j["meshes"][j["nodes"][mn]["mesh"]]["primitives"]
    assert len(prims) == 1, "expected one primitive"
    pr = prims[0]
    pos = acc(j, b, pr["attributes"]["POSITION"]).astype(np.float64)
    idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
    jn = acc(j, b, pr["attributes"]["JOINTS_0"]).astype(np.int64)
    w = acc(j, b, pr["attributes"]["WEIGHTS_0"]).astype(np.float64)
    return mn, pr, pos, idx, jn, w


def seg_dist(p, a, bb):
    ab = bb - a
    L2 = max(float(ab @ ab), 1e-12)
    t = np.clip(((p - a) @ ab) / L2, 0.0, 1.0)
    q = a + t[:, None] * ab
    return np.linalg.norm(p - q, axis=1)


def skeleton(path):
    j, b = load(path)
    rig = Rig(j, b)
    names = standard_names(rig)
    skin = j["skins"][0]["joints"]
    skin_names = [names[i] for i in skin]
    wp = {names[i]: rig.wp[i] for i in rig.joints}
    parent = {}
    for i in rig.joints:
        p = rig.bone_parent(i)
        parent[names[i]] = names[p] if p is not None else None
    node_of = {names[i]: i for i in skin}
    return j, b, skin_names, wp, parent, node_of


def weights_from(c_skin, c_wp, c_parent, cpos, cidx, u_old, upos, inv, r_skin, r_wp, rpos, r_dense, trees, args):
    """The weights of CUR's unique positions, copied from REF (see the module doc)."""
    order = [nm for nm in CANON if nm in c_skin] + [nm for nm in c_skin if nm not in CANON]
    kids = {nm: [c for c in order if c_parent.get(c) == nm] for nm in order}
    segs = []
    for nm in order:
        if c_parent.get(nm) is None:
            continue
        a = c_wp[nm]
        if kids[nm]:
            for c in kids[nm]:
                segs.append((nm, a, c_wp[c]))
        else:
            p = c_parent.get(nm)
            dirn = (a - c_wp[p]) if p else np.array([0, 0.05, 0])
            n = np.linalg.norm(dirn)
            dirn = dirn / n * min(max(n * 0.6, 0.02), 0.08) if n > 1e-6 else np.array([0, 0.03, 0])
            segs.append((nm, a, a + dirn))
    bone_names = [nm for nm in order if c_parent.get(nm) is not None]
    bd = np.full((len(upos), len(bone_names)), np.inf)
    for nm, a, bb in segs:
        k = bone_names.index(nm)
        bd[:, k] = np.minimum(bd[:, k], seg_dist(upos, a, bb))
    nearest = bd.min(1)
    cand = np.argsort(bd, axis=1)[:, :args.cands]
    col = {nm: k for k, nm in enumerate(c_skin)}
    W = np.zeros((len(upos), len(c_skin)))
    matched = np.zeros(len(upos), bool)
    resid = np.full(len(upos), np.inf)
    # one query per candidate bone, vectorised over the vertices that try it
    hits = [[] for _ in range(len(upos))]
    for ci in range(args.cands):
        for k, nm in enumerate(bone_names):
            if nm not in trees:
                continue
            vs = np.where((cand[:, ci] == k) & (bd[:, k] <= nearest * args.reach))[0]
            if len(vs) == 0:
                continue
            tree, sel = trees[nm]
            q = upos[vs] + (r_wp[nm] - c_wp[nm])
            r, ii = tree.query(q)
            for v, rr, i in zip(vs, r, ii):
                hits[v].append((rr, sel[i]))
    for v in range(len(upos)):
        if not hits[v]:
            continue
        hits[v].sort()
        r0 = hits[v][0][0]
        tot = np.zeros(len(c_skin))
        for rr, ri in hits[v]:
            if rr > r0 + args.tie:
                break
            g = np.exp(-((rr - r0) / args.tie) ** 2)
            for k, nm in enumerate(r_skin):
                if nm in col and r_dense[ri, k] > 0:
                    tot[col[nm]] += g * r_dense[ri, k]
        if tot.sum() > 0:
            W[v] = tot / tot.sum()
            matched[v] = True
            resid[v] = r0
    W[~matched] = u_old[~matched]
    print("matched %d of %d positions (%.1f%%); residual median %.1f mm, 95%% %.1f mm, worst %.1f mm" % (
        matched.sum(), len(upos), 100.0 * matched.mean(), np.median(resid[matched]) * 1000,
        np.percentile(resid[matched], 95) * 1000, resid[matched].max() * 1000))

    def keep_top(w):
        top = np.argsort(-w, axis=1)[:, :args.bones]
        keep = np.zeros_like(w, dtype=bool)
        np.put_along_axis(keep, top, True, axis=1)
        w = np.where(keep, w, 0.0)
        return w / np.maximum(w.sum(1, keepdims=True), 1e-9)
    W = keep_top(W)
    uidx = inv[cidx]
    e0 = np.concatenate([uidx[:, 0], uidx[:, 1], uidx[:, 2], uidx[:, 1], uidx[:, 2], uidx[:, 0]])
    e1 = np.concatenate([uidx[:, 1], uidx[:, 2], uidx[:, 0], uidx[:, 0], uidx[:, 1], uidx[:, 2]])
    cnt = np.zeros(len(upos))
    np.add.at(cnt, e0, 1.0)
    for _ in range(args.smooth):
        avg = np.zeros_like(W)
        np.add.at(avg, e0, W[e1])
        avg /= np.maximum(cnt[:, None], 1.0)
        W = keep_top(0.5 * W + 0.5 * avg)
    return W


ARM_BONES = set()
for _s in ["Left", "Right"]:
    ARM_BONES |= {_s + "Shoulder", _s + "Arm", _s + "ForeArm", _s + "Hand"}
    for _f in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
        ARM_BONES |= {"%sHand%s%d" % (_s, _f, k) for k in (1, 2, 3)}
FREE_Y = ARM_BONES | {"Neck", "Head"}


def refit_joints(c_skin, c_wp, c_parent, Wd, upos, r_skin, r_wp, rpos, r_dense):
    """Each joint where REF's is, moved by how far the blend between its bone and
    its parent's (the ring of flesh round the joint) moved between the two meshes
    (Wd: CUR's dense weights on upos)."""
    order = [nm for nm in CANON if nm in c_skin] + [nm for nm in c_skin if nm not in CANON]
    ccol = {nm: k for k, nm in enumerate(c_skin)}
    rcol = {nm: k for k, nm in enumerate(r_skin)}
    off = {}
    out = {}
    for nm in order:
        p = c_parent.get(nm)
        d = None
        if p is not None and nm in rcol and nm in ccol and p in rcol and p in ccol:
            mc = (Wd[:, ccol[nm]] > 0.2) & (Wd[:, ccol[p]] > 0.2)
            mr = (r_dense[:, rcol[nm]] > 0.2) & (r_dense[:, rcol[p]] > 0.2)
            if mc.sum() >= 8 and mr.sum() >= 8:
                d = upos[mc].mean(0) - rpos[mr].mean(0)
        if d is not None:
            if nm not in FREE_Y:
                d = np.array([d[0], 0.0, d[2]])
            out[nm] = r_wp[nm] + d
            if nm not in FREE_Y:
                out[nm][1] = c_wp[nm][1]   # the body and the legs keep their heights
        elif p is not None and p in out:
            out[nm] = c_wp[nm] + (out[p] - c_wp[p])   # no ring of its own (a finger): moved with its parent
            d = out[nm] - r_wp[nm] if nm in r_wp else np.zeros(3)
        else:
            out[nm] = c_wp[nm].copy()   # the root, the hips: as they are
            d = np.zeros(3)
        off[nm] = d
    moved = {nm: np.linalg.norm(out[nm] - c_wp[nm]) for nm in order}
    big = sorted(moved.items(), key=lambda kv: -kv[1])[:6]
    print("joints refitted; moved most: " + ", ".join("%s %.0f mm" % (nm, m * 1000) for nm, m in big))
    for nm in ["Hips", "Spine2", "Neck", "Head", "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand", "LeftHandMiddle1", "LeftHandThumb1", "LeftUpLeg", "LeftLeg", "LeftFoot"]:
        if nm in out:
            print("  %-16s REF %s  now %s -> %s (ring offset %s)" % (nm, np.round(r_wp.get(nm, c_wp[nm]), 3), np.round(c_wp[nm], 3), np.round(out[nm], 3), np.round(off[nm], 3)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cur")
    ap.add_argument("ref")
    ap.add_argument("out")
    ap.add_argument("--bones", type=int, default=4, help="bones a vertex may blend")
    ap.add_argument("--cands", type=int, default=5, help="bones tried for each vertex")
    ap.add_argument("--reach", type=float, default=2.5, help="a bone further than this times the nearest bone's distance isn't tried")
    ap.add_argument("--smooth", type=int, default=2, help="smoothing passes over the mesh")
    ap.add_argument("--tie", type=float, default=0.012, help="metres: matches this close to the best are blended in")
    ap.add_argument("--refit-joints", action="store_true", help="fit the skeleton again from the copied weights, then copy them once more")
    args = ap.parse_args()

    cj, cb, c_skin, c_wp, c_parent, c_node = skeleton(args.cur)
    rj, rb, r_skin, r_wp, r_parent, _ = skeleton(args.ref)
    _, cpr, cpos, cidx, cjn, cw = mesh_of(cj, cb)
    _, rpr, rpos, ridx, rjn, rw = mesh_of(rj, rb)
    c_h = cpos[:, 1].max() - cpos[:, 1].min()
    r_h = rpos[:, 1].max() - rpos[:, 1].min()
    s = c_h / r_h
    rpos = rpos * s
    r_wp = {nm: p * s for nm, p in r_wp.items()}
    # REF centred where CUR is (side to side, front to back)
    cc = (cpos.min(0) + cpos.max(0)) * 0.5
    rc = (rpos.min(0) + rpos.max(0)) * 0.5
    shift = np.array([cc[0] - rc[0], 0.0, cc[2] - rc[2]])
    rpos = rpos + shift
    r_wp = {nm: p + shift for nm, p in r_wp.items()}
    print("CUR %s: %d vertices at %.2f m; REF %s: %d vertices, scaled by %.3f" % (
        os.path.basename(args.cur), len(cpos), c_h, os.path.basename(args.ref), len(rpos), s))

    # REF's weights, dense, by bone name
    r_dense = np.zeros((len(rpos), len(r_skin)))
    for k in range(rjn.shape[1]):
        np.add.at(r_dense, (np.arange(len(rpos)), rjn[:, k]), rw[:, k])
    r_dom = r_dense.argmax(1)
    trees = {}
    for k, nm in enumerate(r_skin):
        sel = np.where(r_dom == k)[0]
        if len(sel) >= 4:
            trees[nm] = (cKDTree(rpos[sel]), sel)

    upos, inv = np.unique(np.round(cpos, 5), axis=0, return_inverse=True)
    inv = inv.reshape(-1)
    # the weights CUR has now, dense on the unique positions (the fallback)
    c_dense = np.zeros((len(cpos), len(c_skin)))
    for k in range(cjn.shape[1]):
        np.add.at(c_dense, (np.arange(len(cpos)), cjn[:, k]), cw[:, k])
    first = np.full(len(upos), -1)
    for vi, ui in enumerate(inv):
        if first[ui] < 0:
            first[ui] = vi
    u_old = c_dense[first]
    col = {nm: k for k, nm in enumerate(c_skin)}

    W = weights_from(c_skin, c_wp, c_parent, cpos, cidx, u_old, upos, inv, r_skin, r_wp, rpos, r_dense, trees, args)
    new_wp = None
    if args.refit_joints:
        new_wp = refit_joints(c_skin, c_wp, c_parent, W, upos, r_skin, r_wp, rpos, r_dense)
        W = weights_from(c_skin, new_wp, c_parent, cpos, cidx, u_old, upos, inv, r_skin, r_wp, rpos, r_dense, trees, args)
    W = W[inv]
    top = np.argsort(-W, axis=1)[:, :4]
    tw = np.take_along_axis(W, top, axis=1)
    tw /= np.maximum(tw.sum(1, keepdims=True), 1e-9)
    print("a vertex blends %.2f bones on average" % (tw > 0.01).sum(1).mean())
    for nm in ["Hips", "Spine2", "Neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "LeftUpLeg", "LeftLeg", "LeftFoot"]:
        if nm in col:
            print("  %-12s %5d vertices mostly its" % (nm, int((top[:, 0] == col[nm]).sum())))

    # write: the same file with two accessors replaced
    bins = bytearray(cb)
    views = cj["bufferViews"]
    accs = cj["accessors"]

    def add(arr, ctype, atype, target=None):
        data = np.ascontiguousarray(arr).tobytes()
        while len(bins) % 4:
            bins.append(0)
        views.append({"buffer": 0, "byteOffset": len(bins), "byteLength": len(data)} | ({"target": target} if target else {}))
        bins.extend(data)
        accs.append({"bufferView": len(views) - 1, "componentType": ctype, "count": int(arr.shape[0]), "type": atype})
        return len(accs) - 1
    jn = top.astype(np.uint8 if len(c_skin) < 256 else np.uint16)
    cpr["attributes"]["JOINTS_0"] = add(jn, 5121 if jn.dtype == np.uint8 else 5123, "VEC4", 34962)
    cpr["attributes"]["WEIGHTS_0"] = add(tw.astype(np.float32), 5126, "VEC4", 34962)
    if new_wp is not None:
        # the skeleton moved: every joint's local translation and bind matrix again
        for nm in c_skin:
            p = c_parent.get(nm)
            loc = new_wp[nm] - (new_wp[p] if p is not None else np.zeros(3))
            cj["nodes"][c_node[nm]]["translation"] = [float(x) for x in loc]
        ibms = np.stack([np.eye(4) for _ in c_skin])
        for k, nm in enumerate(c_skin):
            ibms[k, :3, 3] = -new_wp[nm]
        cj["skins"][0]["inverseBindMatrices"] = add(ibms.transpose(0, 2, 1).reshape(-1, 16).astype(np.float32), 5126, "MAT4")
    cj["buffers"] = [{"byteLength": len(bins)}]
    gen = cj.get("asset", {}).get("generator", "?")
    cj["asset"] = {"version": "2.0", "generator": "covenant-war reweight.py on " + gen}
    js = json.dumps(cj, separators=(",", ":")).encode()
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
