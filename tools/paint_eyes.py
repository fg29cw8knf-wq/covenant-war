"""Paints open eyes onto a character whose model came with them shut
(Tripo3D's Bram of 26 October: the lids are painted closed on a face with no
eyeballs to open; 27 October, Gary: "Bram ... looks like he has his eyes
closed"). The eye is drawn front-on in the model's own metres and projected
onto the face, then written into the colour texture wherever the face's
triangles take it, so it lands right whatever the texture's layout:

  python3 tools/paint_eyes.py MODEL.glb ATLAS.png OUT.png --eye X,Y [--eye X,Y]
      [--width 0.027] [--open 0.0105] [--iris 0.36,0.45,0.5] [--look 0,0]

X, Y: the middle of each eye seen from the front (metres; the model faces +Z,
its left is +X). --width: corner to corner. --open: lid to lid at the middle.
--look: where the irises sit, as a share of the room they have (-1..1, x, y).
The best fix is still a model made with its eyes open (say so in the prompt).
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def eye_rgba(dx, dy, a, up_h, lo_h, iris_c, look):
    """Colour and cover of the eye at (dx, dy) metres from its middle."""
    u = np.clip(dx / a, -1.5, 1.5)
    # the lids: arcs from corner to corner, the upper higher and fuller, its
    # peak a touch towards the nose side is skipped (kept plain)
    upper = up_h * np.clip(1 - u * u, 0.0, 1.0) ** 0.75
    lower = -lo_h * np.clip(1 - u * u, 0.0, 1.0) ** 1.1
    inside_x = np.abs(u) < 1.0
    # signed distance (m) into the opening from the nearest lid
    din = np.minimum(upper - dy, dy - lower)
    din = np.where(inside_x, din, -1.0)
    px = 0.00035   # a soft edge about a texel wide
    cover = smooth(-px, px, din)
    # sclera, cooled and darkened under the upper lid's shadow, pink at the corners
    sclera = np.array([0.76, 0.72, 0.66])
    col = np.broadcast_to(sclera, dx.shape + (3,)).copy()
    shade = 1 - 0.45 * smooth(0.0028, 0.0, upper - dy)
    corner = smooth(0.6, 0.95, np.abs(u))
    col = col * (1 - corner[..., None] * 0.25) + np.array([0.62, 0.36, 0.33]) * corner[..., None] * 0.25
    # the iris and pupil
    r_iris = 0.0058
    ic = np.array([look[0] * (a - r_iris) * 0.5, -0.0004 + look[1] * 0.001])
    rr = np.hypot(dx - ic[0], dy - ic[1])
    ring = smooth(r_iris * 0.62, r_iris, rr)
    iris = np.array(iris_c)[None, None, :] * (1.05 - 0.45 * ring[..., None])
    rad = 0.9 + 0.1 * np.sin(np.arctan2(dy - ic[1], dx - ic[0]) * 23.0)
    iris = iris * rad[..., None]
    in_iris = smooth(r_iris + 0.0003, r_iris - 0.0002, rr)
    col = col * (1 - in_iris[..., None]) + iris * in_iris[..., None]
    in_pupil = smooth(0.0023, 0.0018, rr)
    col = col * (1 - in_pupil[..., None]) + np.array([0.04, 0.035, 0.035]) * in_pupil[..., None]
    col = col * shade[..., None]
    # a catch of light, up and in
    hl = smooth(0.0011, 0.0004, np.hypot(dx - ic[0] + 0.0016, dy - ic[1] - 0.0017))
    col = col * (1 - hl[..., None] * 0.85) + 0.97 * hl[..., None] * 0.85
    # the lid lines: a dark upper lash line, a fainter lower one
    up_line = smooth(0.0011, 0.0, np.abs(dy - upper)) * inside_x
    lo_line = smooth(0.0007, 0.0, np.abs(dy - lower)) * inside_x
    lash = np.array([0.16, 0.1, 0.08])
    out = col * cover[..., None]
    alpha = cover.copy()
    for line, k, c in ((up_line, 0.95, lash), (lo_line, 0.5, np.array([0.42, 0.27, 0.23]))):
        w = line * k
        out = out * (1 - w[..., None]) + c * w[..., None]
        alpha = np.maximum(alpha, w)
    return np.concatenate([np.where(alpha[..., None] > 0, out / np.maximum(alpha[..., None], 1e-6), 0.0), alpha[..., None]], -1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("atlas")
    ap.add_argument("out")
    ap.add_argument("--eye", action="append", required=True)
    ap.add_argument("--width", type=float, default=0.027)
    ap.add_argument("--open", type=float, default=0.0105)
    ap.add_argument("--iris", default="0.36,0.45,0.5")
    ap.add_argument("--look", default="0,0")
    args = ap.parse_args()
    j, b = load(args.model)
    pr = j["meshes"][0]["primitives"][0]
    pos = acc(j, b, pr["attributes"]["POSITION"]).astype(np.float64)
    uv = acc(j, b, pr["attributes"]["TEXCOORD_0"]).astype(np.float64)
    idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
    img = np.asarray(Image.open(args.atlas).convert("RGB")).astype(np.float64) / 255.0
    H, W = img.shape[:2]
    a = args.width / 2
    up_h, lo_h = args.open * 0.58, args.open * 0.42
    iris_c = [float(x) for x in args.iris.split(",")]
    look = [float(x) for x in args.look.split(",")]
    P, U = pos[idx], uv[idx]
    nrm = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-12)
    painted = 0
    for e in args.eye:
        ex, ey = [float(v) for v in e.split(",")]
        c = P.mean(1)
        near = (np.abs(c[:, 0] - ex) < a + 0.006) & (np.abs(c[:, 1] - ey) < 0.012) & (nrm[:, 2] > 0.25)
        # only the face's own surface: the frontmost at that spot
        front_z = c[near, 2].max()
        near &= c[:, 2] > front_z - 0.03
        for t in np.where(near)[0]:
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
            if not m.any():
                continue
            X = l0 * p[0, 0] + l1 * p[1, 0] + l2 * p[2, 0]
            Y = l0 * p[0, 1] + l1 * p[1, 1] + l2 * p[2, 1]
            rgba = eye_rgba(X - ex, Y - ey, a, up_h, lo_h, iris_c, look)
            for (yy, xx) in zip(*np.where(m)):
                tx, ty = (minx + xx) % W, (miny + yy) % H
                al = rgba[yy, xx, 3]
                if al > 0.0:
                    img[ty, tx] = img[ty, tx] * (1 - al) + rgba[yy, xx, :3] * al
                    painted += 1
    Image.fromarray((np.clip(img, 0, 1) * 255).round().astype(np.uint8)).save(args.out)
    print("painted %d texels; wrote %s" % (painted, args.out))


if __name__ == "__main__":
    main()
