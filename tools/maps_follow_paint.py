"""Makes a model's normal and roughness maps agree with paint Claude changed.

Tripo3D works a model's normal and roughness-metal maps out from its own
colour picture. Where that colour is put right afterwards, the maps still
describe the old paint. Player A's (26 November) are the case: the green of
the waistcoat painted on the underside of his sleeves (taken off by
tools/clean_under_arms.py) was given the waistcoat's roughness, so each
patch would still stand out on the shirt as a duller, rougher spot; and his
eyeballs (repainted by tools/paint_eyeballs.py) carry small bumps where the
smear of blue was. His freckles and his scar (tools/paint_face_marks.py) are
the skin's own surface and are left as they are.

  python3 tools/maps_follow_paint.py MODEL.glb MAKERS.png PAINTED.png NORMAL.png MR.png
      [--eye-roughness 0.22] [--report DIR]

MAKERS.png is the maker's colour picture, PAINTED.png the one in the game;
the texels where the two differ are what was repainted. NORMAL.png and
MR.png (the game's, laid out as the picture is) are rewritten in place.

  - On the eyeballs (within the lids' opening round each eye, on the front
    of the head): flat (no bump), not metal, and wet: --eye-roughness, so a
    light shows in them as a small bright point.
  - On the arms: the roughness and metal of the same sleeve round it (the
    middle of the unrepainted texels on the same arm within 3 cm along it),
    and the bump eased flat, so the patch reads as the linen round it.
Each is feathered in by how much the colour changed, so the edges don't
show.

Then two things Tripo's PBR does to skin that the rest of the cast doesn't
have (seen in his portrait, the evening of 26 November):
  - Shine. It made his skin glossy (roughness 0.58 in the middle, where Bram's
    is 0.80 and Hale's 0.69), and under the game's lights he looked oiled.
    The skin's roughness is lifted toward --skin-roughness (0.76), keeping
    which parts are shinier than which (the lips, the tip of the nose), and
    nothing on the front of his face below the hairline is left shinier than
    --face-floor (0.70): the tail of his left eyebrow, painted dark and so not
    taken for skin, caught the light as a wet spot.
  - Ridges. Its normal map is worked out from the colour, so every hard edge
    in the paint stands up as a bump: the line of his eyebrows, the hairline,
    the strands of hair painted on his forehead, the collar's edge. Under a
    low light they shone as white slashes. A texel's tilt is eased under a
    ceiling, gently (the fine grain under it is kept): --skin-tilt (0.10, about
    six degrees) on his head and neck and on skin anywhere, --tilt (0.40)
    everywhere else.
  - Gloss everywhere else (27 November, young Bram's Smart Mesh file): his
    grey hair and beard came at roughness 0.08 and the snow on his
    shoulders at 0.06, mirrors, so each strand's edge flashed white. On the
    head, what isn't skin or an eye is lifted to --hair-roughness (0.65);
    anywhere, what isn't metal or an eye to --floor (0.35).
Then the maps' gutters are filled again, as the picture's were.
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from atlas_paint import Body, texels, at_texels, covered, regutter  # noqa: E402
from paint_eyeballs import find_eyes, smooth  # noqa: E402

Image.MAX_IMAGE_PIXELS = None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model")
    ap.add_argument("makers")
    ap.add_argument("painted")
    ap.add_argument("normal")
    ap.add_argument("mr")
    ap.add_argument("--eye-roughness", type=float, default=0.22)
    ap.add_argument("--eye", action="append", default=[], metavar="X,Y",
                    help="an eye's middle as seen from the front (metres), when the finder can't tell them from "
                         "grey hair; give both. An eye that wasn't repainted is taken as an almond --eye-size round it")
    ap.add_argument("--eye-size", default="0.0105,0.0042", metavar="HALF_W,HALF_H",
                    help="the almond of an eye not repainted: its half-width and half-height (metres)")
    ap.add_argument("--skin-roughness", type=float, default=0.76, help="the skin's middle roughness after (0: left as made)")
    ap.add_argument("--skin-tilt", type=float, default=0.10)
    ap.add_argument("--face-floor", type=float, default=0.70)
    ap.add_argument("--hair-roughness", type=float, default=0.65,
                    help="nothing on the head but skin and the eyes left shinier than this (hair, beard, brows)")
    ap.add_argument("--floor", type=float, default=0.35,
                    help="nothing anywhere left shinier than this but metal and the eyes")
    ap.add_argument("--tilt", type=float, default=0.40)
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    body = Body(args.model)
    old = np.asarray(Image.open(args.makers).convert("RGB")).astype(np.float64) / 255.0
    new = np.asarray(Image.open(args.painted).convert("RGB")).astype(np.float64) / 255.0
    H, W = old.shape[:2]
    nm_img = Image.open(args.normal)
    mr_img = Image.open(args.mr)
    mr_mode = mr_img.mode
    nm = np.asarray(nm_img.convert("RGB")).astype(np.float64) / 255.0
    mr = np.asarray(mr_img.convert("RGBA")).astype(np.float64) / 255.0
    # the maps may be smaller than the picture: worked at their size
    if nm.shape[:2] != (H, W) or mr.shape[:2] != (H, W):
        sys.exit("the maps (%s, %s) aren't the picture's size %dx%d" % (nm.shape[:2], mr.shape[:2], W, H))
    diff = np.abs(new - old).max(2)
    how = smooth(0.012, 0.06, diff).reshape(-1)       # how surely a texel was repainted
    flat_nm, flat_mr = nm.reshape(-1, 3), mr.reshape(-1, 4)
    changed = np.zeros(W * H, bool)
    cen = body.pos[body.idx].mean(1)

    # ---- the eyeballs
    eyes = [tuple(float(v) for v in e.split(",")) for e in args.eye] or [e[:2] for e in find_eyes(body, old, W, H)]
    if len(eyes) != 2:
        sys.exit("expected two eyes, found %d: give them with --eye X,Y --eye X,Y" % len(eyes))
    ew, eh = (float(v) for v in args.eye_size.split(","))
    head = body.share("Head", "Neck")
    n_eye = 0
    eye_px = []
    for ex, ey in eyes:
        near = (np.abs(cen[:, 0] - ex) < 0.016) & (np.abs(cen[:, 1] - ey) < 0.010) & (head[body.idx].min(1) > 0.5)
        near &= cen[:, 2] > body.joint_at["Head"][2]
        pix, tri, bary = texels(body, np.where(near)[0], W, H)
        p = at_texels(body, body.pos, tri, bary)
        inside = (np.abs(p[:, 0] - ex) < 0.011) & (np.abs(p[:, 1] - ey) < 0.0062)
        pix, p = pix[inside], p[inside]
        a = how[pix][:, None]
        if a.sum() < 50:
            # the maker painted this eye and it was left as it was: its open
            # almond, from its middle, the edge feathered over a millimetre
            r = np.sqrt(((p[:, 0] - ex) / ew) ** 2 + ((p[:, 1] - ey) / eh) ** 2)
            a = (1.0 - smooth(0.85, 1.15, r))[:, None]
        flat_nm[pix] = flat_nm[pix] * (1 - a) + np.array([0.5, 0.5, 1.0]) * a
        flat_mr[pix, 1] = flat_mr[pix, 1] * (1 - a[:, 0]) + args.eye_roughness * a[:, 0]
        flat_mr[pix, 2] = flat_mr[pix, 2] * (1 - a[:, 0])
        changed[pix[a[:, 0] > 0.01]] = True
        eye_px.append(pix[a[:, 0] > 0.01])
        n_eye += int((a[:, 0] > 0.01).sum())
    print("eyeballs: %d texels made flat and wet (roughness %.2f)" % (n_eye, args.eye_roughness))

    # ---- the sleeves
    for side in ("Left", "Right"):
        arm = body.share(side + "Arm", side + "ForeArm")
        tris = np.where(arm[body.idx].min(1) > 0.5)[0]
        pix, tri, bary = texels(body, tris, W, H)
        p = at_texels(body, body.pos, tri, bary)
        s0 = body.joint_at[side + "Arm"]
        s1 = body.joint_at[side + "ForeArm"]
        d = (s1 - s0) / np.linalg.norm(s1 - s0)
        along = (p - s0) @ d
        rep = how[pix] > 0.01
        if not rep.any():
            print("%s arm: nothing repainted" % side.lower())
            continue
        bins = np.round(along / 0.01).astype(int)
        r_ref, m_ref = np.zeros(len(pix)), np.zeros(len(pix))
        for b in np.unique(bins[rep]):
            ring = (~rep) & (np.abs(bins - b) <= 3)
            if ring.sum() < 40:
                ring = ~rep
            r_ref[bins == b] = np.median(flat_mr[pix[ring], 1])
            m_ref[bins == b] = np.median(flat_mr[pix[ring], 2])
        sel = np.where(rep)[0]
        q = pix[sel]
        a = how[q]
        before = flat_mr[q, 1].copy()
        flat_mr[q, 1] = flat_mr[q, 1] * (1 - a) + r_ref[sel] * a
        flat_mr[q, 2] = flat_mr[q, 2] * (1 - a) + m_ref[sel] * a
        flat_nm[q] = flat_nm[q] * (1 - a[:, None]) + np.array([0.5, 0.5, 1.0]) * a[:, None]
        changed[q] = True
        print("%s arm: %d texels, roughness %.2f there now %.2f (the sleeve round it), %.0f to %.0f cm down the arm"
              % (side.lower(), len(q), np.median(before), np.median(flat_mr[q, 1]),
                 along[sel].min() * 100, along[sel].max() * 100))

    # ---- skin: its shine, and the ridges at the paint's edges
    lum = new.reshape(-1, 3) @ np.array([0.30, 0.59, 0.11])
    c = new.reshape(-1, 3)
    skin = smooth(0.10, 0.18, c[:, 0] - c[:, 1]) * smooth(0.40, 0.50, lum) * smooth(0.50, 0.60, c[:, 0])
    # (the hands are painted darker than the face, in the shade of the body:
    # young Bram's, 27 November, at a quarter of white, so they weren't taken
    # for skin and kept Tripo's gloss, and cupped for the child they shone
    # like wet clay. On the hands, the skin's hue is enough)
    hands = [n for n in body.joint_at if n.startswith(("LeftHand", "RightHand"))]
    if hands:
        on_hand = np.zeros(W * H, bool)
        ht = np.where(body.share(*hands)[body.idx].min(1) > 0.5)[0]
        for s0 in range(0, len(ht), 20000):
            pix, _, _ = texels(body, ht[s0:s0 + 20000], W, H)
            on_hand[pix] = True
        warm = smooth(0.05, 0.11, c[:, 0] - c[:, 1]) * smooth(0.10, 0.20, lum) * (c[:, 0] > c[:, 2])
        skin = np.where(on_hand, np.maximum(skin, warm), skin)
    on_head = np.zeros(W * H)
    face = np.zeros(W * H, bool)
    head_tris = np.where(head[body.idx].min(1) > 0.5)[0]
    ey = (eyes[0][1] + eyes[1][1]) / 2
    exs = [e[0] for e in eyes]
    hz = body.joint_at["Head"][2]
    for s0 in range(0, len(head_tris), 20000):
        pix, tri, bary = texels(body, head_tris[s0:s0 + 20000], W, H)
        on_head[pix] = 1.0
        p = at_texels(body, body.pos, tri, bary)
        f = (p[:, 2] > hz) & (p[:, 1] > ey - 0.13) & (p[:, 1] < ey + 0.045) & (np.abs(p[:, 0] - sum(exs) / 2) < 0.075)
        face[pix[f]] = True
    eyeball = np.zeros(W * H, bool)
    for q in eye_px:
        eyeball[q] = True
    cover = covered(body, W, H)
    cv = cover.reshape(-1)
    sk = cv & (skin > 0.5)
    if args.skin_roughness > 0 and sk.any():
        mid = float(np.median(flat_mr[sk, 1]))
        if mid < args.skin_roughness:
            k = (1 - args.skin_roughness) / (1 - mid)
            f = 1 - skin * (1 - k)
            flat_mr[cv, 1] = 1 - (1 - flat_mr[cv, 1]) * f[cv]
            print("skin: roughness %.2f in the middle, now %.2f" % (mid, float(np.median(flat_mr[sk, 1]))))
    fl = face & ~eyeball & (flat_mr[:, 1] < args.face_floor)
    flat_mr[fl, 1] = args.face_floor
    print("face: %d texels under %.2f brought up to it" % (fl.sum(), args.face_floor))
    # hair: Tripo gives it the gloss of wet glass (young Bram's grey hair and
    # beard 0.08 in the middle, 27 November), and every strand's edge caught
    # the light as a white glint; hair has a soft sheen, not a mirror's
    hr = cv & (on_head > 0) & ~eyeball & (flat_mr[:, 1] < args.hair_roughness)
    a = 1.0 - skin[hr]
    flat_mr[hr, 1] = flat_mr[hr, 1] * (1 - a) + args.hair_roughness * a
    print("hair: %d texels under %.2f brought up to it" % (int((a > 0.5).sum()), args.hair_roughness))
    # and anything else as glossy, but metal: snow on his shoulders, wet-look
    # wool. Leather and polish keep what they have over the floor
    lo = cv & ~eyeball & (flat_mr[:, 1] < args.floor) & (flat_mr[:, 2] < 0.3)
    flat_mr[lo, 1] = args.floor
    print("the rest: %d texels under %.2f brought up to it" % (lo.sum(), args.floor))
    v = flat_nm * 2 - 1
    t = np.hypot(v[:, 0], v[:, 1])
    lim = args.tilt + (args.skin_tilt - args.tilt) * np.maximum(skin, on_head)
    t2 = lim * np.tanh(t / np.maximum(lim, 1e-6))
    eased = cv & (t > 1e-4)
    sc = np.where(eased, t2 / np.maximum(t, 1e-6), 1.0)
    v[:, 0] *= sc
    v[:, 1] *= sc
    v[:, 2] = np.sqrt(np.clip(1 - v[:, 0] ** 2 - v[:, 1] ** 2, 0, 1))
    print("ridges: %.2f%% of the map tilted over 0.25 before, %.2f%% after"
          % ((t[cv] > 0.25).mean() * 100, (t2[cv] > 0.25).mean() * 100))
    flat_nm[:] = (v + 1) / 2
    changed |= cv
    ch = changed.reshape(H, W)
    g1 = regutter(nm, cover, ch)
    g2 = regutter(mr, cover, ch)
    Image.fromarray((np.clip(nm, 0, 1) * 255 + 0.5).astype(np.uint8)).save(args.normal)
    out = Image.fromarray((np.clip(mr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    (out if mr_mode == "RGBA" else out.convert(mr_mode)).save(args.mr)
    print("%d texels in all (and %d, %d of the maps' gutters)" % (ch.sum(), g1, g2))
    if args.report:
        os.makedirs(args.report, exist_ok=True)
        Image.fromarray((ch * 255).astype(np.uint8)).resize((1024, 1024)).save(os.path.join(args.report, "maps_where.png"))


if __name__ == "__main__":
    main()
