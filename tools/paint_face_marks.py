"""Paints the small marks a face was given on paper and lost in the making:
freckles over the nose and cheeks, and an old scar through an eyebrow.

Player A's sheet (the Cast tab, 25 October) gives him "light freckles over
his nose from summers in the fields" and "a small old scar through his left
eyebrow". Tripo3D's Smart Mesh body of 25 November painted neither: its skin
is one clean wash. Gary said yes to painting them back on 26 November.

  python3 tools/paint_face_marks.py MODEL.glb ATLAS.png OUT.png
      [--eyes-from UNTOUCHED.png | --eye X,Y --eye X,Y]
      [--freckles 170] [--dust 130] [--strength 1.0] [--seed 7]
      [--scar left|right|none] [--scar-at 0.60] [--report DIR]

Everything is placed from the eyes (tools/paint_eyeballs.py finds them by
their paint, which has to be the maker's: once real eyes are painted the
finding has less to go on, so --eyes-from names the untouched picture) and
worked out on the face itself, in metres, never on the picture (see
tools/atlas_paint.py for why).

Freckles. Thickest across the bridge of the nose and the top of the cheeks
under the eyes, thinning toward the cheekbones and the tip of the nose, none
on the lids, the lips or below the nose: where the sun lands on a face.
Each is a soft, slightly lopsided spot 1 to 2.5 mm across that darkens and
warms the skin's own paint (so the face's painted shading shows through
it), no two the same strength; under them a dusting of smaller, fainter
ones, which is what stops the big ones looking stamped on. Only skin is
touched: a texel as dark as a brow, a nostril or a lock of hair is left.

The scar. Found from the brow's own paint: its dark texels over that eye
give its line and its thickness, and the scar crosses it --scar-at of the
way from its inner end to its tail (0.60: where the arch turns), slanting
out at the top, running a little past the brow above and below. Old, so
pale: the skin's colour from just over the brow, a touch lighter, with no
hair growing through it and a faint darker edge on its lower side.

Then the picture's gutters are filled again.
"""
import argparse, os, sys
import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from atlas_paint import Body, texels, at_texels, covered, regutter  # noqa: E402
from paint_eyeballs import find_eyes, smooth  # noqa: E402

Image.MAX_IMAGE_PIXELS = None


def lum(c):
    return c @ np.array([0.30, 0.59, 0.11])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model")
    ap.add_argument("atlas")
    ap.add_argument("out")
    ap.add_argument("--eye", action="append", default=[])
    ap.add_argument("--eyes-from", default="", help="the maker's untouched picture, to find the eyes on")
    ap.add_argument("--freckles", type=int, default=170)
    ap.add_argument("--dust", type=int, default=130, help="the smaller, fainter ones under them")
    ap.add_argument("--strength", type=float, default=1.0)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--scar", default="left", choices=["left", "right", "none"])
    ap.add_argument("--scar-at", type=float, default=0.60, help="how far along the brow, inner end to tail")
    ap.add_argument("--report", default="")
    args = ap.parse_args()

    body = Body(args.model)
    img = np.asarray(Image.open(args.atlas).convert("RGB")).astype(np.float64) / 255.0
    H, W = img.shape[:2]
    if args.eye:
        eyes = [tuple(float(v) for v in e.split(",")) for e in args.eye]
    else:
        src = img
        if args.eyes_from:
            src = np.asarray(Image.open(args.eyes_from).convert("RGB")).astype(np.float64) / 255.0
            assert src.shape == img.shape, "--eyes-from is a different size of picture"
        eyes = [e[:2] for e in find_eyes(body, src, W, H)]
    assert len(eyes) == 2, "expected two eyes, found %d (name them with --eye X,Y)" % len(eyes)
    eyes = sorted(eyes)                      # his right eye (-X) first, then his left
    (xr, yr), (xl, yl) = eyes
    cx, ye, half = (xr + xl) / 2, (yr + yl) / 2, (xl - xr) / 2
    print("eyes at x %.4f and %.4f, y %.4f: the face's middle x %.4f" % (xr, xl, ye, cx))

    # the front of the head from the brow to the chin, texel by texel
    head = body.share("Head", "Neck")
    cen = body.pos[body.idx].mean(1)
    tris = np.where((head[body.idx].min(1) > 0.5) & (cen[:, 2] > body.joint_at["Head"][2])
                    & (cen[:, 1] > ye - 0.13) & (cen[:, 1] < ye + 0.08))[0]
    pix, tri, bary = texels(body, tris, W, H)
    p = at_texels(body, body.pos, tri, bary)
    n = at_texels(body, body.nrm, tri, bary)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
    flat = img.reshape(-1, 3)
    col = flat[pix].copy()
    x, y = p[:, 0] - cx, p[:, 1] - ye

    # the skin's colour, from the middle of the forehead; skin is whatever is
    # near as light as that and warm (brows, nostrils, hair and the eyes fail)
    fore = (np.abs(x) < 0.02) & (y > 0.030) & (y < 0.050) & (n[:, 2] > 0.6)
    fore &= lum(col) > np.percentile(lum(col[fore]), 40)
    skin = np.median(col[fore], 0)
    is_skin = (lum(col) > 0.62 * lum(skin)) & (col[:, 0] > col[:, 2] + 0.04)
    print("skin %.2f %.2f %.2f; %d face texels, %d of them skin" % (*skin, len(pix), is_skin.sum()))

    # the tip of the nose: the foremost point down the face's middle
    mid = (np.abs(x) < 0.010) & (y < -0.020) & (y > -0.075)
    y_tip = y[mid][np.argmax(p[mid, 2])]
    span = -y_tip
    print("nose tip %.1f mm under the eye line" % (span * 1000))

    rng = np.random.default_rng(args.seed)
    tree = cKDTree(p)
    shade = np.ones((len(pix), 3))
    painted = np.zeros(len(pix), bool)

    # ---- freckles
    t = -y / span                            # 0 at the eye line, 1 at the nose's tip
    u = np.abs(x) / half                     # 1 under the middle of an eye
    down = smooth(0.22, 0.40, t) * (1.0 - 0.75 * smooth(0.72, 1.02, t)) * (1.0 - smooth(1.02, 1.22, t))
    bridge = smooth(0.02, 0.16, t) * (1.0 - smooth(0.55, 0.85, t)) * (1.0 - smooth(0.22, 0.40, u))
    across = np.exp(-(u / 1.25) ** 2.2)
    dens = np.maximum(down * across, 0.9 * bridge)
    for ex, ey in eyes:                      # and none on a lid
        dens *= smooth(0.8, 1.25, np.hypot((p[:, 0] - ex) / 0.021, (p[:, 1] - ey) / 0.0125))
    dens *= is_skin
    dens *= smooth(-0.1, 0.25, n[:, 2])      # nor on what faces backward
    assert dens.sum() > 0, "no skin found on the cheeks to freckle"
    # a texel's chance goes by the skin it covers, not by the texel: the
    # picture gives some parts of the face (the ridge of the nose) far fewer
    # texels to the square centimetre than others, and by the texel those
    # parts would come out bare
    tp = body.pos[body.idx[tri]]
    area = 0.5 * np.linalg.norm(np.cross(tp[:, 1] - tp[:, 0], tp[:, 2] - tp[:, 0]), axis=1)
    _, inv, cnt = np.unique(tri, return_inverse=True, return_counts=True)
    covers = area / cnt[inv]
    print("a face texel covers %.2f mm of skin across (middle one)" % (np.sqrt(np.median(covers[is_skin])) * 1000))
    prob = dens * covers
    prob /= prob.sum()
    total = 0
    for count, r_mid, a_lo, a_hi in ((args.freckles, 0.00095, 0.28, 0.62), (args.dust, 0.00055, 0.12, 0.28)):
        if count <= 0:
            continue
        for k in rng.choice(len(pix), size=count, p=prob):
            r = r_mid * float(np.exp(rng.normal(0.0, 0.28)))
            a0 = min(1.0, rng.uniform(a_lo, a_hi) * args.strength)
            tint = np.clip(np.array([0.82, 0.66, 0.53]) + rng.normal(0.0, 0.03, 3), 0.3, 1.0)
            # lopsided: stretched one way across the skin, by up to a third
            nc = n[k]
            e1 = np.cross(nc, [0.0, 1.0, 0.0])
            e1 /= max(np.linalg.norm(e1), 1e-9)
            e2 = np.cross(nc, e1)
            ang, st = rng.uniform(0, np.pi), rng.uniform(0.75, 1.33)
            a1 = np.cos(ang) * e1 + np.sin(ang) * e2
            a2 = np.cross(nc, a1)
            near = np.array(tree.query_ball_point(p[k], r * 1.5), np.int64)
            near = near[is_skin[near] & ((n[near] @ nc) > 0.3)]
            if len(near) == 0:
                continue
            d = p[near] - p[k]
            dist = np.sqrt((d @ a1 / st) ** 2 + (d @ a2 * st) ** 2 + (2.0 * (d @ nc)) ** 2) / r
            a = a0 * (1.0 - smooth(0.40, 1.0, dist))
            shade[near] *= 1.0 - a[:, None] * (1.0 - tint)[None, :]
            painted[near] |= a > 0.01
            total += 1
    shade = np.maximum(shade, [0.62, 0.48, 0.38])   # two that overlap don't make a mole
    new = col * shade
    print("freckles: %d spots on %d texels" % (total, painted.sum()))

    # ---- the scar through a brow
    if args.scar != "none":
        ex = xl if args.scar == "left" else xr
        side = 1.0 if args.scar == "left" else -1.0
        out_x = (p[:, 0] - ex) * side            # toward the temple
        yb = y - (yl if args.scar == "left" else yr) + ye   # (the two eyes' heights differ by a hair)
        band = (out_x > -0.030) & (out_x < 0.034) & (y > 0.006) & (y < 0.042) & (n[:, 2] > 0.2)
        dark = band & (lum(col) < 0.62 * lum(skin))
        # on the face, not a lock of hair in front of it: beside skin in depth
        sk = np.where(is_skin & band)[0]
        st2 = cKDTree(p[sk][:, :2])
        dd, ii = st2.query(p[dark][:, :2])
        on_face = (dd < 0.004) & (np.abs(p[dark][:, 2] - p[sk][ii, 2]) < 0.004)
        brow = np.where(dark)[0][on_face]
        assert len(brow) > 200, "no brow found over the %s eye" % args.scar
        bo, by = out_x[brow], y[brow]
        # the brow's line and thickness, 2 mm of its length at a time
        edges = np.arange(bo.min(), bo.max() + 0.002, 0.002)
        xs, mids, ths = [], [], []
        for a_, b_ in zip(edges[:-1], edges[1:]):
            s = by[(bo >= a_) & (bo < b_)]
            if len(s) >= 12:
                lo, hi = np.percentile(s, 6), np.percentile(s, 94)
                xs.append((a_ + b_) / 2); mids.append((lo + hi) / 2); ths.append(hi - lo)
        xs, mids, ths = np.array(xs), np.array(mids), np.array(ths)
        at = xs[0] + args.scar_at * (xs[-1] - xs[0])
        y_c = float(np.interp(at, xs, mids))
        th = float(np.interp(at, xs, ths))
        print("brow over his %s eye: %.1f mm long, %.1f mm thick where the scar crosses, %.1f mm from its inner end"
              % (args.scar, (xs[-1] - xs[0]) * 1000, th * 1000, (at - xs[0]) * 1000))
        # the scar's line, seen from the front: slanting out at the top
        ang = np.radians(68.0)
        dx, dy = np.cos(ang), np.sin(ang)
        top, bot = (th / 2 + 0.0024) / dy, (th / 2 + 0.0016) / dy
        qx, qy = out_x - at, y - y_c
        s_along = qx * dx + qy * dy
        s_perp = -qx * dy + qy * dx                # + on the inner, upper side
        cand = np.where(band & (s_along > -bot - 0.001) & (s_along < top + 0.001) & (np.abs(s_perp) < 0.003))[0]
        dd, ii = st2.query(p[cand][:, :2])
        cand = cand[(np.abs(p[cand][:, 2] - p[sk][ii, 2]) < 0.004) | is_skin[cand]]
        # tapered to a point at each end, widest a little above the middle
        f = (s_along[cand] + bot) / (top + bot)
        # (not ruled: it bows a quarter of a millimetre along its length)
        bow = s_perp[cand] - 0.00025 * np.sin(np.clip(f, 0, 1) * np.pi)
        taper = np.clip(np.sin(np.clip(f, 0, 1) * np.pi) ** 0.6, 0.0, 1.0)
        w = 0.00030 + 0.00042 * taper
        core = 1.0 - smooth(w, w + 0.00042, np.abs(bow))
        core *= smooth(0.0, 0.06, f) * (1.0 - smooth(0.94, 1.0, f))
        # the skin there: just over the brow, where the scar comes out of it
        above = is_skin & (np.abs(out_x - at - dx * top) < 0.006) & (y > y_c + th / 2 + 0.002) & (y < y_c + th / 2 + 0.010)
        local = np.median(col[above], 0) if above.sum() > 30 else skin
        # paler than the skin and a little less of its colour, as an old scar is
        scar_c = np.clip(0.78 * local * 1.06 + 0.22 * lum(local) * np.array([1.14, 1.02, 0.97]), 0, 1)
        was_dark = lum(col[cand]) < 0.80 * lum(local)
        alpha = core * np.where(was_dark, 0.94, 0.50)
        base = new[cand]
        new[cand] = base * (1 - alpha[:, None]) + scar_c[None, :] * alpha[:, None]
        # a faint darker edge along its lower, outer side: a shallow groove
        rim = smooth(w, w + 0.0002, -bow) * (1.0 - smooth(w + 0.0003, w + 0.0007, -bow))
        rim *= smooth(0.05, 0.2, f) * (1.0 - smooth(0.8, 0.95, f)) * (~was_dark)
        new[cand] *= 1.0 - 0.10 * rim[:, None]
        painted[cand] |= (alpha > 0.01) | (rim > 0.05)
        print("scar: %.1f mm long, %.1f mm at its widest, on %d texels" % ((top + bot) * 1000, 2 * (0.00030 + 0.00042) * 1000, int((alpha > 0.01).sum())))

    flat[pix[painted]] = np.clip(new[painted], 0.0, 1.0)
    changed = np.zeros(W * H, bool)
    changed[pix[painted]] = True
    changed = changed.reshape(H, W)
    filled = regutter(img, covered(body, W, H), changed)
    print("%d texels painted, %d of gutter filled" % (changed.sum(), filled))
    Image.fromarray((np.clip(img, 0, 1) * 255.0 + 0.5).astype(np.uint8)).save(args.out)
    if args.report:
        os.makedirs(args.report, exist_ok=True)
        m = np.zeros((H, W, 3), np.uint8)
        m[changed] = (255, 80, 40)
        Image.fromarray(m).resize((1024, 1024)).save(os.path.join(args.report, "face_marks_where.png"))


if __name__ == "__main__":
    main()
