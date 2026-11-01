"""Paints the lids of eyes painted on by tools/paint_eyes.py lower and closer,
so a face that stared reads as a calm one (1 November, Gary: "when you wake
up after the white card Bram's eyes look mental": the painted eyes were
open wide with white all round the iris, and from below, close to, he looked
startled out of his wits). Over each eye the old opening is painted out with
the eyelid's own skin (sampled from the ring just round it, a little darker
towards the lid's crease) and the eye drawn again inside lids that cover
the top and the bottom of the iris, as a grown man's do at rest:

  python3 tools/relax_eyes.py MODEL.glb ATLAS.png OUT.png --eye X,Y [--eye X,Y]
      [--width 0.027] [--old-open 0.0105] [--open 0.0078] [--iris 0.36,0.45,0.5]

X, Y as for paint_eyes.py (Bram: -0.035,1.707 and 0.034,1.707).
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc
from paint_eyes import eye_rgba, smooth


def raster(P, U, W, H, keep):
    """Yields (texel x, texel y, model X, model Y) for the triangles kept."""
    for t in np.where(keep)[0]:
        p, u = P[t], U[t]
        xs, ys = u[:, 0] * W, u[:, 1] * H
        minx, maxx = int(np.floor(xs.min())), int(np.ceil(xs.max()))
        miny, maxy = int(np.floor(ys.min())), int(np.ceil(ys.max()))
        gx, gy = np.meshgrid(np.arange(minx, maxx + 1) + 0.5, np.arange(miny, maxy + 1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-12:
            continue
        l0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        l1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        l2 = 1 - l0 - l1
        m = (l0 >= -0.02) & (l1 >= -0.02) & (l2 >= -0.02)
        X = l0 * p[0, 0] + l1 * p[1, 0] + l2 * p[2, 0]
        Y = l0 * p[0, 1] + l1 * p[1, 1] + l2 * p[2, 1]
        for (yy, xx) in zip(*np.where(m)):
            yield (minx + xx) % W, (miny + yy) % H, X[yy, xx], Y[yy, xx]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("atlas")
    ap.add_argument("out")
    ap.add_argument("--eye", action="append", required=True)
    ap.add_argument("--width", type=float, default=0.027)
    ap.add_argument("--old-open", type=float, default=0.0105)
    ap.add_argument("--open", type=float, default=0.0078)
    ap.add_argument("--iris", default="0.36,0.45,0.5")
    args = ap.parse_args()
    j, b = load(args.model)
    pr = j["meshes"][0]["primitives"][0]
    pos = acc(j, b, pr["attributes"]["POSITION"]).astype(np.float64)
    uv = acc(j, b, pr["attributes"]["TEXCOORD_0"]).astype(np.float64)
    idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
    src = np.asarray(Image.open(args.atlas).convert("RGB")).astype(np.float64) / 255.0
    img = src.copy()
    H, W = img.shape[:2]
    a = args.width / 2
    old_up, old_lo = args.old_open * 0.58, args.old_open * 0.42
    # the new lids: the upper one well down over the iris, the lower one up a little
    up_h, lo_h = args.open * 0.5, args.open * 0.5
    iris_c = [float(x) for x in args.iris.split(",")]
    P, U = pos[idx], uv[idx]
    nrm = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-12)
    c = P.mean(1)
    painted = 0
    for e in args.eye:
        ex, ey = [float(v) for v in e.split(",")]
        near = (np.abs(c[:, 0] - ex) < a + 0.008) & (np.abs(c[:, 1] - ey) < 0.014) & (nrm[:, 2] > 0.25)
        front_z = c[near, 2].max()
        near &= c[:, 2] > front_z - 0.03
        texels = list(raster(P, U, W, H, near))
        # the lid's skin: the ring just outside the old opening
        ring = []
        for tx, ty, X, Y in texels:
            dx, dy = X - ex, Y - ey
            u = dx / a
            if abs(u) < 1.15:
                upper = old_up * max(0.0, 1 - u * u) ** 0.75
                lower = -old_lo * max(0.0, 1 - u * u) ** 1.1
                out_d = max(dy - upper, lower - dy)
                if 0.0016 < out_d < 0.0035:
                    ring.append(src[ty, tx])
        skin = np.median(np.array(ring), 0) if ring else np.array([0.62, 0.45, 0.37])
        for tx, ty, X, Y in texels:
            dx, dy = X - ex, Y - ey
            u = dx / a
            if abs(u) > 1.12:
                continue
            uu = min(1.0, abs(u))
            upper = old_up * max(0.0, 1 - uu * uu) ** 0.75
            lower = -old_lo * max(0.0, 1 - uu * uu) ** 1.1
            # the old eye and its lash lines, with a little to spare
            inside_old = (dy < upper + 0.0016) and (dy > lower - 0.0012)
            if not inside_old:
                continue
            # skin, a shade darker towards the new upper lid (its crease)
            new_up = up_h * max(0.0, 1 - uu * uu) ** 0.75
            crease = smooth(0.0035, 0.0, abs(dy - new_up - 0.0012)) * 0.18
            base = skin * (1 - crease)
            # fade into what's round it at the old opening's edge
            edge = min(upper + 0.0016 - dy, dy - (lower - 0.0012))
            k = smooth(0.0, 0.0008, edge) * smooth(1.12, 1.0, abs(u))
            col = src[ty, tx] * (1 - k) + base * k
            rgba = eye_rgba(np.array([[dx]]), np.array([[dy]]), a, up_h, lo_h, iris_c, [0.0, 0.25])[0, 0]
            col = col * (1 - rgba[3]) + rgba[:3] * rgba[3]
            img[ty, tx] = col
            painted += 1
    Image.fromarray((np.clip(img, 0, 1) * 255).round().astype(np.uint8)).save(args.out)
    print("relaxed %d texels; wrote %s" % (painted, args.out))


if __name__ == "__main__":
    main()
