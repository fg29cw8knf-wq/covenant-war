"""Paints real eyes onto a model that was sculpted with eyeballs but painted
without them: a white, an iris, a pupil and the lid's shadow, where the
maker's paint is one blur of colour.

Tripo3D's Smart Mesh Player A (25 November) has proper lids and an eyeball
set behind them, but its picture paints the whole ball a pale glassy blue
with a darker smear for the iris: no white, no pupil, so from any distance he
looks blind. (tools/paint_eyes.py is for the other case, Bram's of 26
October: no eyeball at all and the lids painted shut, so it draws lids too.
Here the lids are the model's own and are left exactly as they are.)

  python3 tools/paint_eyeballs.py MODEL.glb ATLAS.png OUT.png
      [--eye X,Y --eye X,Y] [--iris 0.30,0.40,0.48] [--iris-share 0.52]
      [--pupil 0.355] [--ring 0.35] [--look 0,0] [--find]

Each eye is found by its paint: on the front of the head, the texels that
are cool where skin is warm (blue at least as strong as red). --find prints
where they are and stops. --eye X,Y (metres, seen from the front; the model
faces +Z and its left is +X) names them instead, if the finding goes wrong.

For each eye the opening between the lids is measured from those texels
(its corners, and the upper and lower lid's line across it), and the eye is
drawn front-on in the model's own metres:
  - the white, a warm off-white, shaded under the upper lid and pinker into
    the corners (a pure white stares);
  - the iris (--iris, its colour), a little over half as wide as the
    eyeball's paint (which stops short of the corners), darker at its rim
    and lighter round the pupil, set so the upper lid covers its top and the
    lower lid just covers its foot: an eye at rest, not startled (the lesson
    of Bram's, 1 November; at 42 % he stared, white all round the iris);
  - the pupil, and a small catch of light up and to his right.
--look x,y moves the irises (-1..1 of the room they have).

Only eyeball texels are painted, each by how surely it is eyeball, so the
lids' rims keep their own paint; then the picture's gutters are filled
again (tools/atlas_paint.py).
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from atlas_paint import Body, texels, at_texels, covered, regutter  # noqa: E402

Image.MAX_IMAGE_PIXELS = None


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def eyeness(c):
    """How surely a texel's old paint is eyeball: 1 where blue is at least as
    strong as red, 0 where it's skin (red well over blue)."""
    return smooth(-0.10, -0.01, c[:, 2] - c[:, 0])


def find_eyes(body, img, W, H):
    """Where the eyeballs' paint is: the middles of the two cool patches on
    the front of the head, as (x, y) seen from the front."""
    head = body.share("Head", "Neck")
    top = body.pos[:, 1].max()
    tri_ok = (head[body.idx].min(1) > 0.5) & (body.nrm[body.idx].mean(1)[:, 2] > 0.0)
    c = body.pos[body.idx].mean(1)
    tri_ok &= (c[:, 1] > top - 0.24) & (c[:, 1] < top - 0.09)
    tris = np.where(tri_ok)[0]
    pix, tri, bary = texels(body, tris, W, H)
    col = img.reshape(-1, 3)[pix]
    p = at_texels(body, body.pos, tri, bary)
    cool = (eyeness(col) > 0.6) & (col.max(1) > 0.3)
    q = p[cool]
    out = []
    for side in (-1, 1):
        s = q[q[:, 0] * side > 0.008]
        if len(s) < 30:
            continue
        # the densest patch: the median, then the middle of what's near it
        m = np.median(s, 0)
        s = s[(np.abs(s[:, 0] - m[0]) < 0.022) & (np.abs(s[:, 1] - m[1]) < 0.012)]
        out.append(((s[:, 0].min() + s[:, 0].max()) / 2, (s[:, 1].min() + s[:, 1].max()) / 2, len(s)))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model")
    ap.add_argument("atlas")
    ap.add_argument("out")
    ap.add_argument("--eye", action="append", default=[])
    ap.add_argument("--iris", default="0.30,0.40,0.48")
    ap.add_argument("--look", default="0,0")
    ap.add_argument("--iris-share", type=float, default=0.52, help="the iris's width as a share of the eyeball paint's (which stops short of the corners)")
    ap.add_argument("--pupil", type=float, default=0.355, help="the pupil's width as a share of the iris's (a larger one is a softer look)")
    ap.add_argument("--ring", type=float, default=0.35, help="how dark the ring at the iris's edge is (0-1; a pale iris wants more, to stand off the white)")
    ap.add_argument("--find", action="store_true")
    args = ap.parse_args()
    body = Body(args.model)
    img = np.asarray(Image.open(args.atlas).convert("RGB")).astype(np.float64) / 255.0
    H, W = img.shape[:2]
    eyes = [tuple(float(v) for v in e.split(",")) for e in args.eye] or [e[:2] for e in find_eyes(body, img, W, H)]
    for e in eyes:
        print("eye at x %.4f, y %.4f" % (e[0], e[1]))
    assert len(eyes) == 2, "expected two eyes, found %d (name them with --eye X,Y)" % len(eyes)
    if args.find:
        return
    iris_c = np.array([float(x) for x in args.iris.split(",")])
    look = [float(x) for x in args.look.split(",")]
    head = body.share("Head", "Neck")
    cen = body.pos[body.idx].mean(1)
    flat = img.reshape(-1, 3)
    changed = np.zeros(W * H, bool)
    total = 0
    for ex, ey in eyes:
        # the front of the head round the eye (not by "the frontmost surface
        # there": a lock of hair can hang five centimetres in front of an eye,
        # as Player A's does; the hair is warm, so its texels are never taken
        # for eyeball anyway)
        near = (np.abs(cen[:, 0] - ex) < 0.024) & (np.abs(cen[:, 1] - ey) < 0.016) & (head[body.idx].min(1) > 0.5)
        near &= cen[:, 2] > body.joint_at["Head"][2]
        pix, tri, bary = texels(body, np.where(near)[0], W, H)
        p = at_texels(body, body.pos, tri, bary)
        old = flat[pix].copy()
        e = eyeness(old)
        ball = e > 0.5
        assert ball.sum() > 50, "no eyeball paint found at %.3f, %.3f" % (ex, ey)
        # the opening: its corners, and each lid's line across it (the top
        # and the bottom of the eyeball's texels, column by column, fitted
        # with a smooth arch so one stray texel doesn't notch a lid)
        bx, by = p[ball, 0], p[ball, 1]
        x0, x1 = np.percentile(bx, 0.5), np.percentile(bx, 99.5)
        a = (x1 - x0) / 2
        cx = (x0 + x1) / 2
        bins = np.clip(((bx - x0) / (x1 - x0) * 24).astype(int), 0, 23)
        us, tops, bots = [], [], []
        for k in range(24):
            s = by[bins == k]
            if len(s) >= 4:
                us.append((k + 0.5) / 12 - 1)
                tops.append(np.percentile(s, 97))
                bots.append(np.percentile(s, 3))
        us, tops, bots = np.array(us), np.array(tops), np.array(bots)
        ft = np.polyfit(us, tops, 4)
        fb = np.polyfit(us, bots, 4)
        u = np.clip((p[:, 0] - cx) / a, -1.05, 1.05)
        upper, lower = np.polyval(ft, u), np.polyval(fb, u)
        top_c, bot_c = np.polyval(ft, 0.0), np.polyval(fb, 0.0)
        opening = top_c - bot_c
        # the iris: its size from the eye's width; the lids cover what the
        # opening can't show, seven tenths of it under the upper lid. An
        # opening taller than the iris (a wide-eyed sculpt) has the iris sit
        # on the lower lid's line with the white above it kept to a sliver
        # by a slightly larger iris.
        r = args.iris_share * a
        if 2 * r < opening + 0.0012:
            r = min((opening + 0.0012) / 2, r * 1.12)
        hidden = max(2 * r - opening, 0.0)
        icy = bot_c + r - 0.3 * hidden + look[1] * 0.001
        # a straight look sits a touch to the nose's side of the opening's
        # middle (the opening runs further out to the temple)
        nose = -1.0 if ex > 0 else 1.0
        icx = cx + nose * 0.035 * a + look[0] * (a - r) * 0.5
        dx, dy = p[:, 0] - icx, p[:, 1] - icy
        rr = np.hypot(dx, dy)
        # the white
        sclera = np.array([0.74, 0.70, 0.665])
        col = np.broadcast_to(sclera, (len(pix), 3)).copy()
        corner = smooth(0.55, 1.0, np.abs(u))[:, None]
        col = col * (1 - 0.30 * corner) + np.array([0.70, 0.47, 0.42]) * 0.30 * corner
        # the iris: darker at the rim, a paler ring round the pupil, fine spokes
        ang = np.arctan2(dy, dx)
        spokes = 1.0 + 0.07 * np.sin(ang * 19.0) + 0.05 * np.sin(ang * 31.0 + 1.3)
        t = np.clip(rr / r, 0, 1)
        tone = 1.0 - 0.50 * smooth(0.55, 1.0, t) + 0.20 * smooth(0.55, 0.30, t)
        iris = iris_c[None, :] * (tone * spokes)[:, None]
        iris = iris * (1 - args.ring * smooth(0.78, 1.0, t))[:, None]      # the dark ring at its edge
        in_iris = smooth(r + 0.0004, r - 0.0003, rr)[:, None]
        col = col * (1 - in_iris) + iris * in_iris
        in_pupil = smooth((args.pupil + 0.045) * r, (args.pupil - 0.045) * r, rr)[:, None]
        col = col * (1 - in_pupil) + np.array([0.035, 0.03, 0.03]) * in_pupil
        # the upper lid's shadow across the top of the ball, a fainter one along the lower lid
        shade = 1 - 0.55 * smooth(0.0034, 0.0, upper - p[:, 1]) - 0.16 * smooth(0.0014, 0.0, p[:, 1] - lower)
        col = col * shade[:, None]
        # a catch of light, up and to his right, clear of the pupil
        hl = smooth(0.17 * r, 0.05 * r, np.hypot(dx + 0.40 * r, dy - 0.34 * r))[:, None] * 0.70
        col = col * (1 - hl) + 0.97 * hl
        k = smooth(0.25, 0.85, e)[:, None]
        flat[pix] = old * (1 - k) + np.clip(col, 0, 1) * k
        changed[pix[k[:, 0] > 0.01]] = True
        total += int((k[:, 0] > 0.01).sum())
        print("eye at %+.4f, %.4f: %.1f mm wide, %.1f mm open; iris %.1f mm across at %+.4f, %.4f (%.1f mm under the upper lid, %.1f under the lower)"
              % (cx, (top_c + bot_c) / 2, 2000 * a, 1000 * opening, 2000 * r, icx, icy,
                 1000 * max(icy + r - top_c, 0), 1000 * max(bot_c - (icy - r), 0)))
    cover = covered(body, W, H)
    g = regutter(img, cover, changed.reshape(H, W))
    Image.fromarray((np.clip(img, 0, 1) * 255).round().astype(np.uint8)).save(args.out)
    print("painted %d texels (and %d of the gutters); wrote %s" % (total, g, args.out))


if __name__ == "__main__":
    main()
