#!/usr/bin/env python3
"""The child's small hand in the Night of the White Sky's walk out
(16 November, Gary: "When baby hand reaches for card hand doesn't look very
real"). Until then it was put together in the game out of round shapes: a
ball for a palm, one stiff capsule for each finger, so the fingers could only
bend at the knuckle, and the joins showed.

This makes it as one smooth skin over a skeleton, the way a body is made:

  * the shape is a distance field (a palm with the soft pads of a baby's
    hand, a fat crease round the wrist, dimples over the knuckles, short
    plump fingers in three joints each, a thumb in three), each finger
    blended into the palm but kept apart from its neighbours, polygonised
    with marching cubes and given normals from the field itself, so it is
    smooth all over;
  * every bone of it has its own part of the skin (Forearm, Hand, Index1-3,
    Middle1-3, Ring1-3, Little1-3, Thumb1-3), the joints blended, so the
    fingers curl round a joint as fingers do;
  * the vertex colour carries what the game's skin shader needs: how pink
    (the fingertips, the knuckles, the palm), the nails, and the creases;
  * a sleeve of the blanket's cream wool over the forearm (its own surface,
    a rolled cuff and soft folds; the knit and the cuff's ribs are drawn by
    the game's wool shader from its UV: u round it, v down it in 5 cm), so
    the hand comes out of something, not out of nothing.

The hand's own frame: the wrist at the origin, the fingers up +y, the palm
facing +z, the thumb towards -x (the child's left hand, its back to a camera
behind). It is a little bigger than a newborn's (SCALE), as the old one was,
so it reads at the size it's seen.

    python3 tools/make_small_hand.py [out.glb]

writes assets/models/whitesky/small_hand.glb (WhiteSky._make_tiny_hand
loads it). numpy and scikit-image.
"""

import json
import math
import struct
import sys

import numpy as np
from skimage import measure

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/models/whitesky/small_hand.glb"
GRID = 0.0012          # the marching cubes' step (m)

# ----------------------------------------------------------------- helpers ---


def norm(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def smin(a, b, k):
    """polynomial smooth minimum (iq)"""
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def round_cone(p, a, b, r1, r2):
    """distance to a cone with round ends from a (radius r1) to b (r2)"""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    ba = b - a
    l2 = ba.dot(ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = p - a
    y = pa @ ba
    z = y - l2
    q = pa * l2 - np.outer(y, ba)
    x2 = np.einsum("ij,ij->i", q, q)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    d1 = np.sqrt(x2 + z2) * il2 - r2
    d2 = np.sqrt(x2 + y2) * il2 - r1
    d3 = (np.sqrt(np.maximum(x2 * a2 * il2, 0.0)) + y * rr) * il2 - r1
    return np.where(np.sign(z) * a2 * z2 > k, d1, np.where(np.sign(y) * a2 * y2 < k, d2, d3))


def ellipsoid(p, c, r):
    q = (p - np.asarray(c)) / np.asarray(r)
    k0 = np.linalg.norm(q, axis=1)
    k1 = np.linalg.norm(q / np.asarray(r), axis=1)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def sphere(p, c, r):
    return np.linalg.norm(p - np.asarray(c), axis=1) - r


def torus_y(p, c, R, r):
    q = p - np.asarray(c)
    xz = np.sqrt(q[:, 0] ** 2 + q[:, 2] ** 2) - R
    return np.sqrt(xz * xz + q[:, 1] ** 2) - r


def round_box(p, c, b, r):
    q = np.abs(p - np.asarray(c)) - (np.asarray(b) - r)
    return np.linalg.norm(np.maximum(q, 0.0), axis=1) + np.minimum(q.max(axis=1), 0.0) - r


# --------------------------------------------------------------- the hand ---
# (lengths in metres, about 1.35 times a newborn's: the old hand's size)

def frame(d, curl):
    """a bone's basis: y along it, z the way it curls, x = y cross z"""
    y = norm(d)
    c = np.asarray(curl, float)
    z = norm(c - y * y.dot(c))
    x = np.cross(y, z)
    return np.stack([x, y, z], axis=1)   # columns


FINGERS = [
    # name, knuckle, lean towards +x (rad), [lengths], (base r, tip r)
    ("Index", (-0.0132, 0.0436, 0.0), -0.19, [0.0150, 0.0095, 0.0088], (0.0060, 0.0049)),
    ("Middle", (-0.0044, 0.0457, 0.0), -0.05, [0.0165, 0.0105, 0.0092], (0.0062, 0.0050)),
    ("Ring", (0.0046, 0.0444, 0.0), 0.10, [0.0155, 0.0100, 0.0088], (0.0059, 0.0048)),
    ("Little", (0.0129, 0.0406, 0.0), 0.26, [0.0120, 0.0078, 0.0075], (0.0052, 0.0042)),
]
THUMB_AT = np.array([-0.0118, 0.0112, 0.0036])
THUMB = [   # direction, length, (r start, r end)
    ((-0.62, 0.62, 0.48), 0.0140, (0.0076, 0.0068)),
    ((-0.45, 0.80, 0.40), 0.0118, (0.0066, 0.0061)),
    ((-0.28, 0.90, 0.32), 0.0104, (0.0060, 0.0049)),
]
THUMB_CURL = (0.55, 0.0, 0.85)

# bones: name -> [parent, origin (hand frame), basis]
BONES = {}
BONES["Forearm"] = [None, np.array([0.0, -0.075, 0.0]), np.eye(3)]
BONES["Hand"] = ["Forearm", np.zeros(3), np.eye(3)]
# primitives: [bone, chain, kind, args]
SEGS = []           # [bone, chain, a, b, r1, r2] round cones of the digits
for name, at, lean, lens, (rb, rt) in FINGERS:
    d = np.array([math.sin(lean), math.cos(lean), 0.0])
    basis = frame(d, (0, 0, 1))
    p = np.array(at, float)
    total = sum(lens)
    run = 0.0
    parent = "Hand"
    for i, ln in enumerate(lens):
        bn = "%s%d" % (name, i + 1)
        BONES[bn] = [parent, p.copy(), basis]
        q = p + d * ln
        r1 = rb + (rt - rb) * run / total
        run += ln
        r2 = rb + (rt - rb) * run / total
        if i == 2:
            # (the tip's end: rounded off at its own radius, the pad full)
            q = p + d * (ln - r2 * 0.55)
        SEGS.append([bn, name, p.copy(), q.copy(), r1, r2])
        p = p + d * ln
        parent = bn
p = THUMB_AT.copy()
parent = "Hand"
for i, (dv, ln, (r1, r2)) in enumerate(THUMB):
    d = norm(dv)
    bn = "Thumb%d" % (i + 1)
    BONES[bn] = [parent, p.copy(), frame(d, THUMB_CURL)]
    q = p + d * ln
    if i == 2:
        q = p + d * (ln - r2 * 0.55)
    SEGS.append([bn, "Thumb", p.copy(), q.copy(), r1, r2])
    p = p + d * ln
    parent = bn
CHAINS = [f[0] for f in FINGERS] + ["Thumb"]


def palm_parts(p):
    """the palm's own shapes: [(bone, distance)]"""
    # (narrower at the wrist than across the knuckles)
    t = np.clip((p[:, 1] - 0.004) / 0.040, 0.0, 1.0)
    sx = 0.84 + 0.16 * t
    ps = p.copy()
    ps[:, 0] = (p[:, 0] - 0.0004) / sx
    body = round_box(ps, (0.0, 0.0262, 0.0), (0.0187, 0.0206, 0.0079), 0.0072) * sx
    thenar = ellipsoid(p, (-0.0102, 0.0168, 0.0048), (0.0104, 0.0150, 0.0076))
    hypo = ellipsoid(p, (0.0113, 0.0205, 0.0038), (0.0080, 0.0160, 0.0068))
    pads = round_cone(p, (-0.0150, 0.0410, 0.0040), (0.0138, 0.0385, 0.0036), 0.0060, 0.0055)
    # (the back of the hand a little rounder than a box)
    back = ellipsoid(p, (0.0004, 0.0270, -0.0012), (0.0185, 0.0200, 0.0082))
    palm = smin(smin(smin(smin(body, thenar, 0.005), hypo, 0.005), pads, 0.004), back, 0.004)
    # the forearm: plump, a little flat front to back, into the sleeve
    pf = p.copy()
    pf[:, 2] = p[:, 2] / 0.86
    arm = round_cone(pf, (0.0, -0.085, 0.0), (0.0, -0.002, 0.0), 0.0178, 0.0149) * 0.93
    return palm, arm


def field(p, parts=False):
    palm, arm = palm_parts(p)
    hand = smin(palm, arm, 0.0065)
    # the fat crease round the wrist (a baby's bracelet)
    hand = smax(hand, -torus_y(p, (0.0, 0.0012, 0.0006), 0.0158, 0.0011), 0.0014)
    chain_d = {}
    seg_d = []
    for bn, ch, a, b, r1, r2 in SEGS:
        d = round_cone(p, a, b, r1, r2)
        seg_d.append(d)
        chain_d[ch] = d if ch not in chain_d else smin(chain_d[ch], d, 0.0018)
    total = hand
    for ch in CHAINS:
        # (each digit blended into the palm, but not into its neighbours)
        k = 0.0055 if ch == "Thumb" else 0.0042
        total = np.minimum(total, smin(hand, chain_d[ch], k))
    # dimples over the knuckles (a baby's knuckles go in, not out)
    for name, at, lean, lens, rr in FINGERS:
        dp = sphere(p, (at[0] + 0.0004, at[1] - 0.0006, -0.0118), 0.0021)
        total = smax(total, -dp, 0.0016)
    if parts:
        return total, palm, arm, chain_d, seg_d
    return total


# ------------------------------------------------------ marching the field ---
lo = np.array([-0.040, -0.090, -0.020])
hi = np.array([0.030, 0.092, 0.028])
n = np.ceil((hi - lo) / GRID).astype(int) + 1
xs = [lo[i] + np.arange(n[i]) * GRID for i in range(3)]
X, Y, Z = np.meshgrid(xs[0], xs[1], xs[2], indexing="ij")
pts = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
vol = np.empty(pts.shape[0])
CH = 400000
for s in range(0, pts.shape[0], CH):
    vol[s:s + CH] = field(pts[s:s + CH])
vol = vol.reshape(n)
# (the forearm cut off well inside the sleeve)
vol[:, : int((-0.070 - lo[1]) / GRID), :] = 0.01
verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(GRID, GRID, GRID))
verts = verts + lo
print("hand: %d vertices, %d triangles" % (len(verts), len(faces)))

# normals from the field (smooth)
e = 0.00025
nrm = np.zeros_like(verts)
for i in range(3):
    dv = np.zeros(3)
    dv[i] = e
    nrm[:, i] = field(verts + dv) - field(verts - dv)
nrm /= np.linalg.norm(nrm, axis=1, keepdims=True)
# (wound so the front faces face out: glTF's front faces are counter-clockwise)
fa = verts[faces[:, 1]] - verts[faces[:, 0]]
fb = verts[faces[:, 2]] - verts[faces[:, 0]]
fn = np.cross(fa, fb)
if np.einsum("ij,ij->i", fn, nrm[faces[:, 0]]).mean() < 0:
    faces = faces[:, ::-1]

# --------------------------------------------------------------- weights ---
BONE_NAMES = list(BONES.keys())
BI = {b: i for i, b in enumerate(BONE_NAMES)}
_, palm_d, arm_d, chain_d, seg_d = field(verts, parts=True)
S = 0.0016
nv = len(verts)
W = np.zeros((nv, len(BONE_NAMES)))
# which digit a point belongs to (or none: the palm)
cd = np.stack([chain_d[c] for c in CHAINS], axis=1)
own = np.argmin(cd, axis=1)
near_digit = cd[np.arange(nv), own] < np.minimum(palm_d, arm_d) + 0.0015
W[:, BI["Hand"]] = np.exp(-np.maximum(palm_d, 0.0) / S)
W[:, BI["Forearm"]] = np.exp(-np.maximum(arm_d, 0.0) / S) * np.clip((-verts[:, 1] - 0.000) / 0.008, 0.0, 1.0) ** 1.0
# (the wrist itself: the hand's below the crease fades to the forearm's)
for (bn, ch, a, b, r1, r2), d in zip(SEGS, seg_d):
    mine = near_digit & (np.array(CHAINS)[own] == ch)
    W[:, BI[bn]] = np.where(mine, np.exp(-np.maximum(d, 0.0) / S), 0.0)
# the palm gives way to the digit along it
W[:, BI["Hand"]] *= np.where(near_digit, 0.55, 1.0)
W = np.maximum(W, 0.0)
top = np.argsort(-W, axis=1)[:, :4]
tw = np.take_along_axis(W, top, axis=1)
tw = np.where(tw < 1e-4, 0.0, tw)
tw /= np.maximum(tw.sum(axis=1, keepdims=True), 1e-9)
# (nothing left without a bone: the hand's)
bad = tw.sum(axis=1) < 0.5
top[bad, 0] = BI["Hand"]
tw[bad] = [1, 0, 0, 0]

# --------------------------------------------------------------- colour ---
# r: how pink, g: nail, b: crease, a: 1
col = np.zeros((nv, 4))
col[:, 3] = 1.0
for (bn, ch, a, b, r1, r2), d in zip(SEGS, seg_d):
    basis = BONES[bn][2]
    loc = (verts - a) @ basis          # x across, y along, z to the palm
    ln = np.linalg.norm(b - a)
    t = loc[:, 1] / ln
    on = (d < 0.0012) & (np.array(CHAINS)[own] == ch) & near_digit
    if bn.endswith("3"):
        # pink at the tips
        col[:, 0] = np.where(on, np.maximum(col[:, 0], np.clip((t - 0.15) / 0.7, 0, 1) * 0.75), col[:, 0])
        # the nail: on the back of the last joint, its outer two thirds
        rr = r1 + (r2 - r1) * np.clip(t, 0, 1)
        back = -loc[:, 2] / np.maximum(np.sqrt(loc[:, 0] ** 2 + loc[:, 2] ** 2), 1e-9)
        side = np.abs(loc[:, 0]) / np.maximum(rr, 1e-6)
        nail = (np.clip((t - 0.30) / 0.10, 0, 1) * np.clip((1.10 - t) / 0.12, 0, 1)
                * np.clip((back - 0.35) / 0.20, 0, 1) * np.clip((0.82 - side) / 0.15, 0, 1))
        col[:, 1] = np.where(on, np.maximum(col[:, 1], nail), col[:, 1])
    if not bn.startswith("Thumb") or bn != "Thumb1":
        # the crease across the palm side at the joint this bone starts at,
        # and a fainter one on its back
        jt = np.abs(loc[:, 1]) / 0.0009
        palm_side = np.clip(loc[:, 2] / np.maximum(r1, 1e-6), 0, 1)
        back_side = np.clip(-loc[:, 2] / np.maximum(r1, 1e-6), 0, 1)
        crease = np.clip(1.0 - jt, 0, 1) * (palm_side * 0.8 + back_side * 0.25)
        if bn.endswith("1") and not bn.startswith("Thumb"):
            # (the knuckle's: the palm's crease under the finger, a little up it)
            jt2 = np.abs(loc[:, 1] - 0.0045) / 0.0010
            crease = np.clip(1.0 - jt2, 0, 1) * palm_side * 0.7
            # pink over the knuckle
            knk = np.clip(1.0 - np.linalg.norm(loc - [0, 0.002, -r1], axis=1) / 0.006, 0, 1)
            col[:, 0] = np.maximum(col[:, 0], knk * 0.35 * (d < 0.004))
        col[:, 2] = np.maximum(col[:, 2], crease * (d < 0.002))
# the palm a little pinker, its two creases across it
palm_side = np.clip(verts[:, 2] / 0.008, 0, 1) * (palm_d < 0.001)
col[:, 0] = np.maximum(col[:, 0], palm_side * 0.28)
for c0, c1 in [((-0.019, 0.031), (0.006, 0.037)), ((-0.006, 0.028), (0.020, 0.024))]:
    a = np.array(c0)
    b = np.array(c1)
    ab = b - a
    t = np.clip(((verts[:, :2] - a) @ ab) / ab.dot(ab), 0, 1)
    dd = np.linalg.norm(verts[:, :2] - (a + np.outer(t, ab)), axis=1)
    col[:, 2] = np.maximum(col[:, 2], np.clip(1.0 - dd / 0.0009, 0, 1) * palm_side * 0.6)
# the wrist's crease, darker in its fold
wc = np.clip(1.0 - np.abs(verts[:, 1] - 0.0012) / 0.0016, 0, 1)
col[:, 2] = np.maximum(col[:, 2], wc * 0.55)

# ---------------------------------------------------------------- sleeve ---
# a tube of the blanket's cream wool over the forearm: a rolled cuff at its
# mouth, ribbed, then soft folds; open at the wrist end (its lip turned in
# against the skin) and running on down out of sight
SL_TOP = -0.0030
SL_BOT = -0.230
ring = 40
rows = 64
sv = []
suv = []
for j in range(rows + 1):
    v = j / rows
    y = SL_TOP + (SL_BOT - SL_TOP) * v
    for i in range(ring + 1):
        u = i / ring
        th = u * math.tau
        depth = SL_TOP - y
        R = 0.0212 + 0.0040 * min(1.0, max(0.0, (depth - 0.03) / 0.10))
        # the rolled cuff
        roll = math.exp(-((depth - 0.0045) / 0.0042) ** 2) * 0.0034
        # (the cuff's ribs are the wool shader's: WhiteSky.WOOL)
        rib = 0.0
        # soft folds further down
        fold = 0.0009 * math.sin(depth * 230.0 + 1.3 * math.sin(th * 2.0 + depth * 35.0) + 0.7 * math.sin(th * 5.0)) * min(1.0, depth / 0.035)
        fold += 0.0007 * math.sin(th * 3.0 + depth * 70.0 + 1.1 * math.sin(depth * 160.0)) * min(1.0, depth / 0.05)
        r = R + roll + rib + fold
        sv.append((r * math.sin(th), y, r * math.cos(th) * 0.92))
        suv.append((u, depth / 0.05))
# its lip, turned in to the skin at the mouth (inside first, then its rim)
lip = []
for k, (rk, dy) in enumerate([(0.0166, -0.0030), (0.0197, 0.0010)]):
    for i in range(ring + 1):
        th = i / ring * math.tau
        lip.append((rk * math.sin(th), SL_TOP + dy, rk * math.cos(th) * 0.92))
sv = np.array(sv)
suv = np.array(suv)
lipv = np.array(lip)
sverts = np.concatenate([lipv, sv])
suv = np.concatenate([np.array([(i / ring, -0.05 * (1 - k)) for k in range(2) for i in range(ring + 1)]), suv])
srows = rows + 1 + 2
sfaces = []
for j in range(srows - 1):
    for i in range(ring):
        a = j * (ring + 1) + i
        b = a + 1
        c = a + ring + 1
        d = c + 1
        sfaces += [(a, c, b), (b, c, d)]
sfaces = np.array(sfaces)
# normals (out of the tube)
snrm = np.zeros_like(sverts)
fa = sverts[sfaces[:, 1]] - sverts[sfaces[:, 0]]
fb = sverts[sfaces[:, 2]] - sverts[sfaces[:, 0]]
fn = np.cross(fa, fb)
for k in range(3):
    np.add.at(snrm, sfaces[:, k], fn)
# (the seam round the tube: both ends of each row the same normal)
for j in range(srows):
    a0 = j * (ring + 1)
    a1 = a0 + ring
    snrm[a0] = snrm[a1] = snrm[a0] + snrm[a1]
snrm /= np.maximum(np.linalg.norm(snrm, axis=1, keepdims=True), 1e-12)
radial = sverts.copy()
radial[:, 1] = 0.0
if np.einsum("ij,ij->i", snrm, radial).mean() < 0:
    sfaces = sfaces[:, ::-1]
    snrm = -snrm
print("sleeve: %d vertices, %d triangles" % (len(sverts), len(sfaces)))
s_joints = np.zeros((len(sverts), 4), int)
s_joints[:, 0] = BI["Forearm"]
s_w = np.zeros((len(sverts), 4))
s_w[:, 0] = 1.0
s_col = np.ones((len(sverts), 4))

# ------------------------------------------------------------- the glTF ---
bin_ = bytearray()
views = []
accs = []


def add(arr, comp, typ, target=None, minmax=False):
    global bin_
    while len(bin_) % 4:
        bin_ += b"\0"
    data = arr.astype({5126: "<f4", 5125: "<u4", 5123: "<u2", 5121: "u1"}[comp]).tobytes()
    v = {"buffer": 0, "byteOffset": len(bin_), "byteLength": len(data)}
    if target:
        v["target"] = target
    views.append(v)
    bin_ += data
    a = {"bufferView": len(views) - 1, "componentType": comp, "count": int(arr.shape[0]), "type": typ}
    if minmax:
        a["min"] = [float(x) for x in arr.min(axis=0)]
        a["max"] = [float(x) for x in arr.max(axis=0)]
    accs.append(a)
    return len(accs) - 1


def prim(v, nr, uv, cl, jn, wt, fc, mat):
    return {
        "attributes": {
            "POSITION": add(v, 5126, "VEC3", 34962, True),
            "NORMAL": add(nr, 5126, "VEC3", 34962),
            "TEXCOORD_0": add(uv, 5126, "VEC2", 34962),
            "COLOR_0": add(cl, 5126, "VEC4", 34962),
            "JOINTS_0": add(jn, 5123, "VEC4", 34962),
            "WEIGHTS_0": add(wt, 5126, "VEC4", 34962),
        },
        "indices": add(fc.reshape(-1), 5125, "SCALAR", 34963),
        "material": mat,
    }


huv = np.zeros((nv, 2))
p0 = prim(verts, nrm, huv, col, top, tw, faces, 0)
p1 = prim(sverts, snrm, suv, s_col, s_joints, s_w, sfaces, 1)

# the joints' nodes, with their transforms as their parents see them
glob = {}
for b in BONE_NAMES:
    par, o, B = BONES[b]
    M = np.eye(4)
    M[:3, :3] = B
    M[:3, 3] = o
    glob[b] = M


def quat(m):
    m = np.asarray(m)
    t = np.trace(m)
    if t > 0:
        s = math.sqrt(t + 1.0) * 2
        return [(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, 0.25 * s]
    i = int(np.argmax(np.diag(m)))
    if i == 0:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        return [0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    if i == 1:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        return [(m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
    return [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s, (m[1, 0] - m[0, 1]) / s]


nodes = []
# 0: the root, 1: the mesh, then the joints
nodes.append({"name": "SmallHand", "children": [1, 2]})
nodes.append({"name": "HandMesh", "mesh": 0, "skin": 0})
first = len(nodes)
for b in BONE_NAMES:
    par = BONES[b][0]
    L = glob[b] if par is None else np.linalg.inv(glob[par]) @ glob[b]
    nd = {"name": b, "translation": [float(x) for x in L[:3, 3]]}
    q = quat(L[:3, :3])
    if abs(q[3]) < 0.999999:
        nd["rotation"] = [float(x) for x in q]
    kids = [first + BONE_NAMES.index(c) for c in BONE_NAMES if BONES[c][0] == b]
    if kids:
        nd["children"] = kids
    nodes.append(nd)
ibm = np.stack([np.linalg.inv(glob[b]).T.reshape(-1) for b in BONE_NAMES])   # (column-major)
ibm_acc = add(ibm, 5126, "MAT4")

gl = {
    "asset": {"version": "2.0", "generator": "covenant-war tools/make_small_hand.py"},
    "scene": 0,
    "scenes": [{"nodes": [0]}],
    "nodes": nodes,
    "meshes": [{"name": "SmallHand", "primitives": [p0, p1]}],
    "skins": [{"name": "SmallHandSkin", "joints": [first + i for i in range(len(BONE_NAMES))],
               "inverseBindMatrices": ibm_acc, "skeleton": first}],
    "materials": [
        {"name": "skin", "pbrMetallicRoughness": {"baseColorFactor": [0.95, 0.78, 0.70, 1.0], "metallicFactor": 0.0, "roughnessFactor": 0.6}},
        {"name": "wool", "pbrMetallicRoughness": {"baseColorFactor": [0.86, 0.79, 0.69, 1.0], "metallicFactor": 0.0, "roughnessFactor": 1.0}, "doubleSided": True},
    ],
    "buffers": [{"byteLength": 0}],
    "bufferViews": views,
    "accessors": accs,
}
while len(bin_) % 4:
    bin_ += b"\0"
gl["buffers"][0]["byteLength"] = len(bin_)
js = json.dumps(gl, separators=(",", ":")).encode()
while len(js) % 4:
    js += b" "
total = 12 + 8 + len(js) + 8 + len(bin_)
with open(OUT, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, total))
    f.write(struct.pack("<II", len(js), 0x4E4F534A))
    f.write(js)
    f.write(struct.pack("<II", len(bin_), 0x004E4942))
    f.write(bin_)
print("wrote %s (%.0f kB), bones: %s" % (OUT, total / 1024, ", ".join(BONE_NAMES)))
# (for WhiteSky: each digit's radii, to close the fingers onto the card)
for bn, ch, a, b, r1, r2 in SEGS:
    print("  %-8s from %s r %.4f -> %.4f" % (bn, np.round(a, 4), r1, r2))
