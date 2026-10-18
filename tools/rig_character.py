"""Turns a rigged character (AssetFurnace's, or any glTF with a humanoid skeleton)
into one of the game's 3D characters, the way Figure3D expects them:

  - the shared skeleton: Root, Hips, Spine, Spine1, Spine2, Neck, Head, Left/Right
    Shoulder, Arm, ForeArm, Hand, the fingers (Thumb, Index, Middle, Ring, Pinky
    1-3), UpLeg, Leg, Foot, ToeBase. Bones called bone_0, bone_1... are named by
    where they sit (the model faces +Z, its left is +X). Smaller AssetFurnace
    rigs have what they have: a thumb and the fingers as one (Middle: Tam's,
    Old Nell's), or a thumb and two groups (Index, Ring: Tilly's); no Spine1
    (Nell's);
  - every bone's rest square to the world (no roll), as Bram's, Corin's... are, so
    clips pass from one model to another;
  - feet on the ground at a chosen height;
  - its own clips converted exactly; walking clips (--cycle) cut to one step
    cycle from their steady part that stays on the spot (the game moves the
    figure), with their natural speed printed for Figure3D.OWN_GAIT; looping
    clips (--seam) eased so the end meets the start;
  - the head lifted a few degrees in chosen clips (--head-up), when the
    sculpted face looks down at rest;
  - clips it lacks (--borrow) fitted from other models: arms and legs point
    where the other model's did, the body, head and fingers move as theirs did
    from the rest pose, the hips' travel scaled to the leg length;
  - one arm kept as it is in another of its clips (--hold-arm), for a hand
    on a walking stick that's part of the mesh (Old Nell's);
  - its textures beside it as <stem>_atlas.png and <stem>_mr.png (and
    <stem>_normal.png with --normal-map), imported once with our settings.
    The player's AssetFurnace normal map shades his face in two halves and
    blotches his shirt, even with the tangents of his unrigged model, so a
    normal map is only used when asked for (check the face first).

  python3 tools/rig_character.py IN.glb assets/models/characters/<id>.glb --height 1.76 \\
      --cycle walk --cycle run --cycle sneak --seam idle --seam fight_stance --seam dance \\
      --borrow assets/models/characters/clips/shared.glb:talk,duel_idle,play_card \\
      --borrow assets/models/characters/bram.glb:lift

  (tools/rig_player_a.sh and tools/rig_villager.sh hold each character's settings.)
  Only what the model uses is written: AssetFurnace's combined files can carry
  every source file's mesh and textures, unused (Tam's master was 47 MB).

  python3 tools/rig_character.py --library IN.glb OUT.glb
      the skeleton and clips of a game model, with a stand-in mesh, for borrowing from
"""
import argparse, io, json, math, os, struct, sys
import numpy as np
from PIL import Image

# ------------------------------------------------------------------ glTF in ---

NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
DT = {5126: np.float32, 5123: np.uint16, 5121: np.uint8, 5125: np.uint32, 5122: np.int16, 5120: np.int8}


def load(path):
    b = open(path, "rb").read()
    magic, ver, length = struct.unpack_from("<III", b, 0)
    assert magic == 0x46546C67, path + " is not a GLB"
    off, js, bins = 12, None, b""
    while off < length:
        cl, ct = struct.unpack_from("<II", b, off)
        c = b[off + 8:off + 8 + cl]
        off += 8 + cl
        if ct == 0x4E4F534A:
            js = json.loads(c)
        elif ct == 0x004E4942:
            bins = c
    return js, bins


def acc(j, b, i):
    a = j["accessors"][i]
    n, dt = NC[a["type"]], DT[a["componentType"]]
    bv = j["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    isz = np.dtype(dt).itemsize
    stride = bv.get("byteStride", n * isz)
    raw = np.frombuffer(b, np.uint8, stride * (a["count"] - 1) + n * isz, off)
    out = np.lib.stride_tricks.as_strided(raw, (a["count"], n * isz), (stride, 1)).copy().view(dt).reshape(a["count"], n)
    if a.get("normalized"):
        out = out.astype(np.float64) / np.iinfo(dt).max
    return out if n > 1 else out[:, 0]


# ------------------------------------------------------------ quaternions ---
# (x, y, z, w), as glTF stores them

def qmul(a, b):
    ax, ay, az, aw = np.moveaxis(np.asarray(a, np.float64), -1, 0)
    bx, by, bz, bw = np.moveaxis(np.asarray(b, np.float64), -1, 0)
    return np.stack([aw * bx + ax * bw + ay * bz - az * by,
                     aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw,
                     aw * bw - ax * bx - ay * by - az * bz], -1)


def qinv(a):
    return np.asarray(a, np.float64) * np.array([-1.0, -1.0, -1.0, 1.0])


def qnorm(q):
    return q / np.linalg.norm(q, axis=-1, keepdims=True)


def qrot(q, v):
    v = np.asarray(v, np.float64)
    qv = np.concatenate([v, np.zeros(v.shape[:-1] + (1,))], -1)
    return qmul(qmul(q, qv), qinv(q))[..., :3]


def slerp(a, b, u):
    a, b = np.asarray(a, np.float64), np.asarray(b, np.float64)
    u = np.asarray(u, np.float64)[..., None]
    d = np.sum(a * b, -1, keepdims=True)
    b = np.where(d < 0, -b, b)
    d = np.abs(d)
    th = np.arccos(np.clip(d, -1, 1))
    s = np.sin(th)
    small = s < 1e-6
    wa = np.where(small, 1 - u, np.sin((1 - u) * th) / np.where(small, 1, s))
    wb = np.where(small, u, np.sin(u * th) / np.where(small, 1, s))
    return qnorm(wa * a + wb * b)


def arc(u, v):
    """The smallest turn taking direction u onto direction v."""
    u = u / np.linalg.norm(u)
    v = v / np.linalg.norm(v)
    d = float(np.dot(u, v))
    if d < -0.9999:
        ax = np.cross(u, [1, 0, 0])
        if np.linalg.norm(ax) < 1e-3:
            ax = np.cross(u, [0, 1, 0])
        return np.array([*(ax / np.linalg.norm(ax)), 0.0])
    return qnorm(np.array([*np.cross(u, v), 1 + d]))


def yaw_q(a):
    return np.array([0.0, math.sin(a / 2), 0.0, math.cos(a / 2)])


def angle(a, b):
    return np.degrees(2 * np.arccos(np.clip(np.abs(np.sum(a * b, -1)), 0, 1)))


I4 = np.array([0.0, 0.0, 0.0, 1.0])

# ------------------------------------------------------------- skeleton ---

FINGERS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
CANON = ["Root", "Hips", "Spine", "Spine1", "Spine2", "Neck", "Head"]
for _s in ["Left", "Right"]:
    CANON += [_s + "Shoulder", _s + "Arm", _s + "ForeArm", _s + "Hand"]
    for _f in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
        CANON += ["%sHand%s%d" % (_s, _f, k) for k in (1, 2, 3)]
for _s in ["Left", "Right"]:
    CANON += [_s + "UpLeg", _s + "Leg", _s + "Foot", _s + "ToeBase"]

# the bones a model must have; the rest (a neck, fingers) are used when it has them
REQUIRED = ["Hips", "Spine", "Head"] + [_s + _b for _s in ["Left", "Right"] for _b in
                                        ["Arm", "ForeArm", "Hand", "UpLeg", "Leg", "Foot", "ToeBase"]]

# a bone's direction is from it to the first of these children both models have:
# arms and legs are fitted to it
PRIMARY = {}
for _s in ["Left", "Right"]:
    PRIMARY.update({_s + "Arm": [_s + "ForeArm"], _s + "ForeArm": [_s + "Hand"],
                    _s + "Hand": [_s + "HandMiddle1", _s + "HandIndex1", _s + "HandRing1"],
                    _s + "UpLeg": [_s + "Leg"], _s + "Leg": [_s + "Foot"], _s + "Foot": [_s + "ToeBase"]})


class Rig:
    """A skeleton: names, parents, rest (local TRS), world rest positions and turns."""

    def __init__(self, j, b, names=None):
        self.j, self.b = j, b
        nodes = j["nodes"]
        self.joints = list(j["skins"][0]["joints"])
        self.name = {}
        for i in range(len(nodes)):
            nm = nodes[i].get("name", "node%d" % i)
            self.name[i] = (names or {}).get(i, nm)
        self.parent = {}
        for i, n in enumerate(nodes):
            for c in n.get("children", []):
                self.parent[c] = i
        self.t = {i: np.array(n.get("translation", [0, 0, 0]), np.float64) for i, n in enumerate(nodes)}
        self.r = {i: np.array(n.get("rotation", [0, 0, 0, 1]), np.float64) for i, n in enumerate(nodes)}
        self.s = {i: np.array(n.get("scale", [1, 1, 1]), np.float64) for i, n in enumerate(nodes)}
        self.by_name = {self.name[i]: i for i in self.joints}
        self.order = self._topo()
        self.wp, self.wq = self.world(self.t, self.r)

    def _topo(self):
        out, seen = [], set()

        def visit(i):
            if i in seen:
                return
            if i in self.parent:
                visit(self.parent[i])
            seen.add(i)
            out.append(i)
        for i in range(len(self.j["nodes"])):
            visit(i)
        return out

    def world(self, t, r):
        """World positions and turns of every node, for local translations t and turns r
        (dicts or arrays over frames)."""
        wp, wq = {}, {}
        for i in self.order:
            if i in self.parent:
                p = self.parent[i]
                wp[i] = wp[p] + qrot(wq[p], t[i])
                wq[i] = qnorm(qmul(wq[p], r[i]))
            else:
                wp[i], wq[i] = t[i], r[i]
        return wp, wq

    def pos(self, nm):
        return self.wp[self.by_name[nm]]

    def bone_parent(self, i):
        p = self.parent.get(i)
        return p if p in self.joints else None


def name_bones(rig):
    """Standard names for a skeleton whose bones aren't named (bone_0...): by
    where they sit. Returns {node index: name}."""
    j = rig.j
    js = set(rig.joints)
    kids = {i: [c for c in j["nodes"][i].get("children", []) if c in js] for i in js}
    P = rig.wp
    roots = [i for i in js if rig.bone_parent(i) is None]
    assert len(roots) == 1, "expected one root bone, found %d" % len(roots)
    out = {}
    hips = roots[0]
    if P[hips][1] < 0.25 * max(P[i][1] for i in js) and len(kids[hips]) == 1:
        out[hips] = "Root"
        hips = kids[hips][0]
    out[hips] = "Hips"

    def lowest(i):
        return min([P[i][1]] + [lowest(c) for c in kids[i]])
    # the legs are the branches that reach the feet (Old Nell's start a little
    # above her hips bone)
    knee_high = P[hips][1] - 0.4 * (P[hips][1] - min(P[i][1] for i in js))
    up = [c for c in kids[hips] if lowest(c) > knee_high]
    down = [c for c in kids[hips] if lowest(c) <= knee_high]
    assert len(up) == 1 and len(down) == 2, "Hips should have a spine and two legs"
    # the spine, up to the chest (where the neck and the shoulders branch)
    chain, b = [], up[0]
    while len(kids[b]) == 1:
        chain.append(b)
        b = kids[b][0]
    chain.append(b)
    chest = b
    names = ["Spine", "Spine1", "Spine2"] if len(chain) == 3 else (
        ["Spine", "Spine2"] if len(chain) == 2 else ["Spine"] + ["Spine%d" % k for k in range(1, len(chain) - 1)] + ["Spine2"])
    for b, nm in zip(chain, names):
        out[b] = nm
    ck = kids[chest]
    neck = max(ck, key=lambda c: P[c][1] - abs(P[c][0] - P[chest][0]))
    if kids[neck]:
        out[neck] = "Neck"
        b, k = kids[neck][0], 0
        while True:
            out[b] = "Head" if k == 0 else "HeadTop_End%s" % ("" if k == 1 else k)
            if not kids[b]:
                break
            b, k = kids[b][0], k + 1
    else:
        out[neck] = "Head"   # one bone for the neck and head (Old Nell's)
    for sh in [c for c in ck if c != neck]:
        side = "Left" if P[sh][0] > P[chest][0] else "Right"
        b = sh
        for nm in ["Shoulder", "Arm", "ForeArm", "Hand"]:
            out[b] = side + nm
            if nm != "Hand":
                assert len(kids[b]) == 1, "unexpected branch at " + side + nm
                b = kids[b][0]
        hand = b
        fingers = list(kids[hand])
        if 2 <= len(fingers) <= 5:
            # the thumb starts nearest the wrist; the fingers go from the front
            # (index) back. A hand with fewer fingers has them in groups: two
            # (the fingers as one, Tam's and Nell's) or three (Tilly's)
            thumb = min(fingers, key=lambda c: np.linalg.norm(P[c] - P[hand]))
            rest = sorted([c for c in fingers if c != thumb], key=lambda c: -P[c][2])
            labels = {4: FINGERS[1:], 3: ["Index", "Middle", "Ring"], 2: ["Index", "Ring"], 1: ["Middle"]}[len(rest)]
            for f, nm in zip([thumb] + rest, ["Thumb"] + labels):
                b, k = f, 1
                while True:
                    out[b] = "%sHand%s%d" % (side, nm, k) if k <= 3 else "%sHand%s%d_End" % (side, nm, k)
                    if not kids[b]:
                        break
                    b, k = kids[b][0], k + 1
    for leg in down:
        side = "Left" if P[leg][0] > P[hips][0] else "Right"
        b = leg
        for nm in ["UpLeg", "Leg", "Foot", "ToeBase", "Toe_End"]:
            out[b] = side + nm
            if not kids[b]:
                break
            b = kids[b][0]
    return out


def standard_names(rig):
    """Bone names to use: the rig's own (minus a 'mixamorig:' prefix) when they're
    already the standard ones, else named by place."""
    own = {i: rig.name[i].split(":")[-1] for i in rig.joints}
    if "Hips" in own.values() and "LeftHand" in own.values():
        return own
    return name_bones(rig)


# ------------------------------------------------------------ animation ---

def sample(t_in, v, t, interp, is_rot):
    """A channel's value at times t."""
    if len(t_in) == 1:
        return np.repeat(v[:1], len(t), 0)
    if interp == "CUBICSPLINE":
        v = v[1::3]
    k = np.clip(np.searchsorted(t_in, t, side="right") - 1, 0, len(t_in) - 2)
    t0, t1 = t_in[k], t_in[k + 1]
    u = np.clip((t - t0) / np.maximum(t1 - t0, 1e-9), 0, 1)
    if interp == "STEP":
        u = np.where(t >= t1, 1.0, 0.0)
    if is_rot:
        return slerp(v[k], v[k + 1], u)
    return v[k] + (v[k + 1] - v[k]) * u[:, None]


def read_clip(rig, an):
    """A clip as local transforms over frames: times, {node: t}, {node: r}, {node: s}, animated sets."""
    j, b = rig.j, rig.b
    times = np.unique(np.round(np.concatenate([acc(j, b, s["input"]) for s in an["samplers"]]).astype(np.float64), 5))
    n = len(times)
    T = {i: np.repeat(rig.t[i][None], n, 0) for i in rig.t}
    R = {i: np.repeat(rig.r[i][None], n, 0) for i in rig.r}
    S = {i: np.repeat(rig.s[i][None], n, 0) for i in rig.s}
    moved = {"translation": set(), "rotation": set(), "scale": set()}
    for c in an["channels"]:
        s = an["samplers"][c["sampler"]]
        node, path = c["target"]["node"], c["target"]["path"]
        if path not in moved:
            continue
        ti = acc(j, b, s["input"]).astype(np.float64)
        v = acc(j, b, s["output"]).astype(np.float64)
        val = sample(ti, v, times, s.get("interpolation", "LINEAR"), path == "rotation")
        {"translation": T, "rotation": R, "scale": S}[path][node] = val
        rest = {"translation": rig.t, "rotation": rig.r, "scale": rig.s}[path][node]
        if path == "rotation":
            if angle(val, rest[None]).max() > 0.01:
                moved[path].add(node)
        elif np.abs(val - rest).max() > 1e-5:
            moved[path].add(node)
    return times, T, R, S, moved


class Clip:
    """A clip on the game skeleton: per bone name, local turns (n x 4); the hips'
    position (n x 3); local scales for bones that scale."""

    def __init__(self, name, times, rot, hips, scale):
        self.name, self.times, self.rot, self.hips, self.scale = name, times, rot, hips, scale
        self.speed = None

    @property
    def length(self):
        return float(self.times[-1])


def fit_clip(src, names, an, tgt_wp, corrections, k, tgt_hips, clip_name):
    """A source clip on the target skeleton. names: source node -> standard name.
    corrections: name -> the turn from the target's rest direction to the source's
    (I for bones moved as they are). k: how far the hips' travel is scaled."""
    times, T, R, S, moved = read_clip(src, an)
    wp, wq = src.world(T, R)
    rest_q = src.wq
    by = {names[i]: i for i in src.joints if i in names}
    out = {}
    glob = {}
    for nm in CANON:
        if nm == "Root" or nm not in tgt_wp:
            continue
        i = by.get(nm)
        if i is None:
            continue
        # the source bone's turn from its rest, in the world, then the fitting
        d = qmul(wq[i], qinv(rest_q[i])[None])
        g = qnorm(qmul(d, corrections.get(nm, I4)[None]))
        glob[nm] = g
    for nm in glob:
        p = parent_name(nm)
        while p is not None and p not in glob and p != "Root":
            p = parent_name(p)
        loc = glob[nm] if p in (None, "Root") else qmul(qinv(glob[p]), glob[nm])
        loc = qnorm(loc)
        # keep the hemisphere steady (no flips between keys)
        for f in range(1, len(loc)):
            if np.dot(loc[f], loc[f - 1]) < 0:
                loc[f] = -loc[f]
        out[nm] = loc
    hi = by["Hips"]
    hips = tgt_hips[None] + (wp[hi] - src.wp[hi][None]) * k
    scale = {}
    for i in moved["scale"]:
        if names.get(i) in tgt_wp:
            scale[names[i]] = S[i]
    times = times - times[0]
    return Clip(clip_name, times, out, hips, scale)


PARENTS = {}


def parent_name(nm):
    return PARENTS.get(nm)


def corrections_for(src, src_names, tgt_wp):
    """Per bone, the turn taking the target's rest direction onto the source's:
    arms and legs only; every other bone inherits its parent's (so the body,
    head and fingers move from rest as the source's did)."""
    sp = {src_names[i]: src.wp[i] for i in src.joints if i in src_names}
    out = {}
    for nm in CANON:
        if nm == "Root":
            continue
        c = next((c for c in PRIMARY.get(nm, []) if c in sp and c in tgt_wp), None)
        if c and nm in sp and nm in tgt_wp:
            out[nm] = arc(tgt_wp[c] - tgt_wp[nm], sp[c] - sp[nm])
        else:
            p = parent_name(nm)
            out[nm] = out.get(p, I4) if p else I4
    return out


def make_cycle(clip, rest_hips, steady=0.8, pmin=0.45, pmax=2.0):
    """Cuts a walking clip to one step cycle from its steady part, turned to head
    along +Z, staying on the spot, its end eased into its start. Sets clip.speed."""
    t = clip.times
    n = len(t)
    fps = (n - 1) / max(t[-1], 1e-6)
    hv = np.linalg.norm(np.gradient(clip.hips[:, [0, 2]], axis=0) * fps, axis=1)
    hv_s = np.convolve(hv, np.ones(9) / 9, mode="same")
    fast = hv_s >= steady * hv_s.max()
    names = list(clip.rot)
    Q = np.stack([clip.rot[nm] for nm in names], 1)
    w = np.array([3.0 if any(s in nm for s in ("Hips", "UpLeg", "Leg", "Foot", "Toe")) else
                  (2.0 if any(s in nm for s in ("Spine", "Arm", "Shoulder")) else
                   (0.2 if "Hand" in nm and nm[-1].isdigit() else 1.0)) for nm in names])
    vy = np.gradient(clip.hips[:, 1]) * fps
    best = None
    for i in range(n):
        if not fast[i]:
            continue
        for k in range(i + max(2, int(pmin * fps)), min(n, i + int(pmax * fps) + 1)):
            if not fast[k]:
                continue
            d = (angle(Q[i], Q[k]) * w).sum() / w.sum()
            sc = d + 100 * abs(clip.hips[i, 1] - clip.hips[k, 1]) + 5 * abs(vy[i] - vy[k])
            if best is None or sc < best[0]:
                best = (sc, i, k)
    assert best is not None, clip.name + ": no steady stretch to loop"
    sc, i, k = best
    sl = slice(i, k + 1)
    times = t[sl] - t[i]
    rot = {nm: clip.rot[nm][sl].copy() for nm in names}
    hips = clip.hips[sl].copy()
    scale = {nm: v[sl].copy() for nm, v in clip.scale.items()}
    disp = hips[-1] - hips[0]
    heading = math.atan2(disp[0], disp[2])
    turn = yaw_q(-heading)
    # turn the whole move to head along +Z (the hips carry it; Root stays square)
    rot["Hips"] = qnorm(qmul(turn[None], rot["Hips"]))
    rel = qrot(turn[None], hips - hips[0][None])
    dist = float(np.linalg.norm(disp[[0, 2]]))
    period = float(times[-1])
    u = times / period
    # on the spot: take away the steady travel, keep the sway and bob
    rel[:, 2] -= dist * u
    rel[:, 0] -= rel[-1, 0] * u
    rel -= np.array([rel[:, 0].mean(), 0.0, rel[:, 2].mean()])[None]
    hips = rest_hips[None] * np.array([1, 0, 1])[None] + rel + np.array([0, hips[0, 1], 0])[None]
    # the end eased into the start
    hips[:, 1] += (hips[0, 1] - hips[-1, 1]) * u
    for nm in names:
        q = rot[nm]
        dq = qmul(qinv(q[-1]), q[0])
        rot[nm] = qnorm(qmul(q, slerp(np.repeat(I4[None], len(u), 0), np.repeat(dq[None], len(u), 0), u)))
    for nm, v in scale.items():
        scale[nm] = v + (v[0] - v[-1])[None] * u[:, None]
    out = Clip(clip.name, times, rot, hips, scale)
    out.speed = dist / period
    out.cut = (float(t[i]), float(t[k]), sc, math.degrees(heading))
    return out


def head_up(clip, deg):
    """Lifts the head by `deg` (two fifths at the neck, the rest at the head):
    for a model whose sculpted face looks down at rest, in clips that don't
    lift it themselves."""
    for nm, part in (("Neck", 0.4), ("Head", 0.6)):
        a = -math.radians(deg * part) / 2
        q = np.array([math.sin(a), 0.0, 0.0, math.cos(a)])
        n = len(clip.times)
        clip.rot[nm] = qnorm(qmul(np.repeat(q[None], n, 0), clip.rot.get(nm, np.repeat(I4[None], n, 0))))
    return clip


def arm_bones(side):
    """The shoulder, arm, hand and fingers on one side ("Left"/"Right")."""
    return [nm for nm in CANON if nm.startswith(side) and not any(x in nm for x in ("Leg", "Foot", "Toe"))]


def hold_arm(clip, src, side):
    """Keeps one arm (the hand on a walking stick) moving as it does in clip
    `src` (idle) for the whole of `clip`, so the stick doesn't swing through
    the body: src runs a whole number of times over the clip so a loop still
    meets its start, or stays at its first moment in a short clip (a step)."""
    n = len(clip.times)
    L = clip.length
    if L < 0.5 * src.length:
        u = np.zeros(n)
    else:
        k = max(1, round(L / src.length))
        # (src's end meets its start: its loop is eased with --seam)
        u = np.minimum(np.mod(clip.times * k * src.length / max(L, 1e-6), src.length), src.length)
    for nm in arm_bones(side):
        if nm in src.rot:
            clip.rot[nm] = sample(src.times, src.rot[nm], u, "LINEAR", True)
    return clip


def ease_seam(clip, window=1.0):
    """Eases the last `window` seconds so a looping clip's end meets its start."""
    t = clip.times
    a = max(0.0, t[-1] - window)
    u = np.clip((t - a) / max(t[-1] - a, 1e-6), 0, 1)
    u = u * u * (3 - 2 * u)
    for nm, q in clip.rot.items():
        dq = qmul(qinv(q[-1]), q[0])
        clip.rot[nm] = qnorm(qmul(q, slerp(np.repeat(I4[None], len(u), 0), np.repeat(dq[None], len(u), 0), u)))
    clip.hips = clip.hips + (clip.hips[0] - clip.hips[-1])[None] * u[:, None]
    for nm, v in clip.scale.items():
        clip.scale[nm] = v + (v[0] - v[-1])[None] * u[:, None]
    return clip


# ----------------------------------------------------------- glTF out ---

class Out:
    def __init__(self):
        self.bin = bytearray()
        self.views, self.accs = [], []

    def view(self, data, target=None):
        while len(self.bin) % 4:
            self.bin.append(0)
        v = {"buffer": 0, "byteOffset": len(self.bin), "byteLength": len(data)}
        if target:
            v["target"] = target
        self.bin += data
        self.views.append(v)
        return len(self.views) - 1

    def acc(self, arr, ctype, typ, target=None, minmax=False, normalized=False):
        arr = np.ascontiguousarray(arr)
        a = {"bufferView": self.view(arr.tobytes(), target), "componentType": ctype,
             "count": int(arr.shape[0]), "type": typ}
        if normalized:
            a["normalized"] = True
        if minmax:
            a2 = arr.reshape(arr.shape[0], -1)
            a["min"] = [float(x) for x in a2.min(0)]
            a["max"] = [float(x) for x in a2.max(0)]
        self.accs.append(a)
        return len(self.accs) - 1

    def f32(self, arr, typ, **kw):
        return self.acc(np.asarray(arr, np.float32), 5126, typ, **kw)


def write_glb(path, j, out):
    while len(out.bin) % 4:
        out.bin.append(0)
    j["buffers"] = [{"byteLength": len(out.bin)}]
    j["bufferViews"] = out.views
    j["accessors"] = out.accs
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    total = 12 + 8 + len(js) + 8 + len(out.bin)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(out.bin), 0x004E4942))
        f.write(bytes(out.bin))
    return total


def emit_clips(out, clips, node_of):
    anims = []
    for c in clips:
        chans, samps = [], []
        tin = out.f32(c.times, "SCALAR", minmax=True)

        def add(node, path, vals, typ):
            samps.append({"input": tin, "output": out.f32(vals, typ), "interpolation": "LINEAR"})
            chans.append({"sampler": len(samps) - 1, "target": {"node": node, "path": path}})
        add(node_of["Hips"], "translation", c.hips, "VEC3")
        for nm in CANON:
            if nm in c.rot and nm in node_of:
                q = c.rot[nm]
                if angle(q, I4[None]).max() < 0.02:
                    continue
                add(node_of[nm], "rotation", q, "VEC4")
        for nm, v in c.scale.items():
            if nm in node_of:
                add(node_of[nm], "scale", v, "VEC3")
        anims.append({"name": c.name, "channels": chans, "samplers": samps})
    return anims


def save_png(img, path):
    img.save(path, "PNG", optimize=True)
    return os.path.basename(path)


TEX_IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://{res}"

[params]

compress/mode=1
compress/high_quality=false
compress/lossy_quality={q}
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map={normal}
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


def write_tex_import(png_path, normal=False):
    """Our import settings for a texture (lossy, mipmapped, as the other characters'),
    written only when the texture hasn't one yet."""
    imp = png_path + ".import"
    if os.path.exists(imp):
        return
    root = os.path.abspath(png_path)
    proj = root
    while proj != "/" and not os.path.exists(os.path.join(proj, "project.godot")):
        proj = os.path.dirname(proj)
    res = os.path.relpath(root, proj) if proj != "/" else os.path.basename(root)
    open(imp, "w").write(TEX_IMPORT.format(res=res, q="0.9" if normal else "0.85", normal=1 if normal else 0))


# ---------------------------------------------------------------- main ---

ARM_PARTS = ("Arm", "ForeArm", "Hand")


def free_of_arms(spec, j, b, pr, skin_joints, jn, wts, scale_h):
    """A bag and its strap that move with the body, not with an arm.

    AssetFurnace binds whatever is near an arm in the rest pose to it: Tilly's
    satchel hangs beside her left hand, so its top was bound to her forearm and
    stretched up after her arm when she held her card out, and the strap over
    her right shoulder followed that arm. spec is "R,G,B:TOL" (0-1): the
    vertices of about that colour (the leather) bound to an arm or hand lose
    those bones, and take the body's bones from their own weights, or from the
    leather round them where they had none."""
    rgb, _, tol = spec.partition(":")
    target = np.array([float(x) for x in rgb.split(",")])
    tol = float(tol or 0.12)
    # the colour under each vertex, from the base colour texture
    mat = j["materials"][pr["material"]] if "material" in pr else {}
    info = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
    assert info, "--free-of-arms needs the model's colour texture"
    im = j["images"][j["textures"][info["index"]]["source"]]
    bv = j["bufferViews"][im["bufferView"]]
    img = np.asarray(Image.open(io.BytesIO(b[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]])).convert("RGB")).astype(np.float64) / 255.0
    uv = acc(j, b, pr["attributes"]["TEXCOORD_0"])
    h, w = img.shape[:2]
    col = img[np.clip((uv[:, 1] % 1.0) * h, 0, h - 1).astype(int), np.clip((uv[:, 0] % 1.0) * w, 0, w - 1).astype(int)]
    n, nb = len(jn), len(skin_joints)
    dense = np.zeros((n, nb))
    for k in range(jn.shape[1]):
        np.add.at(dense, (np.arange(n), jn[:, k].astype(np.int64)), wts[:, k])
    arm = np.array([any(nm == side + part or nm.startswith(side + "Hand") for side in ("Left", "Right") for part in ARM_PARTS)
                    for nm in skin_joints])
    on_arm = dense[:, arm].sum(1) > 0.01
    near = np.linalg.norm(col - target, axis=1)
    like = near < tol
    # the bag and its strap are big patches of that colour, all of a piece;
    # a few shaded spots of skin on a forearm that happen to be about the
    # same colour are small ones of their own, and stay with the arm
    idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
    e0 = np.concatenate([idx[:, 0], idx[:, 1], idx[:, 2], idx[:, 1], idx[:, 2], idx[:, 0]])
    e1 = np.concatenate([idx[:, 1], idx[:, 2], idx[:, 0], idx[:, 0], idx[:, 1], idx[:, 2]])
    p0 = acc(j, b, pr["attributes"]["POSITION"])
    _, weld = np.unique(np.round(p0 * 20000).astype(np.int64), axis=0, return_inverse=True)
    weld = weld.reshape(-1)
    parent = np.arange(n)

    def root(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    first = {}   # the first copy of that colour at each point (where texture islands meet)
    pairs = [(first.setdefault(int(weld[i]), i), i) for i in range(n) if like[i]]
    pairs += list(zip(e0.tolist(), e1.tolist()))
    for a_, c_ in pairs:
        if like[a_] and like[c_]:
            ra, rc_ = root(a_), root(c_)
            if ra != rc_:
                parent[rc_] = ra
    roots = np.array([root(i) for i in range(n)])
    ids, counts = np.unique(roots[like], return_counts=True)
    big = set(ids[counts >= 100].tolist())
    sel = on_arm & like & np.array([r in big for r in roots])
    # bits of the same leather touching it (a corner of the bag where it meets
    # the forearm, painted on a scrap of texture of its own): within 3 cm of
    # what's freed (7 cm); a texture seam already splits them from the arm's skin
    if sel.any():
        cand = np.where(on_arm & like & ~sel)[0]
        ref = p0[sel]
        reach = 0.07 * float(np.ptp(p0[:, 1])) / scale_h   # 7 cm on the finished model
        for i in cand:
            if np.min(np.linalg.norm(ref - p0[i], axis=1)) < reach:
                sel[i] = True
    # and the edge of it: arm-bound neighbours of about the same colour
    edge = np.zeros(n, bool)
    np.logical_or.at(edge, e0, sel[e1])
    sel |= edge & on_arm & (near < tol * 1.6)
    # the body's share: its own weights without the arms, or (where that's
    # nothing much) the leather round it, spread in from where it's bound to
    # the body
    body = dense.copy()
    body[:, arm] = 0.0
    own = body.sum(1)
    x = body / np.maximum(own[:, None], 1e-9)
    keep = sel & (own >= 0.5)
    fill = sel & ~keep
    cnt = np.zeros(n)
    np.add.at(cnt, e0, 1.0)
    for _ in range(60):
        acc_ = np.zeros((n, nb))
        np.add.at(acc_, e0, x[e1])
        avg = acc_ / np.maximum(cnt[:, None], 1.0)
        s = avg.sum(1, keepdims=True)
        x[fill] = np.where(s[fill] > 1e-6, avg[fill] / np.maximum(s[fill], 1e-9), x[fill])
    # any left with nothing (bound to an arm all round): the body's weights at
    # the nearest point that has them
    empty = np.where(fill & (x.sum(1) < 0.5))[0]
    if len(empty):
        donors = np.where(~sel & (own >= 0.9))[0]
        for i in empty:
            d = np.linalg.norm(p0[donors] - p0[i], axis=1)
            x[i] = body[donors[np.argmin(d)]] / own[donors[np.argmin(d)]]
    new = dense.copy()
    new[keep] = x[keep]
    new[fill] = x[fill]
    # back to four bones a vertex
    top = np.argsort(-new, axis=1)[:, :4]
    tw = np.take_along_axis(new, top, axis=1)
    tw = tw / np.maximum(tw.sum(1, keepdims=True), 1e-9)
    left = int((sel & (dense[:, [skin_joints.index(nm) for nm in skin_joints if nm.startswith("Left")]].sum(1) > 0)).sum())
    jn_out = jn.copy()
    w_out = wts.copy()
    jn_out[sel] = top[sel].astype(jn.dtype)
    w_out[sel] = tw[sel].astype(wts.dtype)
    # where the hand rested on the bag the mesh is fused, hand to leather: a
    # triangle with a corner all on the arm and a corner not on it at all
    # would stretch into a long sheet as the arm moves off, so those are left
    # out (in the rest pose they're slivers where the two touch; weights that
    # blend, as at a shoulder, never jump like that across one triangle)
    arm_after = np.zeros(n)
    for k in range(jn_out.shape[1]):
        arm_after += np.where(arm[jn_out[:, k].astype(np.int64)], w_out[:, k], 0.0)
    drop = (arm_after >= 0.9)[idx].any(1) & (arm_after <= 0.02)[idx].any(1)
    print("  freed from the arms: %d vertices of the colour %s (%d bound to the left arm, %d filled in from the leather round them); "
          "%d triangles joining an arm to what isn't on it left out" %(int(sel.sum()), rgb, left, int(fill.sum()), int(drop.sum())))
    return jn_out, w_out, drop


def build(args):
    j, b = load(args.input)
    src = Rig(j, b)
    names = standard_names(src)
    missing = [nm for nm in REQUIRED if nm not in names.values()]
    assert not missing, "couldn't find bones: " + ", ".join(missing)
    unnamed = [src.name[i] for i in src.joints if i not in names]
    assert not unnamed, "couldn't place bones: " + ", ".join(unnamed)
    for i, nm in names.items():
        PARENTS.setdefault(nm, None)
    for i in src.joints:
        p = src.bone_parent(i)
        PARENTS[names[i]] = names[p] if p is not None else "Root"
    PARENTS["Root"] = None
    PARENTS["Hips"] = "Root"
    # the mesh: one skinned mesh, at the model's origin
    mesh_nodes = [i for i, n in enumerate(j["nodes"]) if "mesh" in n and "skin" in n]
    assert len(mesh_nodes) == 1, "expected one skinned mesh"
    mn = mesh_nodes[0]
    assert np.allclose(src.wp[mn], 0, atol=1e-4) and angle(src.wq[mn], I4) < 0.01, "the mesh should sit at the origin"
    prims = j["meshes"][j["nodes"][mn]["mesh"]]["primitives"]
    assert len(prims) == 1, "expected one material"
    pr = prims[0]
    pos = acc(j, b, pr["attributes"]["POSITION"]).astype(np.float64)
    # bind pose = rest pose
    ibm = acc(j, b, j["skins"][0]["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
    for k, ji in enumerate(src.joints):
        q = src.wq[ji]
        x, y, z, w = q
        G = np.eye(4)
        G[:3, :3] = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
        G[:3, 3] = src.wp[ji]
        assert np.abs(G @ ibm[k] - np.eye(4)).max() < 1e-3, "bind pose isn't the rest pose (%s)" % names[ji]
    lo, hi = pos.min(0), pos.max(0)
    s = args.height / (hi[1] - lo[1]) if args.height else 1.0
    lift = -lo[1] * s
    # facing +Z: toes ahead of the ankles
    by = {nm: i for i, nm in names.items()}
    toe_z = src.wp[by["LeftToeBase"]][2] - src.wp[by["LeftFoot"]][2]
    assert toe_z > 0, "the model should face +Z"

    def tp(p):
        return np.asarray(p) * s + np.array([0, lift, 0])
    tgt_wp = {"Root": np.zeros(3)}
    for i in src.joints:
        tgt_wp[names[i]] = tp(src.wp[i])
    # nodes: the mesh, then the bones in the standard order (extras after)
    order = ["Root"] + [nm for nm in CANON if nm in tgt_wp and nm != "Root"]
    order += [names[i] for i in src.joints if names[i] not in order]
    node_of = {nm: k + 1 for k, nm in enumerate(order)}
    children = {nm: [] for nm in order}
    for nm in order[1:]:
        children[PARENTS[nm]].append(node_of[nm])
    nodes = [{"name": args.name, "mesh": 0, "skin": 0}]
    for nm in order:
        nd = {"name": nm}
        p = PARENTS.get(nm)
        off = tgt_wp[nm] - (tgt_wp[p] if p else np.zeros(3))
        if np.abs(off).max() > 0:
            nd["translation"] = [float(x) for x in off]
        if children[nm]:
            nd["children"] = children[nm]
        nodes.append(nd)
    out = Out()
    # mesh
    jn = acc(j, b, pr["attributes"]["JOINTS_0"]).astype(np.int64)
    wts = acc(j, b, pr["attributes"]["WEIGHTS_0"]).astype(np.float32)
    skin_joints = order  # skin index = position in order
    remap = np.array([skin_joints.index(names[ji]) for ji in src.joints])
    jn2 = remap[jn].astype(np.uint8 if len(skin_joints) < 256 else np.uint16)
    wts = wts / np.maximum(wts.sum(1, keepdims=True), 1e-9)
    drop = None
    if args.free_of_arms:
        jn2, wts, drop = free_of_arms(args.free_of_arms, j, b, pr, skin_joints, jn2, wts, (hi[1] - lo[1]) * s)
    attrs = {
        "POSITION": out.f32(tp(pos), "VEC3", target=34962, minmax=True),
        "NORMAL": out.f32(acc(j, b, pr["attributes"]["NORMAL"]), "VEC3", target=34962),
        "TEXCOORD_0": out.f32(acc(j, b, pr["attributes"]["TEXCOORD_0"]), "VEC2", target=34962),
        "JOINTS_0": out.acc(jn2, 5121 if jn2.dtype == np.uint8 else 5123, "VEC4", target=34962),
        "WEIGHTS_0": out.f32(wts, "VEC4", target=34962),
    }
    idx = acc(j, b, pr["indices"]).astype(np.uint32).reshape(-1)
    if drop is not None and drop.any():
        idx = idx.reshape(-1, 3)[~drop].reshape(-1)
    ind = out.acc(idx.astype(np.uint16) if idx.max() < 65536 else idx, 5123 if idx.max() < 65536 else 5125, "SCALAR", target=34963)
    ibms = np.stack([np.eye(4) for _ in skin_joints])
    for k, nm in enumerate(skin_joints):
        ibms[k, :3, 3] = -tgt_wp[nm]
    ibm_acc = out.f32(ibms.transpose(0, 2, 1).reshape(-1, 16), "MAT4")
    # textures beside the model
    stem = os.path.splitext(os.path.basename(args.output))[0]
    odir = os.path.dirname(os.path.abspath(args.output))
    mat_src = j["materials"][pr["material"]] if "material" in pr else {}

    def image_of(texinfo):
        if not texinfo:
            return None
        im = j["images"][j["textures"][texinfo["index"]]["source"]]
        bv = j["bufferViews"][im["bufferView"]]
        data = b[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
        return Image.open(io.BytesIO(data)).convert("RGB")
    images, textures = [], []
    mat = {"name": args.name}
    pbr = {}
    for key, suffix, normal in [("baseColorTexture", "atlas", False), ("normalTexture", "normal", True),
                                ("metallicRoughnessTexture", "mr", False)]:
        info = mat_src.get(key) or mat_src.get("pbrMetallicRoughness", {}).get(key)
        img = image_of(info)
        if img is None or (key == "normalTexture" and not args.normal_map):
            continue
        lim = args.texture_size if suffix != "mr" else min(args.texture_size, 1024)
        if img.width > lim:
            img = img.resize((lim, lim), Image.LANCZOS)
        fn = save_png(img, os.path.join(odir, "%s_%s.png" % (stem, suffix)))
        write_tex_import(os.path.join(odir, fn), normal)
        images.append({"name": suffix, "uri": fn})
        textures.append({"sampler": 0, "source": len(images) - 1})
        ref = {"index": len(textures) - 1}
        if key == "normalTexture":
            mat["normalTexture"] = ref
        else:
            pbr[key] = ref
    pbr["metallicFactor"] = float(mat_src.get("pbrMetallicRoughness", {}).get("metallicFactor", 1.0))
    pbr["roughnessFactor"] = float(mat_src.get("pbrMetallicRoughness", {}).get("roughnessFactor", 1.0))
    mat["pbrMetallicRoughness"] = pbr
    if args.double_sided:
        mat["doubleSided"] = True
    # clips: its own, then the ones it borrows
    rest_hips = tgt_wp["Hips"]
    clips = {}
    ident = {nm: I4 for nm in CANON}
    renames = dict(r.split("=", 1) for r in args.rename)
    for an in j.get("animations", []):
        nm = an.get("name", "clip")
        nm = renames.get(nm, nm)
        clips[nm] = fit_clip(src, names, an, tgt_wp, ident, s, rest_hips, nm)
    report = []
    for spec in args.borrow:
        path, _, which = spec.rpartition(":")
        dj, db = load(path)
        drig = Rig(dj, db)
        dnames = standard_names(drig)
        d_hips = drig.wp[{v: k for k, v in dnames.items()}["Hips"]]
        if len(drig.joints) == len(src.joints) and np.allclose(d_hips, src.wp[by["Hips"]], atol=1e-3):
            # the model's own rig, in another of its files (a single-clip
            # AssetFurnace export): its clips fit as the model's own do
            corr = ident
            dk = s
        else:
            corr = corrections_for(drig, dnames, tgt_wp)
            dk = rest_hips[1] / d_hips[1]
        anims = {a.get("name", "clip%d" % k): a for k, a in enumerate(dj.get("animations", []))}
        for item in which.split(","):
            # "theirs=ours" takes their clip under our name (a single-clip
            # AssetFurnace file whose one clip is called whatever it's called)
            src_nm, _, nm = item.partition("=")
            nm = nm or src_nm
            if nm in clips:
                report.append("%-12s own clip kept (not borrowed from %s)" % (nm, os.path.basename(path)))
                continue
            if src_nm == "*" and len(anims) == 1:
                src_nm = list(anims)[0]
            assert src_nm in anims, "%s has no clip %s (it has %s)" % (path, src_nm, ", ".join(anims))
            clips[nm] = fit_clip(drig, dnames, anims[src_nm], tgt_wp, corr, dk, rest_hips, nm)
            report.append("%-12s fitted from %s" % (nm, os.path.basename(path)))
    # (after the borrowing: a walk that came from a single-clip file of the
    # model's own is cut to its cycle like one it carried itself)
    for nm in args.cycle:
        if nm in clips:
            c = make_cycle(clips[nm], rest_hips)
            clips[nm] = c
            report.append("%-12s one cycle %.2f s (from %.2f to %.2f s, mismatch %.1f, turned %.1f deg), natural speed %.2f m/s"
                          % (nm, c.length, c.cut[0], c.cut[1], c.cut[2], -c.cut[3], c.speed))
    for nm in args.seam:
        if nm in clips:
            ease_seam(clips[nm])
            report.append("%-12s end eased into its start" % nm)
    for spec in args.hold_arm:
        side, src_nm, which = spec.split(":")
        for nm in which.split(","):
            if nm in clips:
                hold_arm(clips[nm], clips[src_nm], side)
        report.append("%s arm kept as in %s in %s" % (side.lower(), src_nm, which))
    for spec in args.head_up:
        deg, _, which = spec.partition(":")
        for nm in which.split(","):
            if nm in clips:
                head_up(clips[nm], float(deg))
        report.append("head lifted %s deg in %s" % (deg, which))
    gltf = {
        "asset": {"version": "2.0", "generator": "Covenant %s / tools/rig_character.py from %s" % (args.name, os.path.basename(args.input))},
        "scene": 0,
        "scenes": [{"nodes": [0, 1]}],
        "nodes": nodes,
        "skins": [{"name": args.name, "joints": [node_of[nm] for nm in skin_joints], "inverseBindMatrices": ibm_acc}],
        "meshes": [{"name": args.name, "primitives": [{"attributes": attrs, "indices": ind, "material": 0}]}],
        "materials": [mat],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}],
        "textures": textures,
        "images": images,
    }
    gltf["animations"] = emit_clips(out, list(clips.values()), node_of)
    size = write_glb(args.output, gltf, out)
    h = tgt_wp["Head"][1]
    print("%s: %d bones, %d clips, %.2f m tall (hips %.3f, head %.3f), %d KB"
          % (args.output, len(skin_joints), len(clips), (hi[1] - lo[1]) * s, rest_hips[1], h, size // 1024))
    for r in report:
        print("  " + r)
    for c in clips.values():
        print("  clip %-13s %.2f s" % (c.name, c.length) + ("  speed %.2f m/s" % c.speed if c.speed else ""))


def library(args):
    """A game model's skeleton and clips, with a one-triangle stand-in for its mesh."""
    j, b = load(args.input)
    rig = Rig(j, b)
    out = Out()
    joints = rig.joints
    new ={old: k + 1 for k, old in enumerate([i for i in rig.order if i in joints])}
    nodes = [{"name": "clips", "mesh": 0, "skin": 0}]
    for old in [i for i in rig.order if i in joints]:
        n = j["nodes"][old]
        nd = {"name": n["name"]}
        for key in ("translation", "rotation", "scale"):
            if key in n:
                nd[key] = n[key]
        ch = [new[c] for c in n.get("children", []) if c in new]
        if ch:
            nd["children"] = ch
        nodes.append(nd)
    roots = [new[i] for i in joints if rig.bone_parent(i) is None]
    ibm = acc(j, b, j["skins"][0]["inverseBindMatrices"])
    tri = np.array([[0, 0, 0], [0.001, 0, 0], [0, 0.001, 0]], np.float32)
    attrs = {"POSITION": out.f32(tri, "VEC3", target=34962, minmax=True),
             "JOINTS_0": out.acc(np.zeros((3, 4), np.uint8), 5121, "VEC4", target=34962),
             "WEIGHTS_0": out.f32(np.array([[1, 0, 0, 0]] * 3), "VEC4", target=34962)}
    anims = []
    for an in j.get("animations", []):
        chans, samps = [], []
        for c in an["channels"]:
            if c["target"]["node"] not in new:
                continue
            sm = an["samplers"][c["sampler"]]
            ti = acc(j, b, sm["input"])
            v = acc(j, b, sm["output"])
            typ = {1: "SCALAR", 3: "VEC3", 4: "VEC4"}[v.shape[1] if v.ndim > 1 else 1]
            samps.append({"input": out.f32(ti, "SCALAR", minmax=True), "output": out.f32(v, typ),
                          "interpolation": sm.get("interpolation", "LINEAR")})
            chans.append({"sampler": len(samps) - 1, "target": {"node": new[c["target"]["node"]], "path": c["target"]["path"]}})
        anims.append({"name": an["name"], "channels": chans, "samplers": samps})
    gltf = {"asset": {"version": "2.0", "generator": "Covenant clip library / tools/rig_character.py --library from " + os.path.basename(args.input)},
            "scene": 0, "scenes": [{"nodes": [0] + roots}], "nodes": nodes,
            "skins": [{"joints": [new[i] for i in joints], "inverseBindMatrices": out.f32(ibm, "MAT4")}],
            "meshes": [{"primitives": [{"attributes": attrs}]}], "animations": anims}
    size = write_glb(args.output, gltf, out)
    print("%s: %d bones, %d clips (%s), %d KB" % (args.output, len(joints), len(anims), ", ".join(a["name"] for a in anims), size // 1024))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--library", action="store_true", help="skeleton and clips only (for borrowing from)")
    ap.add_argument("--name", default="Character")
    ap.add_argument("--height", type=float, default=0.0, help="metres, feet to crown (default: as made)")
    ap.add_argument("--cycle", action="append", default=[], help="a walking clip to cut to one cycle on the spot")
    ap.add_argument("--seam", action="append", default=[], help="a looping clip whose end is eased into its start")
    ap.add_argument("--borrow", action="append", default=[], help="model.glb:clip,clip,... clips to fit from another model (theirs=ours renames one; *=ours takes a single-clip file's only clip)")
    ap.add_argument("--rename", action="append", default=[], help="theirs=ours: one of the model's own clips under our name")
    ap.add_argument("--texture-size", type=int, default=2048)
    ap.add_argument("--head-up", action="append", default=[], help="DEG:clip,clip,... lift the head in these clips")
    ap.add_argument("--hold-arm", action="append", default=[],
                    help="SIDE:FROM:clip,clip,... keep the Left/Right arm as it is in clip FROM (a walking stick's hand)")
    ap.add_argument("--normal-map", action="store_true", help="use the model's normal map (off by default: see above)")
    ap.add_argument("--double-sided", action="store_true")
    ap.add_argument("--free-of-arms", default="", help="R,G,B:TOL (0-1) a bag or strap of about this colour moves with the body, not an arm")
    args = ap.parse_args()
    (library if args.library else build)(args)


if __name__ == "__main__":
    main()
