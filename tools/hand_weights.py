#!/usr/bin/env python3
"""Gives a model's fingers skin weights that open cleanly (8 November, Gary:
"Players hand distort really bad when Bram hands you box").

Player A's Tripo3D rig put his finger joints in a jumble within a centimetre
or two of the knuckles, and his finger skin is weighted across them and the
hand bone in patches (a vertex half way along a finger 52 to 90% on the
finger bones, its neighbour 100%). Kept at rest (Figure3D.FROZEN) that never
shows: the fingers go with the hand. But a flat hand under the card box opens
them (Figure3D.OPEN_FLAT: each finger turned at its root about the knuckle
line), and every vertex with part of its weight left on the hand moved only
part of the way: at 70 degrees the skin stretched to 3.7 times its length,
132 of the left hand's triangles over 1.6 times.

Here every finger's share of each vertex (the four fingers' bones together)
goes to the middle finger's root, so the fingers turn as one block about one
pivot, and how much of a vertex is finger is set by where it is: none behind
`--blend` D0 (cm, along the hand from the knuckles; negative is towards the
wrist), all past D1, smoothly between, so the skin bends across the knuckles
instead of tearing along the fingers. The thumb's share is the thumb's own
weight, smoothed over the mesh (`--smooth` passes), all to the thumb's root.
The forearm's share of a vertex is left as it was; nothing else in the model
changes. At rest it looks exactly as before (the fingers are kept at rest
everywhere else), so only the opened hand is different.

    python3 tools/hand_weights.py assets/models/characters/player_a.glb            # report
    python3 tools/hand_weights.py assets/models/characters/player_a.glb --fix      # mend it in place
    python3 tools/hand_weights.py MODEL.glb --try 45,0      # report the stretch at that opening
         [--blend -1.5,2.0] [--smooth 4] [--side Left|Right]

The report: each hand's triangles' edge stretch with the fingers opened
(and the thumb turned) as Figure3D.OPEN_FLAT does, before and after.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from arm_weights import read_glb, write_glb, view   # noqa: E402

FINGERS = ("Index", "Middle", "Ring", "Pinky")


def _rot(axis, ang):
    axis = axis / np.linalg.norm(axis)
    x, y, z = axis
    c, s = np.cos(ang), np.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


class Hands:
    def __init__(self, j, binc):
        self.j, self.binc = j, binc
        skin = j["skins"][0]
        self.joints = skin["joints"]
        self.names = [j["nodes"][k].get("name", "") for k in self.joints]
        ibm, _, _ = view(j, binc, skin["inverseBindMatrices"])
        self.bind = [np.linalg.inv(np.array(m, dtype=float).reshape(4, 4).T) for m in ibm]
        self.pos = {n: self.bind[i][:3, 3] for i, n in enumerate(self.names)}
        parent = {}
        for i, n in enumerate(j["nodes"]):
            for c in n.get("children", []):
                parent[c] = i
        jidx = {k: i for i, k in enumerate(self.joints)}
        self.parent = []
        for k in self.joints:
            q = k
            p = -1
            while q in parent:
                q = parent[q]
                if q in jidx:
                    p = jidx[q]
                    break
            self.parent.append(p)

    def idx(self, name):
        return self.names.index(name) if name in self.names else -1

    def frame(self, side):
        """The hand's frame as Figure3D reads it: the knuckle (the middle finger's root),
        the fingers' way f, the palm's way p, the knuckle line a."""
        pre = side + "Hand"
        wrist = self.pos[pre]
        kn = self.pos[pre + "Middle1"]
        f = kn - wrist
        f /= np.linalg.norm(f)
        pk = pre + "Pinky1" if pre + "Pinky1" in self.pos else pre + "Ring1"
        across = self.pos[pre + "Index1"] - self.pos[pk]
        p = np.cross(across, f) if side == "Right" else np.cross(f, across)
        p = p - f * p.dot(f)
        p /= np.linalg.norm(p)
        a = np.cross(p, f)
        return kn, f, p, a / np.linalg.norm(a)

    def groups(self, side):
        pre = side + "Hand"
        fing = [i for i, n in enumerate(self.names) if n.startswith(pre) and n[len(pre):].startswith(FINGERS)]
        thumb = [i for i, n in enumerate(self.names) if n.startswith(pre + "Thumb")]
        return fing, thumb, self.idx(pre)

    def subtree(self, b):
        out = []
        for k in range(len(self.names)):
            q = k
            while q >= 0:
                if q == b:
                    out.append(k)
                    break
                q = self.parent[q]
        return out

    def opened(self, side, fingers_deg, thumb_deg):
        """Each bone's move (4x4, bind space) for OPEN_FLAT's turns at rest."""
        pre = side + "Hand"
        kn, f, p, a = self.frame(side)
        D = [np.eye(4) for _ in self.names]

        def turn(b, axis, ang):
            R = _rot(axis, ang)
            c = self.pos[self.names[b]]
            T = np.eye(4)
            T[:3, :3] = R
            T[:3, 3] = c - R @ c
            for k in self.subtree(b):
                D[k] = T @ D[k]
        for fn in FINGERS:
            b = self.idx(pre + fn + "1")
            if b >= 0 and fingers_deg:
                turn(b, a, np.radians(fingers_deg))
        b = self.idx(pre + "Thumb1")
        if b >= 0 and thumb_deg:
            turn(b, f, np.radians(thumb_deg) * (1.0 if side == "Left" else -1.0))
        return D


def _weld(pos):
    key = np.round(pos * 1e4).astype(np.int64)
    _, wid = np.unique(key, axis=0, return_inverse=True)
    return wid.ravel()


def stretch(h, side, pos, jn, w, tris, fingers_deg, thumb_deg):
    fing, thumb, hb = h.groups(side)
    grp = set(fing + thumb + [hb])
    D = h.opened(side, fingers_deg, thumb_deg)
    ph = np.c_[pos, np.ones(len(pos))]
    q = np.zeros_like(pos)
    for k in range(4):
        Dk = np.stack([D[x] for x in jn[:, k]])
        q += w[:, k:k + 1] * np.einsum("nij,nj->ni", Dk, ph)[:, :3]
    hv = np.zeros(len(pos), bool)
    for k in range(4):
        hv |= np.isin(jn[:, k], list(grp)) & (w[:, k] > 0.05)
    t = tris[hv[tris].any(1)]
    e0 = np.concatenate([np.linalg.norm(pos[t[:, i]] - pos[t[:, (i + 1) % 3]], axis=1) for i in range(3)])
    e1 = np.concatenate([np.linalg.norm(q[t[:, i]] - q[t[:, (i + 1) % 3]], axis=1) for i in range(3)])
    ok = e0 > 1e-4
    r = e1[ok] / e0[ok]
    return len(t), r


def reweight(h, side, pos, jn, w, tris, blend, smooth):
    fing, thumb, hb = h.groups(side)
    pre = side + "Hand"
    mid1 = h.idx(pre + "Middle1")
    th1 = h.idx(pre + "Thumb1")
    grp = set(fing + thumb + [hb])
    kn, fdir, _, _ = h.frame(side)
    sF = np.zeros(len(pos))
    sT = np.zeros(len(pos))
    G = np.zeros(len(pos))
    for k in range(4):
        sF += np.where(np.isin(jn[:, k], fing), w[:, k], 0.0)
        sT += np.where(np.isin(jn[:, k], thumb), w[:, k], 0.0)
        G += np.where(np.isin(jn[:, k], list(grp)), w[:, k], 0.0)
    hv = G > 1e-4
    wid = _weld(pos)
    nw = wid.max() + 1
    # the thumb's share of the hand's weight, smoothed over the welded mesh
    t = np.where(hv, sT / np.maximum(G, 1e-6), 0.0)
    tw = np.bincount(wid, weights=t, minlength=nw) / np.maximum(np.bincount(wid, minlength=nw), 1)
    e = np.concatenate([tris[:, [0, 1]], tris[:, [1, 2]], tris[:, [2, 0]]])
    we = wid[e]
    cnt = np.bincount(we[:, 0], minlength=nw) + np.bincount(we[:, 1], minlength=nw)
    for _ in range(smooth):
        s = np.bincount(we[:, 0], weights=tw[we[:, 1]], minlength=nw) + np.bincount(we[:, 1], weights=tw[we[:, 0]], minlength=nw)
        tw = np.where(cnt > 0, 0.5 * tw + 0.5 * s / np.maximum(cnt, 1), tw)
    t = np.clip(tw[wid], 0.0, 1.0)
    # the fingers' share by where the vertex is along the hand past the knuckles
    d = (pos - kn) @ fdir
    f = np.clip((d - blend[0]) / (blend[1] - blend[0]), 0.0, 1.0)
    f = f * f * (3.0 - 2.0 * f)
    # (the fingers first: where the thumb's smoothed share runs on into the
    # fingers, a finger vertex left part thumb moved only part of the way)
    t = np.minimum(t, 1.0 - f)
    hand = 1.0 - f - t
    nj = jn.copy()
    nwt = w.copy()
    for v in np.where(hv)[0]:
        keep = [(int(jn[v, k]), float(w[v, k])) for k in range(4) if int(jn[v, k]) not in grp and w[v, k] > 0.0]
        new = keep + [(hb, G[v] * hand[v]), (mid1, G[v] * f[v]), (th1, G[v] * t[v])]
        new = sorted([x for x in new if x[1] > 1e-5], key=lambda x: -x[1])[:4]
        tot = sum(x[1] for x in new)
        new = [(a, b / tot) for a, b in new] + [(0, 0.0)] * (4 - len(new))
        nj[v] = [a for a, _ in new]
        nwt[v] = [b for _, b in new]
    return nj, nwt, int(hv.sum())


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = sys.argv[1:]
    path = args[0]

    def opt(name, default):
        if name in flags:
            return flags[flags.index(name) + 1]
        return default
    fix = "--fix" in flags
    tries = [tuple(float(x) for x in opt("--try", "45,0").split(","))]
    if "--try" not in flags:
        tries = [(45.0, 0.0), (70.0, -60.0)]
    blend = tuple(float(x) / 100.0 for x in opt("--blend", "-1.5,2.0").split(","))
    smooth = int(opt("--smooth", "4"))
    sides = [opt("--side", "")] if "--side" in flags else ["Left", "Right"]
    j, binc, _ = read_glb(path)
    h = Hands(j, binc)
    changed = 0
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            at = prim["attributes"]
            if "JOINTS_0" not in at or "indices" not in prim:
                continue
            pos, _, _ = view(j, binc, at["POSITION"])
            pos = pos.astype(float)
            jn_v, _, _ = view(j, binc, at["JOINTS_0"])
            w_v, wstart, wacc = view(j, binc, at["WEIGHTS_0"])
            assert wacc["componentType"] == 5126, "weights aren't floats"
            jn = jn_v.astype(int)
            w = w_v.astype(float)
            w = w / np.maximum(w.sum(1, keepdims=True), 1e-9)
            tris, _, _ = view(j, binc, prim["indices"])
            tris = tris.reshape(-1, 3).astype(int)
            nj, nw = jn, w
            for side in sides:
                if h.idx(side + "HandMiddle1") < 0:
                    print(f"{side}: no middle finger root, left alone")
                    continue
                before = [(fa, ta, stretch(h, side, pos, jn, w, tris, fa, ta)) for fa, ta in tries]
                nj, nw, nv = reweight(h, side, pos, nj, nw, tris, blend, smooth)
                after = [(fa, ta, stretch(h, side, pos, nj, nw, tris, fa, ta)) for fa, ta in tries]
                print(f"{side} hand: {nv} vertices")
                for (fa, ta, (n, r0)), (_, _, (_, r1)) in zip(before, after):
                    print(f"  fingers {fa:.0f}, thumb {ta:.0f}: {n} triangles; edge stretch "
                          f"max {r0.max():.2f} -> {r1.max():.2f}, 99% under {np.percentile(r0, 99):.2f} -> {np.percentile(r1, 99):.2f}, "
                          f"over 1.3x {(r0 > 1.3).sum()} -> {(r1 > 1.3).sum()}, over 1.6x {(r0 > 1.6).sum()} -> {(r1 > 1.6).sum()}")
            if fix and nj is not jn:
                jdtype = jn_v.dtype
                if nj.max() > np.iinfo(jdtype).max:
                    raise SystemExit("joint index too big for the model's JOINTS_0")
                jn_v_w = np.frombuffer(binc, dtype=jn_v.dtype, count=jn_v.size, offset=view(j, binc, at["JOINTS_0"])[1])
                jn_v_w[:] = nj.astype(jdtype).ravel()
                w_w = np.frombuffer(binc, dtype=np.float32, count=w_v.size, offset=wstart)
                w_w[:] = nw.astype(np.float32).ravel()
                changed += 1
    if fix:
        write_glb(path, j, binc)
        print(f"written: {path} ({changed} primitive(s))")


if __name__ == "__main__":
    main()
