"""Gives a Tripo3D creature that came rigged but without clips the duel's
clips, made by hand from its own bones: idle, attack, hit, defeat, spawn,
run, victory and guard (DuelField3D.CLIP_ALIASES reads them).

  python3 tools/creature_clips.py <rigged.glb> <out.glb> --kind turtle|warg

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
    # The Infernal Warg (Gary's, 27 November: Tripo Smart Mesh, rigged as a
    # four-legged animal, no clips). Facing +Z after glb_bake_turn.py, 1.0 m
    # nose to tail and 0.68 m high. Its bones by the flesh they carry: Root
    # (at the ground under its middle) the hindquarters and the tail, which
    # has no bones of its own; Spine_0 the middle of the back; Head_0 the
    # chest and shoulders, and both front legs hang from it; Head_1 the neck
    # (no flesh of its own), Head_2 the head and mane, Head_3 the lower jaw.
    # 0_Right_Limb is the front leg on its right (-X), 0_Left_Limb on its
    # left; 1_Right_Limb and 1_Left_Limb the hind legs; the bone_* at their
    # ends are toes.
    "warg": {
        "clips": "hound",
        "root": "tripo::Root", "spine": "tripo::Spine_0", "chest": "tripo::Head_0",
        "neck": "tripo::Head_1", "head": "tripo::Head_2", "jaw": "tripo::Head_3",
        "front_r": ["tripo::0_Right_Limb_0", "tripo::0_Right_Limb_1", "tripo::0_Right_Limb_2"],
        "front_l": ["tripo::0_Left_Limb_0", "tripo::0_Left_Limb_1", "tripo::0_Left_Limb_2"],
        "back_r": ["tripo::1_Right_Limb_0", "tripo::1_Right_Limb_1", "tripo::1_Right_Limb_2"],
        "back_l": ["tripo::1_Left_Limb_0", "tripo::1_Left_Limb_1", "tripo::1_Left_Limb_2"],
        "hind_z": -0.24,   # the hind feet, for rearing about
        "plant": True,
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


def hound_clips(k):
    """A big four-legged hunter: low and menacing at rest, a crouch and a
    lunge with the jaws, a gallop. Turns are about world axes at each bone's
    joint, and a bone's turn carries its children: +X pitches a head down or
    swings a hanging leg back, -X the other way; +Y turns to its left; +Z
    rolls its left side up."""
    R, S, C, N, H, J = k["root"], k["spine"], k["chest"], k["neck"], k["head"], k["jaw"]
    fr, fl, br, bl = k["front_r"], k["front_l"], k["back_r"], k["back_l"]

    def merge(*parts):
        out = {}
        for p in parts:
            for bone, m in p.items():
                o = out.setdefault(bone, {})
                if "rot" in m:
                    o["rot"] = o.get("rot", []) + list(m["rot"])
                if "move" in m:
                    a = np.array(o.get("move", (0, 0, 0)), np.float64) + np.array(m["move"], np.float64)
                    o["move"] = tuple(a)
                for key in ("pivot", "scale"):
                    if key in m:
                        o[key] = m[key]
        return out

    def leg(chain, swing, bend):
        """swing: the whole leg from the shoulder or hip (+ back); bend: the
        joint below folds, lifting the paw (measured on the Warg: its
        forelegs stand angled forward, so a foreleg's lower bone turned
        forward lifts the paw and turned back drops it; a hind leg's the
        other way round)."""
        front = chain in (fr, fl)
        out = {chain[0]: {"rot": [(X, swing)]}}
        if bend:
            out[chain[1]] = {"rot": [(X, -bend if front else bend)]}
        return out

    def idle(t):
        # low and watchful: slow deep breaths through the chest, the head
        # weaving a little, the jaw hanging open and panting heat; once a
        # cycle the head snaps round toward something and back
        T = 3.6
        a = 2 * math.pi * t / T
        breath = math.sin(a)
        look = keys(t, [(0, 0), (1.3, 0), (1.7, 1), (2.6, 1), (3.1, 0), (3.6, 0)])
        return {
            S: {"rot": [(X, -0.8 * breath)]},
            C: {"rot": [(X, 0.6 * breath), (Y, 1.0 * look)]},
            N: {"rot": [(X, 2.0 * math.sin(a + 0.7)), (Y, 9.0 * look + 3.0 * math.sin(0.5 * a))]},
            H: {"rot": [(X, -1.5 * math.sin(2 * a)), (Y, 5.0 * look), (Z, 2.0 * math.sin(0.5 * a + 1.0))]},
            J: {"rot": [(X, 6.0 + 4.0 * (0.5 + 0.5 * math.sin(2 * a + 0.4)) + 6.0 * look)]},
        }

    def attack(t):
        # gathers, crouching back on its haunches with the head down; drives
        # forward off the hind legs, forelegs reaching, the jaws wide; they
        # snap shut at the end of the lunge, and it draws back to stand
        gather = keys(t, [(0, 0), (0.32, 1), (0.42, 0), (1.25, 0)])
        lunge = keys(t, [(0, 0), (0.32, -0.15), (0.52, 1), (0.74, 1), (1.25, 0)])
        jaw = keys(t, [(0, 0.2), (0.3, 0.3), (0.5, 1.0), (0.62, 1.0), (0.7, -0.1), (0.85, 0.2), (1.25, 0.2)])
        L = max(0.0, lunge)
        return merge(
            {R: {"move": (0, -0.035 * gather + 0.03 * L, -0.05 * gather + 0.20 * L)},
             S: {"rot": [(X, 3.0 * gather - 4.0 * L)]},
             C: {"rot": [(X, 5.0 * gather - 6.0 * L)]},
             N: {"rot": [(X, 10.0 * gather - 12.0 * L)]},
             H: {"rot": [(X, 8.0 * gather - 10.0 * L)]},
             J: {"rot": [(X, 4.0 + 34.0 * jaw)]}},
            leg(fr, -6.0 * gather - 34.0 * L, 10.0 * gather + 16.0 * L),
            leg(fl, -6.0 * gather - 30.0 * L, 10.0 * gather + 14.0 * L),
            leg(br, -14.0 * gather + 30.0 * L, 18.0 * gather),
            leg(bl, -14.0 * gather + 26.0 * L, 18.0 * gather),
        )

    def hit(t):
        # knocked back: the front of it thrown up and away, the head wrenched
        # aside, and it gathers itself
        r = keys(t, [(0, 0), (0.09, 1), (0.3, 0.75), (0.75, 0)])
        return merge(
            {R: {"move": (0, 0, -0.07 * r)},
             S: {"rot": [(X, -3.0 * r), (Z, 3.0 * r)]},
             C: {"rot": [(X, -6.0 * r), (Z, 5.0 * r)]},
             N: {"rot": [(X, -14.0 * r), (Y, 16.0 * r)]},
             H: {"rot": [(X, -8.0 * r), (Y, 10.0 * r)]},
             J: {"rot": [(X, 6.0 + 22.0 * r)]}},
            leg(fr, 10.0 * r, 8.0 * r), leg(fl, 10.0 * r, 8.0 * r),
        )

    def defeat(t):
        # staggers, the forelegs going first, and goes down on its right
        # side; the head falls last and the jaw hangs
        stag = keys(t, [(0, 0), (0.25, 1), (0.5, 0.6), (0.7, 0)])
        roll = keys(t, [(0.35, 0), (1.25, 1.0), (1.4, 0.94), (1.55, 1.0), (2.0, 1.0)])
        sink = keys(t, [(0.25, 0), (0.75, 1.0), (2.0, 1.0)])
        head = keys(t, [(0.6, 0), (1.5, 1.0), (1.62, 0.9), (1.75, 1.0), (2.0, 1.0)])
        return merge(
            {R: {"rot": [(Z, 78.0 * roll)], "pivot": (-0.17, 0.0, 0.0), "move": (0, -0.03 * sink, -0.05 * stag)},
             C: {"rot": [(X, 6.0 * sink - 5.0 * stag)]},
             N: {"rot": [(X, 22.0 * head - 10.0 * stag), (Z, 12.0 * head)]},
             H: {"rot": [(X, 10.0 * head), (Z, 10.0 * head)]},
             J: {"rot": [(X, 4.0 + 16.0 * head)]}},
            leg(fr, 14.0 * sink, 26.0 * sink), leg(fl, 20.0 * sink, 30.0 * sink),
            leg(br, -8.0 * sink, 20.0 * sink), leg(bl, -14.0 * sink, 26.0 * sink),
        )

    def spawn(t):
        # rises out of a crouch, gives itself a shake, and throws its head up
        # in a roar
        up = keys(t, [(0, 0), (0.6, 1.0)])
        crouch = 1.0 - up
        s = keys(t, [(0, 0.86), (0.5, 1.03), (0.7, 1.0)])
        shake = math.sin((t - 0.55) * 2 * math.pi * 3.2) * keys(t, [(0.5, 0), (0.62, 1), (0.95, 0)])
        roar = keys(t, [(0.9, 0), (1.15, 1.0), (1.5, 1.0), (1.8, 0)])
        return merge(
            {R: {"move": (0, -0.05 * crouch, 0), "scale": s},
             S: {"rot": [(Z, 4.0 * shake)]},
             C: {"rot": [(X, 6.0 * crouch), (Z, 6.0 * shake)]},
             N: {"rot": [(X, 16.0 * crouch - 24.0 * roar), (Z, 9.0 * shake)]},
             H: {"rot": [(X, 6.0 * crouch - 10.0 * roar), (Z, 10.0 * shake)]},
             J: {"rot": [(X, 4.0 + 36.0 * roar)]}},
            leg(fr, -4.0 * crouch, 22.0 * crouch), leg(fl, -4.0 * crouch, 22.0 * crouch),
            leg(br, -10.0 * crouch, 24.0 * crouch), leg(bl, -10.0 * crouch, 24.0 * crouch),
        )

    def run(t):
        # a gallop: the forelegs land one after the other, then the hind
        # pair; the back flexes with the stride, the head holds steady
        T = 0.56
        ph = t / T
        parts = []
        for chain, off, amp in ((fr, 0.0, 30.0), (fl, 0.12, 30.0), (br, 0.5, 28.0), (bl, 0.62, 28.0)):
            a = 2 * math.pi * (ph + off)
            # forward on the swing (-X), back on the stance; the joint below
            # folds while it swings forward
            parts.append(leg(chain, amp * math.sin(a), 34.0 * max(0.0, math.cos(a))))
        a = 2 * math.pi * ph
        parts.append({
            R: {"move": (0, 0.022 * abs(math.sin(a + 0.4)), 0)},
            S: {"rot": [(X, 5.0 * math.sin(a))]},
            C: {"rot": [(X, -4.0 * math.sin(a + 0.6))]},
            N: {"rot": [(X, 4.0 * math.sin(a + 1.2) + 4.0)]},
            H: {"rot": [(X, -2.0 * math.sin(a + 1.2))]},
            J: {"rot": [(X, 10.0 + 3.0 * math.sin(2 * a))]},
        })
        return merge(*parts)

    def victory(t):
        # rears up off its forelegs, paws the air and howls, comes down
        rear = keys(t, [(0, 0), (0.4, 1), (1.3, 1), (1.8, 0)])
        paw = math.sin((t - 0.4) * 2 * math.pi * 1.6) * keys(t, [(0.35, 0), (0.5, 1), (1.2, 1), (1.35, 0)])
        howl = keys(t, [(0.3, 0), (0.6, 1), (1.3, 1), (1.6, 0)])
        return merge(
            {R: {"rot": [(X, -16.0 * rear)], "pivot": (0, 0, k["hind_z"])},
             C: {"rot": [(X, -4.0 * rear)]},
             N: {"rot": [(X, -26.0 * howl)]},
             H: {"rot": [(X, -14.0 * howl), (Y, 3.0 * paw)]},
             J: {"rot": [(X, 4.0 + 30.0 * howl)]}},
            leg(fr, -26.0 * rear - 14.0 * paw, 30.0 * rear + 10.0 * paw),
            leg(fl, -26.0 * rear + 14.0 * paw, 30.0 * rear - 10.0 * paw),
            leg(br, 18.0 * rear, 6.0 * rear), leg(bl, 18.0 * rear, 6.0 * rear),
        )

    def guard(t):
        # crouched to spring, head low, a growl trembling in the jaw
        T = 2.4
        a = 2 * math.pi * t / T
        return merge(
            {R: {"move": (0, -0.035, -0.02)},
             S: {"rot": [(X, 3.0 + 0.6 * math.sin(a))]},
             C: {"rot": [(X, 3.0)]},
             N: {"rot": [(X, 7.0 + 1.5 * math.sin(a))]},
             H: {"rot": [(X, 3.0), (Y, 2.0 * math.sin(7 * a))]},
             J: {"rot": [(X, 14.0 + 2.0 * math.sin(9 * a))]}},
            leg(fr, -8.0, 14.0), leg(fl, -8.0, 14.0), leg(br, -14.0, 20.0), leg(bl, -14.0, 20.0),
        )

    return {
        "idle": (3.6, True, idle), "attack": (1.25, False, attack), "hit": (0.75, False, hit),
        "defeat": (2.0, False, defeat), "spawn": (1.8, False, spawn), "run": (0.56, True, run),
        "victory": (1.8, False, victory), "guard": (2.4, True, guard),
    }


CLIPS = {"turtle": turtle_clips, "hound": hound_clips}


def ground_lifts(j, binc, rig, tracks, n):
    """For each frame, how far the whole creature must rise so that no part
    of it is below the ground (y 0): a crouch or a fall worked out as turns
    can push a foot or a flank through the floor, and this keeps it on top.
    Worked on every vertex a foot could be (low at rest) and one in six of
    the rest, through the skin as the game draws it (scale left out)."""
    from rig_character import acc
    mesh_node = next(i for i, nd in enumerate(j["nodes"]) if "skin" in nd and "mesh" in nd)
    prim = j["meshes"][j["nodes"][mesh_node]["mesh"]]["primitives"][0]
    at = prim["attributes"]
    P = acc(j, binc, at["POSITION"]).astype(np.float64)
    JN = acc(j, binc, at["JOINTS_0"]).astype(np.int64)
    WT = acc(j, binc, at["WEIGHTS_0"]).astype(np.float64)
    keep = (P[:, 1] < 0.08) | (np.arange(len(P)) % 6 == 0)
    P, JN, WT = P[keep], JN[keep], WT[keep]
    WT /= np.maximum(WT.sum(1, keepdims=True), 1e-9)
    skin = j["skins"][0]
    ibm = acc(j, binc, skin["inverseBindMatrices"]).astype(np.float64).reshape(-1, 4, 4).transpose(0, 2, 1)
    joints = skin["joints"]

    def qm(q):
        x, y, z, w = q
        return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    lifts = np.zeros(n)
    for fi in range(n):
        t = dict(rig.t)
        r = dict(rig.r)
        for i, tr in tracks.items():
            if len(tr["r"]) == n:
                r[i] = np.array(tr["r"][fi])
                t[i] = np.array(tr["t"][fi])
        wp, wq = rig.world(t, r)
        a = np.zeros((len(joints), 3))
        c = np.zeros(len(joints))
        for k, ji in enumerate(joints):
            R = qm(wq[ji])
            A = R @ ibm[k][:3, :3]
            a[k] = A[1]
            c[k] = (R @ ibm[k][:3, 3])[1] + wp[ji][1]
        y = np.zeros(len(P))
        for q in range(4):
            y += WT[:, q] * (np.einsum("ij,ij->i", a[JN[:, q]], P) + c[JN[:, q]])
        lifts[fi] = max(0.0, -float(y.min()))
    return lifts


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
    clips = CLIPS[k.get("clips", "turtle")](k)
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
        if k.get("plant"):
            lifts = ground_lifts(j, binc, rig, tracks, n)
            if lifts.max() > 1e-4:
                ri = idx[k["root"]]
                if ri not in tracks or len(tracks[ri]["t"]) != n:
                    tracks[ri] = {"r": [rig.r[ri]] * n, "t": [rig.t[ri]] * n, "s": [rig.s[ri]] * n, "used": set()}
                pq = rig.wq[parent[ri]] if ri in parent else np.array([0, 0, 0, 1.0])
                up = qrot(qinv(pq), np.array([0.0, 1.0, 0.0]))
                tracks[ri]["t"] = [np.array(tv) + up * lf for tv, lf in zip(tracks[ri]["t"], lifts)]
                tracks[ri]["used"].add("t")
                print("  %s: lifted up to %.1f cm to keep it on the ground" % (name, lifts.max() * 100))
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
