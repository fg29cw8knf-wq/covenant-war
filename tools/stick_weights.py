#!/usr/bin/env python3
"""Makes a walking stick that's part of a character's mesh rigid: every vertex
of the stick is bound to the hand that holds it, and nothing else.

AssetFurnace weights by nearness, so Old Nell's stick (in her right hand,
its foot on the ground beside her boot) came out bound to her middle finger
bones at the top and to her toes at the bottom. It held still in her idle and
in every clip whose right arm is kept as in the idle (tools/rig_villager.sh,
--hold-arm), but in her dance the fingers and the feet pull its two ends
different ways and it bends and stretches (Gary, 23 October: "the old
woman's cane warps out of shape as she dances").

The stick is found as the thin upright column hanging below the hand in the
bind pose: a line is fitted through the vertices in that column, and every
vertex within the stick's radius of the line, from the ground up to just
above the hand, goes 100% to the hand bone. The hand's own vertices wrapped
round the grip may be taken with it, which is right: fingers on a stick don't
flex.

    python3 tools/stick_weights.py assets/models/characters/nell.glb            # report
    python3 tools/stick_weights.py assets/models/characters/nell.glb --fix      # mend it in place
    python3 tools/stick_weights.py <model.glb> --fix --side Left --radius 0.04
"""
import sys
import numpy as np

sys.path.insert(0, __file__.rsplit("/", 1)[0] if "/" in __file__ else ".")
from arm_weights import read_glb, write_glb, view, COMP   # noqa: E402


def arg(flag, default):
    if flag in sys.argv:
        return sys.argv[sys.argv.index(flag) + 1]
    return default


def main():
    path = sys.argv[1]
    fix = "--fix" in sys.argv
    side = arg("--side", "Right")
    radius = float(arg("--radius", "0.035"))
    j, binc, chunks = read_glb(path)
    skin = j["skins"][0]
    names = [j["nodes"][ni].get("name", "") for ni in skin["joints"]]
    hand = names.index(side + "Hand")
    ibm, _, _ = view(j, binc, skin["inverseBindMatrices"])
    joint_at = {n: np.linalg.inv(ibm[i].reshape(4, 4).T)[:3, 3] for i, n in enumerate(names)}
    h = joint_at[side + "Hand"]
    knee = joint_at.get(side + "Leg", joint_at.get("Hips"))
    changed = 0
    for mesh in j["meshes"]:
        for prim in mesh["primitives"]:
            at = prim["attributes"]
            if "JOINTS_0" not in at:
                continue
            pos, _, _ = view(j, binc, at["POSITION"])
            jn, jstart, jacc = view(j, binc, at["JOINTS_0"])
            w, wstart, wacc = view(j, binc, at["WEIGHTS_0"])
            assert wacc["componentType"] == 5126, "weights aren't floats"
            # the column below the hand, on the hand's side of the body and
            # in front of the leg (the stick stands beside and ahead of the
            # boot; the skirt's hem hangs round the leg itself)
            sx = 1.0 if h[0] >= 0 else -1.0
            below = ((pos[:, 1] < h[1] - 0.12) & (pos[:, 1] > 0.02) & (pos[:, 0] * sx > abs(knee[0]) + 0.08)
                & (pos[:, 2] > knee[2] + 0.18))
            if below.sum() < 20:
                continue
            # the stick's axis: a line through the column's centre, fitted top to bottom
            col = pos[below]
            c = col.mean(axis=0)
            u, s, vt = np.linalg.svd(col - c)
            axis = vt[0] / np.linalg.norm(vt[0])
            if axis[1] < 0:
                axis = -axis
            # tighten: keep only the vertices within the radius of that line, refit once
            rel = pos - c
            d = np.linalg.norm(rel - np.outer(rel @ axis, axis), axis=1)
            tight = below & (d < radius * 1.6)
            col = pos[tight]
            c = col.mean(axis=0)
            u, s, vt = np.linalg.svd(col - c)
            axis = vt[0] / np.linalg.norm(vt[0])
            if axis[1] < 0:
                axis = -axis
            rel = pos - c
            along = rel @ axis
            d = np.linalg.norm(rel - np.outer(along, axis), axis=1)
            top = float(((h - c) @ axis)) + 0.12          # a little above the hand (a knob, the grip)
            stick = (d < radius) & (pos[:, 1] > 0.0) & (along < top) & (pos[:, 1] < h[1] + 0.12)
            n = int(stick.sum())
            if n == 0:
                continue
            heaviest = jn[np.arange(len(pos)), np.argmax(w, axis=1)]
            bones = {}
            for b in heaviest[stick]:
                bones[names[b]] = bones.get(names[b], 0) + 1
            print("%s: the stick is %d vertices, %.2f m tall, %.1f cm across, bound to %s" % (
                path, n, float(along[stick].max() - along[stick].min()), 2.0 * float(d[stick].max()) * 100.0,
                ", ".join("%s %d" % kv for kv in sorted(bones.items(), key=lambda kv: -kv[1]))))
            if not fix:
                continue
            jn = jn.copy()
            w = w.copy()
            jn[stick] = [hand, 0, 0, 0]
            w[stick] = [1.0, 0.0, 0.0, 0.0]
            jsize = COMP[jacc["componentType"]][1]
            binc[jstart: jstart + len(pos) * 4 * jsize] = np.ascontiguousarray(jn, dtype=jn.dtype).tobytes()
            binc[wstart: wstart + w.nbytes] = np.ascontiguousarray(w, dtype="<f4").tobytes()
            changed += n
    if fix and changed:
        write_glb(path, j, binc)
        print("%s: %d vertices now follow the %s hand alone" % (path, changed, side.lower()))


if __name__ == "__main__":
    main()
