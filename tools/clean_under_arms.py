"""Paints out the patches of the body's clothes that a model's maker left on
the inside of its arms.

A model made from a picture of someone standing with their arms down has its
paint thrown onto it from outside, and where an arm lay against the body the
inside of the arm took the body's paint: Player A's Smart Mesh model (25
November) has a dark patch of his green waistcoat on the underside of each
cream sleeve, by the armpit and again by the elbow. Nothing shows while his
arms hang; the moment he lifts one (a wave, a cheer, taking the card box) the
patch is in plain view. (Making the model from a picture with the arms held
out, a T-pose, is the real cure: Still to Make, the Cast tab.)

  python3 tools/clean_under_arms.py MODEL.glb ATLAS.png OUT.png [--report DIR]

For each arm the surface is read as a sleeve round the arm's bones: how far
along (s), which way round (0 = facing out, 180 = facing the body). Then:

  1. what the arm should look like at each point along it is taken from its
     outer half (the sleeve's cream to the cuff, skin below it);
  2. a texel on the half that faces the body is a stain when it is far from
     that and nearer the colour of the body beside it (found in the model's
     own metres: the nearest of the torso's paint), or simply much darker;
     the soft rim round each stain goes with it;
  3. each stain takes the paint of the arm's own outer side straight across
     the bone from it (so it has the cloth's own folds and weave, not a flat
     fill), toned to the inside of the arm round the stain and feathered in
     at its edge;
  4. the picture's gutters are filled again (tools/atlas_paint.py).

--report DIR writes each sleeve rolled out flat, before and after, to look at.
Prints how much was painted; nothing is written if nothing is found.
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from atlas_paint import Body, texels, at_texels, covered, regutter  # noqa: E402

Image.MAX_IMAGE_PIXELS = None
MM = 0.001


def lum(c):
    return c @ np.array([0.299, 0.587, 0.114])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model")
    ap.add_argument("atlas")
    ap.add_argument("out")
    ap.add_argument("--far", type=float, default=0.20, help="how far from the arm's own colour a stain is (0-1.7)")
    ap.add_argument("--dark", type=float, default=0.50, help="a texel under this share of the arm's own brightness is a stain whatever its colour")
    ap.add_argument("--grow", type=float, default=0.007, help="metres of soft rim taken with each stain")
    ap.add_argument("--report", default="")
    args = ap.parse_args()
    from scipy.spatial import cKDTree
    from scipy import ndimage
    body = Body(args.model)
    img = np.asarray(Image.open(args.atlas).convert("RGB")).astype(np.float64) / 255.0
    H, W = img.shape[:2]
    flat = img.reshape(-1, 3)
    changed = np.zeros(W * H, bool)
    # the torso's paint, to tell whose colour a stain is
    arm_all = body.share("LeftArm", "LeftForeArm", "LeftHand*", "RightArm", "RightForeArm", "RightHand*")
    trunk = body.share("Hips", "Spine*", "LeftUpLeg", "RightUpLeg", "LeftShoulder", "RightShoulder")
    t_tris = np.where((arm_all[body.idx].max(1) < 0.2) & (trunk[body.idx].min(1) > 0.5))[0]
    tp, tt, tb = texels(body, t_tris, W, H)
    keep = np.arange(0, len(tp), 3)            # a third of them is plenty to know the colour by
    t_pos = at_texels(body, body.pos, tt[keep], tb[keep])
    t_col = flat[tp[keep]].copy()
    trunk_tree = cKDTree(t_pos)
    total = 0
    for side in ("Left", "Right"):
        sh = body.share(side + "Arm", side + "ForeArm")
        tris = np.where(sh[body.idx].max(1) > 0.25)[0]
        pix, tri, bary = texels(body, tris, W, H)
        p = at_texels(body, body.pos, tri, bary)
        n = at_texels(body, body.nrm, tri, bary)
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        c = flat[pix].copy()
        A, B, C = body.joint_at[side + "Arm"], body.joint_at[side + "ForeArm"], body.joint_at[side + "Hand"]
        L1, L2 = np.linalg.norm(B - A), np.linalg.norm(C - B)
        d1, d2 = (B - A) / L1, (C - B) / L2
        t1 = (p - A) @ d1
        low = t1 > L1
        s = np.where(low, L1 + (p - B) @ d2, t1)
        r = np.where(low[:, None], (p - B) - ((p - B) @ d2)[:, None] * d2, (p - A) - t1[:, None] * d1)
        out_dir = np.array([1.0 if side == "Left" else -1.0, 0.0, 0.0])
        out_dir -= (out_dir @ d1) * d1
        out_dir /= np.linalg.norm(out_dir)
        fwd = np.cross(d1, out_dir)
        th = np.degrees(np.arctan2(r @ fwd, r @ out_dir))      # 0 out, +-180 towards the body
        facing = n @ out_dir
        along = (s > 0.03) & (s < L1 + L2 - 0.03)
        outer = along & (facing > 0.15)
        inner = along & (facing < -0.15)
        # 1. the arm's own colour along its length, from its outer half
        nb = int((L1 + L2) / 0.01) + 1
        sb = np.clip((s / 0.01).astype(int), 0, nb - 1)
        ref = np.zeros((nb, 3))
        have = np.zeros(nb, bool)
        for k in range(nb):
            m = outer & (sb == k)
            if m.sum() >= 60:
                ref[k] = np.median(c[m], 0)
                have[k] = True
        assert have.any(), "no outer side found for the %s arm" % side.lower()
        ks = np.where(have)[0]
        for ch in range(3):
            ref[:, ch] = np.interp(np.arange(nb), ks, ref[ks, ch])
        ref_s = np.stack([np.interp(s / 0.01 - 0.5, np.arange(nb), ref[:, ch]) for ch in range(3)], 1)
        d_ref = np.linalg.norm(c - ref_s, axis=1)
        # 2. stains: on the inner half, far from that and nearer the body's colour, or much darker
        ii = np.where(inner)[0]
        dist, nn = trunk_tree.query(p[ii], k=8, distance_upper_bound=0.07)
        ok = np.isfinite(dist)
        nnc = np.where(ok[:, :, None], t_col[np.minimum(nn, len(t_col) - 1)], 0.0).sum(1) / np.maximum(ok.sum(1, keepdims=True), 1)
        d_body = np.where(ok.any(1), np.linalg.norm(c[ii] - nnc, axis=1), 9.0)
        stain = np.zeros(len(pix), bool)
        stain[ii] = ((d_ref[ii] > args.far) & (d_body < 0.9 * d_ref[ii])) | (lum(c[ii]) < args.dark * lum(ref_s[ii]))
        seeds = int(stain.sum())
        if seeds:
            tree = cKDTree(p[stain])
            near = np.where(inner & ~stain & (d_ref > 0.5 * args.far))[0]
            dd, _ = tree.query(p[near], distance_upper_bound=args.grow)
            stain[near[np.isfinite(dd)]] = True
        if not stain.any():
            print("%s arm: no stain found" % side.lower())
            continue
        # the sleeve rolled out flat (1 mm along, 1 degree round), for the paint across the bone
        s0 = -0.08
        Wd = int((L1 + L2 + 0.16) / MM) + 1
        sx = np.clip(((s - s0) / MM).astype(int), 0, Wd - 1)
        ty = (np.floor(th + 180.0).astype(int)) % 360
        clean = ~stain & (np.linalg.norm(r, axis=1) < 0.11)
        acc = np.zeros((360, Wd, 3))
        cnt = np.zeros((360, Wd))
        np.add.at(acc, (ty[clean], sx[clean]), c[clean])
        np.add.at(cnt, (ty[clean], sx[clean]), 1)
        U = acc / np.maximum(cnt, 1)[..., None]
        hole = cnt == 0
        _, (iy, ix) = ndimage.distance_transform_edt(hole, return_indices=True)
        U = U[iy, ix]
        # 3. each stain: the outer side straight across the bone, toned to the inside of the arm
        st = np.where(stain)[0]
        donor = U[(ty[st] + 180) % 360, sx[st]]
        # the tone of the clean inside of the arm at that length, against the outside's
        tone = np.ones(nb)
        for k in range(nb):
            mi = inner & ~stain & (sb == k) & (d_ref < 0.5 * args.far)
            if mi.sum() >= 40 and have[k]:
                tone[k] = np.clip(np.median(lum(c[mi])) / max(lum(ref[k]), 1e-3), 0.78, 1.0)
        tone = ndimage.uniform_filter1d(tone, 5, mode="nearest")
        new = donor * np.interp(s[st] / 0.01 - 0.5, np.arange(nb), tone)[:, None]
        # feathered in over the rim: full strength 3 mm inside the stain's edge
        ctree = cKDTree(p[inner & ~stain]) if (inner & ~stain).any() else None
        if ctree is not None:
            de, _ = ctree.query(p[st], distance_upper_bound=0.02)
            w = np.clip(np.where(np.isfinite(de), de, 0.02) / 0.003, 0.0, 1.0)
            w = w * w * (3 - 2 * w)
        else:
            w = np.ones(len(st))
        w = np.maximum(w, 0.35)                 # the rim itself still loses most of its stain
        if args.report:
            os.makedirs(args.report, exist_ok=True)
            for tag, cols in (("before", c), ("after", None)):
                cc = c.copy()
                if cols is None:
                    cc[st] = c[st] * (1 - w[:, None]) + new * w[:, None]
                a2 = np.zeros((360, Wd, 3))
                n2 = np.zeros((360, Wd))
                np.add.at(a2, (ty, sx), cc)
                np.add.at(n2, (ty, sx), 1)
                R = a2 / np.maximum(n2, 1)[..., None]
                R[n2 == 0] = (0.15, 0.15, 0.18)
                Image.fromarray((R * 255).astype(np.uint8)).save(os.path.join(args.report, "sleeve_%s_%s.png" % (side.lower(), tag)))
        flat[pix[st]] = c[st] * (1 - w[:, None]) + new * w[:, None]
        changed[pix[st]] = True
        total += len(st)
        area = len(st) * (np.pi * 0.06 * 2 * (L1 + L2)) / max(int(along.sum()), 1)
        print("%s arm: %d texels of stain (%d found, the rest their rim), about %.0f cm2, between %.0f and %.0f cm down from the shoulder"
              % (side.lower(), len(st), seeds, area * 1e4, 100 * s[st].min(), 100 * s[st].max()))
    if not total:
        print("nothing to paint; %s not written" % args.out)
        return
    g = regutter(img, covered(body, W, H), changed.reshape(H, W))
    Image.fromarray((np.clip(img, 0, 1) * 255).round().astype(np.uint8)).save(args.out)
    print("painted %d texels (and %d of the gutters); wrote %s" % (total, g, args.out))


if __name__ == "__main__":
    main()
