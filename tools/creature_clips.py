"""Gives a Tripo3D creature that came rigged but without clips the duel's
clips, made by hand from its own bones: idle, attack, hit, defeat, spawn,
run, victory and guard (DuelField3D.CLIP_ALIASES reads them).

  python3 tools/creature_clips.py <rigged.glb> <out.glb> --kind turtle

Run tools/glb_bake_turn.py on Tripo's export first (its joints are placed by
matrices and the figure is turned a quarter round above them), and
tools/split_creature.py on the result after.

Each clip is a few moves on named bones, written as turns about world axes
(the creature faces +Z, +X is its left, +Y up) and shifts in metres, eased
in and out between keys; a bone's turn is about its own joint, so its
children go with it. The shapes of a creature's body (which bone is its
shell, its neck, each leg) are in KINDS, found from where each bone's
flesh sits (the bone each vertex leans on most).

Shellguard (Gary's coral turtle, 2 November): Tripo's auto-rig named the
bones loosely, so they're mapped here by what they move: Spine_0 carries
the shell and body, bone_3 the neck and bone_4 the head, 1_Right_Limb the
front right leg and 0_Right_Limb the front left, 1_Left_Limb the back right
and Spine_2 the back left, Spine_3 the tail. The guard clip draws head and
legs in under the shell: its stance in a duel.
"""
import argparse, json, math, os, struct, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import Rig, qmul, qinv, qnorm, qrot  # noqa: E402

FPS = 30

KINDS = {
    "turtle": {
        "body": "tripo::Spine_0", "root": "tripo::Root",
        "neck": "bone_3", "head": "bone_4",
        "front_r": ["tripo::1_Right_Limb_1", "tripo::1_Right_Limb_2"],
        "front_l": ["tripo::0_Right_Limb_1", "tripo::0_Right_Limb_2"],
        "back_r": ["tripo::1_Left_Limb_0", "tripo::1_Left_Limb_1"],
        "back_l": ["tripo::Spine_2"],
        "tail": "tripo::Spine_3",
    },
}


def aa(axis, deg):
    axis = np.asarray(axis, np.float64)
    axis = axis / np.linalg.norm(axis)
    h = math.radians(deg) * 0.5
    return np.array([*(axis * math.sin(h)), math.cos(h)])


def ease(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def keys(t, pts):
    """A value along keyed points [(time, value)...], eased between them."""
    if t <= pts[0][0]:
        return pts[0][1]
    for (t0, v0), (t1, v1) in zip(pts, pts[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * ease((t - t0) / max(1e-6, t1 - t0))
    return pts[-1][1]


X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)


def turtle_clips(k):
    """{clip: (length, loop, f(t) -> {bone: {"rot": [(axis, deg)...], "move": xyz, "scale": s}})}"""
    B, N, H = k["body"], k["neck"], k["head"]
    legs_f = k["front_r"][:1] + k["front_l"][:1]

    def pose(**bones):
        return bones

    def idle(t):
        T = 3.2
        a = 2 * math.pi * t / T
        return {
            B: {"rot": [(X, 0.8 * math.sin(a))], "move": (0, 0.004 * (1 - math.cos(a)) * 0.5, 0)},
            N: {"rot": [(X, 2.5 * math.sin(2 * a + 0.6)), (Y, 6.0 * math.sin(a))]},
            H: {"rot": [(X, -2.0 * math.sin(2 * a)), (Y, 4.0 * math.sin(a + 0.8))]},
            k["tail"]: {"rot": [(Y, 6.0 * math.sin(a))]},
        }

    def attack(t):
        # draws its head back, then the shell and head drive forward (a ram
        # and a snap), and settles
        back = keys(t, [(0, 0), (0.32, 1), (0.42, -1.0), (0.62, -1.0), (1.1, 0)])
        lunge = keys(t, [(0, 0), (0.32, -0.25), (0.45, 1), (0.62, 1), (1.1, 0)])
        out = {
            k["root"]: {"move": (0, 0.012 * max(0.0, lunge), 0.09 * lunge)},
            B: {"rot": [(X, -4.0 * max(0.0, back) + 3.0 * max(0.0, -back))]},
            N: {"rot": [(X, -14.0 * max(0.0, back) + 16.0 * max(0.0, -back))], "move": (0, 0, -0.03 * max(0.0, back) + 0.05 * max(0.0, -back))},
            H: {"rot": [(X, -8.0 * max(0.0, back) + 14.0 * max(0.0, -back))]},
        }
        for i, leg in enumerate(legs_f):
            out[leg] = {"rot": [(X, -14.0 * max(0.0, lunge))]}
        return out

    def hit(t):
        r = keys(t, [(0, 0), (0.1, 1), (0.28, 0.8), (0.7, 0)])
        return {
            k["root"]: {"move": (0, 0, -0.05 * r)},
            B: {"rot": [(X, -6.0 * r), (Z, 3.0 * r)]},
            N: {"rot": [(X, -12.0 * r)], "move": (0, 0, -0.045 * r)},
            H: {"rot": [(X, -10.0 * r), (Y, 8.0 * r)]},
        }

    def defeat(t):
        d = keys(t, [(0, 0), (0.25, -0.15), (1.1, 1.0), (1.6, 1.0)])
        h = keys(t, [(0, 0), (0.5, 0.3), (1.3, 1.0), (1.6, 1.0)])
        out = {
            k["root"]: {"move": (0, -0.07 * d, 0)},
            B: {"rot": [(X, 5.0 * d), (Z, -4.0 * d)]},
            N: {"rot": [(X, 30.0 * h), (Y, -10.0 * h)]},
            H: {"rot": [(X, 18.0 * h)]},
            k["tail"]: {"rot": [(X, 10.0 * d)]},
        }
        # the legs give way, splaying out sideways under the sinking shell
        out[k["front_r"][0]] = {"rot": [(Z, 28.0 * d)]}
        out[k["front_l"][0]] = {"rot": [(Z, -28.0 * d)]}
        out[k["back_r"][0]] = {"rot": [(Z, 22.0 * d)]}
        out[k["back_l"][0]] = {"rot": [(Z, -22.0 * d)]}
        return out

    def spawn(t):
        # comes out of its shell: rises from tucked, the head last, a shake
        g = 1.0 - keys(t, [(0, 0), (0.55, 1.0)])
        s = keys(t, [(0, 0.82), (0.45, 1.04), (0.7, 1.0)])
        head = keys(t, [(0, 1.0), (0.45, 1.0), (0.8, 0), (1.3, 0)])
        shake = math.sin(t * 2 * math.pi * 3.0) * keys(t, [(0.8, 0), (0.95, 1), (1.3, 0)])
        out = guard_pose(g)
        out.setdefault(k["root"], {})["scale"] = s
        out[N] = {"rot": [(X, -6.0 * head), (Y, 10.0 * shake)], "move": (0, -0.02 * head, -0.08 * head)}
        out[H] = {"rot": [(X, -6.0 * head), (Y, 6.0 * shake)]}
        return out

    def run(t):
        T = 0.72
        a = 2 * math.pi * t / T
        sw = 20.0 * math.sin(a)
        return {
            k["root"]: {"move": (0, 0.012 * abs(math.sin(a)), 0)},
            B: {"rot": [(Z, 2.0 * math.sin(a))]},
            k["front_r"][0]: {"rot": [(X, -sw)]},
            k["back_l"][0]: {"rot": [(X, -sw)]},
            k["front_l"][0]: {"rot": [(X, sw)]},
            k["back_r"][0]: {"rot": [(X, sw)]},
            N: {"rot": [(X, -6.0 + 3.0 * math.sin(2 * a))], "move": (0, 0, 0.02)},
            k["tail"]: {"rot": [(Y, 10.0 * math.sin(a))]},
        }

    def victory(t):
        rear = keys(t, [(0, 0), (0.35, 1), (1.15, 1), (1.6, 0)])
        shake = math.sin((t - 0.35) * 2 * math.pi * 2.2) * keys(t, [(0.3, 0), (0.5, 1), (1.0, 1), (1.2, 0)])
        out = {
            # the front comes up off the ground, pivoting on the back feet
            k["root"]: {"rot": [(X, -9.0 * rear)], "pivot": (0, 0, -0.3)},
            N: {"rot": [(X, -22.0 * rear), (Y, 14.0 * shake)], "move": (0, 0.01 * rear, 0.03 * rear)},
            H: {"rot": [(X, -12.0 * rear), (Y, 10.0 * shake)]},
            k["tail"]: {"rot": [(Y, 14.0 * shake)]},
        }
        out[k["front_r"][0]] = {"rot": [(X, -18.0 * rear), (Z, 10.0 * rear)]}
        out[k["front_l"][0]] = {"rot": [(X, -18.0 * rear), (Z, -10.0 * rear)]}
        return out

    def guard_pose(g):
        return {
            k["root"]: {"move": (0, -0.035 * g, 0)},
            N: {"rot": [(X, -8.0 * g)], "move": (0, -0.03 * g, -0.11 * g)},
            H: {"rot": [(X, 6.0 * g)]},
            k["front_r"][0]: {"rot": [(Y, -30.0 * g), (Z, -12.0 * g)]},
            k["front_l"][0]: {"rot": [(Y, 30.0 * g), (Z, 12.0 * g)]},
            k["back_r"][0]: {"rot": [(Y, 25.0 * g), (Z, -10.0 * g)]},
            k["back_l"][0]: {"rot": [(Y, -25.0 * g), (Z, 10.0 * g)]},
            k["tail"]: {"rot": [(X, -15.0 * g)]},
        }

    def guard(t):
        T = 2.4
        out = guard_pose(1.0)
        out[k["body"]] = {"move": (0, 0.003 * (1 - math.cos(2 * math.pi * t / T)) * 0.5, 0)}
        return out

    return {
        "idle": (3.2, True, idle), "attack": (1.1, False, attack), "hit": (0.7, False, hit),
        "defeat": (1.6, False, defeat), "spawn": (1.3, False, spawn), "run": (0.72, True, run),
        "victory": (1.6, False, victory), "guard": (2.4, True, guard),
    }


def build(src, dst, kind):
    b = open(src, "rb").read()
    off, chunks = 12, []
    while off < len(b):
        cl, ct = struct.unpack_from("<II", b, off)
        chunks.append([ct, bytearray(b[off + 8:off + 8 + cl])])
        off += 8 + cl
    j = json.loads(bytes(chunks[0][1]))
    binc = chunks[1][1]
    assert not any("matrix" in n for n in j["nodes"]), "run tools/glb_bake_turn.py on it first"
    rig = Rig(j, binc)
    idx = {j["nodes"][i].get("name"): i for i in range(len(j["nodes"]))}
    parent = rig.parent
    k = KINDS[kind]
    clips = turtle_clips(k)
    j.setdefault("animations", [])
    j["animations"] = [a for a in j["animations"] if a.get("name") not in clips]

    def add(arr, typ):
        arr = np.ascontiguousarray(arr, "<f4")
        while len(binc) % 4:
            binc.append(0)
        bo = len(binc)
        binc.extend(arr.tobytes())
        j["bufferViews"].append({"buffer": 0, "byteOffset": bo, "byteLength": arr.nbytes})
        acc = {"bufferView": len(j["bufferViews"]) - 1, "componentType": 5126, "count": len(arr), "type": typ}
        if typ == "SCALAR":
            acc["min"], acc["max"] = [float(arr.min())], [float(arr.max())]
        j["accessors"].append(acc)
        return len(j["accessors"]) - 1

    for name, (length, loop, f) in clips.items():
        n = int(round(length * FPS)) + 1
        times = np.arange(n, dtype=np.float64) / FPS
        tracks = {}
        for fi, t in enumerate(times):
            moves = f(t if not loop else t % length)
            for bone, m in moves.items():
                i = idx[bone]
                tr = tracks.setdefault(i, {"r": [], "t": [], "s": [], "used": set()})
                rest_r, rest_t = rig.r[i], rig.t[i]
                gq = rig.wq[i]
                pq = rig.wq[parent[i]] if i in parent else np.array([0, 0, 0, 1.0])
                D = np.array([0, 0, 0, 1.0])
                for axis, deg in m.get("rot", []):
                    D = qmul(aa(axis, deg), D)
                local_d = qmul(qinv(gq), qmul(D, gq))
                tr["r"].append(qnorm(qmul(rest_r, local_d)))
                mv = np.array(m.get("move", (0, 0, 0)), np.float64)
                if "pivot" in m:
                    # turn about a point (world, relative to the bone) rather than the joint
                    pv = np.array(m["pivot"], np.float64)
                    mv = mv + (pv - qrot(D, pv))
                tr["t"].append(rest_t + qrot(qinv(pq), mv))
                tr["s"].append(rig.s[i] * float(m.get("scale", 1.0)))
                tr["used"] |= {"r"} if m.get("rot") else set()
                tr["used"] |= {"t"} if ("move" in m or "pivot" in m) else set()
                tr["used"] |= {"s"} if "scale" in m else set()
        # a bone a clip moves in some frames is keyed in all of them (rest where it's still)
        anim = {"name": name, "samplers": [], "channels": []}
        tin = add(times.astype(np.float32), "SCALAR")
        for i in tracks:
            pass
        all_bones = set(tracks)
        for i in all_bones:
            tr = tracks[i]
            for path, key, typ in (("rotation", "r", "VEC4"), ("translation", "t", "VEC3"), ("scale", "s", "VEC3")):
                if key not in tr["used"]:
                    continue
                vals = np.array(tr[key])
                if len(vals) != n:
                    continue
                anim["samplers"].append({"input": tin, "output": add(vals, typ), "interpolation": "LINEAR"})
                anim["channels"].append({"sampler": len(anim["samplers"]) - 1, "target": {"node": i, "path": path}})
        j["animations"].append(anim)
        print("clip %-8s %.2f s%s, %d bones" % (name, length, " (loops)" if loop else "", len(all_bones)))
    j["buffers"][0]["byteLength"] = len(binc)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    while len(binc) % 4:
        binc.append(0)
    out = [struct.pack("<II", len(js), 0x4E4F534A) + js, struct.pack("<II", len(binc), 0x004E4942) + bytes(binc)]
    for ct, data in chunks[2:]:
        out.append(struct.pack("<II", len(data), ct) + bytes(data))
    body = b"".join(out)
    open(dst, "wb").write(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)
    print("wrote", dst)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--kind", default="turtle", choices=sorted(KINDS))
    a = ap.parse_args()
    build(a.input, a.output, a.kind)
