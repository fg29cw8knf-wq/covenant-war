#!/usr/bin/env python3
"""Finds (and with --fix, mends) skin weights that bind a model's clothes or
legs to its hand and finger bones: AssetFurnace weights by nearness, and in
the A-pose the fingertips hang beside the thighs, so a patch of a tunic's
skirt or a trouser leg can end up on a finger or hand bone. It never shows in
the idle, but the moment a hand is raised (the hand IK carrying the lantern
crate, a lift, a wave) that patch rises with it in a long streak (Gary, 22
October: "Player D, when he's holding the lanterns, his image becomes
distorted"; 353 of his triangles tied a finger to a leg).

A triangle with one corner mostly on a hand, finger or forearm bone and
another mostly on a body bone (hips, spine, a leg) tears when the hand moves.
Every such arm-side corner below the chest is cloth, not hand (a hand's own
vertices never share a triangle with the thighs): its arm weight is
moved to the body bone its neighbour is on, and the walk repeats until no
such triangle is left (the patch is taken back a ring at a time). The hands
and sleeves themselves, out at the wrists, are left alone.

    python3 tools/arm_weights.py assets/models/characters/player_d.glb            # report
    python3 tools/arm_weights.py assets/models/characters/player_d.glb --fix      # mend it in place
"""
import json, struct, sys
import numpy as np

ARM = ("Arm", "ForeArm", "Hand")   # (the Shoulder bones spread over the chest and back, rightly)
REACH = 0.11   # m from the arm's line before a vertex is cloth, not arm
NEAR = 0.075   # m from the forearm or hand's line within which a vertex is the arm itself

def read_glb(path):
    b = open(path, "rb").read()
    magic, ver, length = struct.unpack("<III", b[:12])
    assert magic == 0x46546C67
    off = 12
    chunks = []
    while off < length:
        cl, ct = struct.unpack("<II", b[off:off + 8])
        chunks.append([ct, bytearray(b[off + 8:off + 8 + cl])])
        off += 8 + cl
    return json.loads(chunks[0][1]), chunks[1][1], chunks

def write_glb(path, j, binc):
    js = json.dumps(j, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(binc) % 4:
        binc.append(0)
    total = 12 + 8 + len(js) + 8 + len(binc)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack("<II", len(binc), 0x004E4942)); f.write(binc)

COMP = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NUM = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}

def view(j, binc, acc_i):
    acc = j["accessors"][acc_i]
    bv = j["bufferViews"][acc["bufferView"]]
    code, size = COMP[acc["componentType"]]
    n = NUM[acc["type"]]
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", size * n)
    assert stride == size * n, "interleaved buffers aren't handled"
    arr = np.frombuffer(binc, dtype=np.dtype("<" + code), count=acc["count"] * n, offset=start).reshape(acc["count"], n)
    return arr, start, acc

def _seg_dist(p, segs, side, first):
    """Distance from p to the arm's segments from `first` on (1: the forearm and the hand)."""
    best = 1e9
    for a, b in segs.get(side, [])[first:]:
        ab = b - a
        t = float(np.clip(np.dot(p - a, ab) / max(np.dot(ab, ab), 1e-9), 0.0, 1.0))
        best = min(best, float(np.linalg.norm(p - (a + ab * t))))
    return best

def main():
    path = sys.argv[1]
    fix = "--fix" in sys.argv
    j, binc, chunks = read_glb(path)
    skin = j["skins"][0]
    names = [j["nodes"][ni].get("name", "") for ni in skin["joints"]]
    def is_arm(n):
        for side in ("Left", "Right"):
            if n.startswith(side) and n[len(side):].startswith(ARM):
                return True
        return False
    arm = np.array([is_arm(n) for n in names])
    hips = names.index("Hips") if "Hips" in names else 0
    # the joints' places in the bind pose (the inverse bind matrices, inverted)
    ibm, _, _ = view(j, binc, skin["inverseBindMatrices"])
    joint_at = {n: np.linalg.inv(ibm[i].reshape(4, 4).T)[:3, 3] for i, n in enumerate(names)}
    hip_y = float(joint_at["Hips"][1]) if "Hips" in joint_at else 0.0
    # each arm as a line of segments: shoulder, elbow, wrist, and on past the hand
    segs = {}
    for side in ("Left", "Right"):
        chain = [joint_at.get(side + b) for b in ("Arm", "ForeArm", "Hand")]
        if any(c is None for c in chain):
            continue
        tip = chain[2] + (chain[2] - chain[1]) / max(np.linalg.norm(chain[2] - chain[1]), 1e-6) * 0.2
        segs[side] = [(chain[0], chain[1]), (chain[1], chain[2]), (chain[2], tip)]
    def dist_to_arm(p, side):
        best = 1e9
        for a, b in segs.get(side, []):
            ab = b - a
            t = float(np.clip(np.dot(p - a, ab) / max(np.dot(ab, ab), 1e-9), 0.0, 1.0))
            best = min(best, float(np.linalg.norm(p - (a + ab * t))))
        return best
    side_of = np.array([("Left" if n.startswith("Left") else "Right") if is_arm(n) else "" for n in names])
    hip_y = float(joint_at["Hips"][1]) if "Hips" in joint_at else 0.0
    wrists = [abs(float(joint_at[sd + "Hand"][0])) for sd in ("Left", "Right") if sd + "Hand" in joint_at]
    # (a hand's own vertices never share a triangle with the thighs, so below the
    # chest the torn triangles alone pick the cloth out; no width test is needed)
    limit = 9.0
    top = hip_y + 0.1                                   # below this it's the skirt and the legs
    total = moved = rounds = 0
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            at = prim["attributes"]
            if "JOINTS_0" not in at or "indices" not in prim:
                continue
            pos, _, _ = view(j, binc, at["POSITION"])
            jn, _, _ = view(j, binc, at["JOINTS_0"])
            w, wstart, wacc = view(j, binc, at["WEIGHTS_0"])
            assert wacc["componentType"] == 5126, "weights aren't floats"
            w = w.copy()
            idx, _, _ = view(j, binc, prim["indices"])
            idx = idx.reshape(-1, 3)
            first = True
            while True:
                heaviest = np.argmax(w, axis=1)
                hb = jn[np.arange(len(pos)), heaviest]
                varm = arm[hb]
                tear = varm[idx].any(axis=1) & (~varm[idx]).any(axis=1)
                tris = idx[tear]
                low = (np.abs(pos[:, 0]) < limit) & (pos[:, 1] < top)
                cloth = {}
                for t in tris:
                    body_corners = [v for v in t if not varm[v]]
                    for v in t:
                        if varm[v] and low[v] and v not in cloth:
                            # the body bone to take it: its neighbour's heaviest
                            cloth[int(v)] = int(hb[body_corners[0]])
                if first:
                    total += int(tear.sum())
                    moved += len(cloth)
                    first = False
                    if "--where" in sys.argv and cloth:
                        vs = np.array(list(cloth.keys()))
                        print("   torn: %d triangles; cloth on a hand or finger: %d vertices, |x| %.2f..%.2f, y %.2f..%.2f, bones %s" % (tear.sum(), len(vs),
                            np.abs(pos[vs, 0]).min(), np.abs(pos[vs, 0]).max(), pos[vs, 1].min(), pos[vs, 1].max(), sorted(set(names[b] for b in hb[vs]))[:6]))
                if not fix or not cloth:
                    break
                for v, to in cloth.items():
                    lost = float(w[v][arm[jn[v]]].sum())
                    w[v][arm[jn[v]]] = 0.0
                    slot = [k for k in range(4) if jn[v][k] == to]
                    if slot:
                        w[v][slot[0]] += lost
                    else:
                        k = int(np.argmin(w[v]))
                        jn_w = jn[v].copy(); jn_w[k] = to
                        jstart = view(j, binc, at["JOINTS_0"])[1]
                        jsize = COMP[j["accessors"][at["JOINTS_0"]]["componentType"]][1]
                        binc[jstart + v * 4 * jsize: jstart + (v + 1) * 4 * jsize] = np.asarray(jn_w, dtype=view(j, binc, at["JOINTS_0"])[0].dtype).tobytes()
                        jn = view(j, binc, at["JOINTS_0"])[0]
                        w[v][k] = lost
                rounds += 1
                moved += 0
            if fix:
                binc[wstart: wstart + w.nbytes] = np.ascontiguousarray(w, dtype="<f4").tobytes()
    print("%s: %d triangles tie a hand or finger to the body; %d cloth vertices on a hand%s" % (path, total, moved, (" (moved to the body in %d rounds)" % rounds) if fix and moved else ""))
    if fix and moved:
        write_glb(path, j, binc)

if __name__ == "__main__":
    main()
