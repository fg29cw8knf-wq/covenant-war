"""What the tools that paint onto a model's colour picture share
(tools/paint_eyeballs.py, tools/clean_under_arms.py): the model read once,
its triangles laid out on the picture texel by texel, and the picture's
gutters filled again afterwards.

A Tripo3D picture (atlas) is cut into thousands of small islands (Player A's
Smart Mesh one of 25 November: 5,796), so nothing can be painted by working
on the picture as a picture: two texels side by side are often centimetres
apart on the body. Every tool here works on the body instead: each texel is
given the point of the body it colours (`texels`), the paint is worked out
there, in metres, and written back texel by texel.

Round every island the picture carries a margin of the island's own colour
(the gutter), which is what the screen blends in at an island's edge and in
the smaller copies of the picture seen from far off. Paint that stops at the
island's edge would leave the old colour showing as a thin line along every
seam, so after painting `regutter` fills the margin again from the nearest
painted texel.
"""
import os, sys
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rig_character import load, acc  # noqa: E402


class Body:
    """A game model's one skinned mesh: places, normals, picture places,
    triangles, and each vertex's share on every bone, by name."""

    def __init__(self, path):
        j, b = load(path)
        self.j = j
        pr = j["meshes"][0]["primitives"][0]
        at = pr["attributes"]
        self.pos = acc(j, b, at["POSITION"]).astype(np.float64)
        self.nrm = acc(j, b, at["NORMAL"]).astype(np.float64)
        self.uv = acc(j, b, at["TEXCOORD_0"]).astype(np.float64)
        self.idx = acc(j, b, pr["indices"]).astype(np.int64).reshape(-1, 3)
        jn = acc(j, b, at["JOINTS_0"]).astype(np.int64)
        wt = acc(j, b, at["WEIGHTS_0"]).astype(np.float64)
        self.joints = [j["nodes"][n]["name"] for n in j["skins"][0]["joints"]]
        self.weights = np.zeros((len(self.pos), len(self.joints)))
        for k in range(4):
            np.add.at(self.weights, (np.arange(len(self.pos)), jn[:, k]), wt[:, k])
        # where each bone's joint stands (the game's models: every rest square to the world)
        self.joint_at = {}
        nodes = j["nodes"]
        parent = {c: i for i, n in enumerate(nodes) for c in n.get("children", [])}
        for n in j["skins"][0]["joints"]:
            p, i = np.zeros(3), n
            while True:
                p = p + np.array(nodes[i].get("translation", [0, 0, 0]), np.float64)
                if i not in parent:
                    break
                i = parent[i]
            self.joint_at[nodes[n]["name"]] = p

    def share(self, *names):
        """Each vertex's weight on these bones together (a name ending in *
        takes every bone that starts with it)."""
        out = np.zeros(len(self.pos))
        for nm in names:
            for k, jn in enumerate(self.joints):
                if jn == nm or (nm.endswith("*") and jn.startswith(nm[:-1])):
                    out += self.weights[:, k]
        return out


def texels(body, tris, W, H):
    """Every texel whose middle lies in one of these triangles: (texel index
    y*W+x, triangle, its three barycentric shares)."""
    u = body.uv[body.idx[tris]]
    xs, ys = u[:, :, 0] % 1.0 * W, u[:, :, 1] % 1.0 * H
    x0, x1, x2 = xs[:, 0], xs[:, 1], xs[:, 2]
    y0, y1, y2 = ys[:, 0], ys[:, 1], ys[:, 2]
    area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
    minx = np.floor(xs.min(1)).astype(np.int64)
    miny = np.floor(ys.min(1)).astype(np.int64)
    ext = np.maximum(np.ceil(xs.max(1)).astype(np.int64) - minx, np.ceil(ys.max(1)).astype(np.int64) - miny) + 1
    ok = np.abs(area) > 1e-12
    pix, tri, bary = [], [], []
    done = np.zeros(len(tris), bool)
    k = 2
    while not done[ok].all() and k <= 8192:
        sel = np.where(ok & ~done & (ext <= k))[0]
        done[sel] = True
        off = np.arange(k)
        ox, oy = [a.reshape(-1) for a in np.meshgrid(off, off)]
        step = max(1, int(3e6 // (k * k)))
        for s in range(0, len(sel), step):
            ids = sel[s:s + step]
            px = minx[ids][:, None] + ox[None, :]
            py = miny[ids][:, None] + oy[None, :]
            cx, cy = px + 0.5, py + 0.5
            a = area[ids][:, None]
            w0 = ((x1[ids][:, None] - cx) * (y2[ids][:, None] - cy) - (x2[ids][:, None] - cx) * (y1[ids][:, None] - cy)) / a
            w1 = ((x2[ids][:, None] - cx) * (y0[ids][:, None] - cy) - (x0[ids][:, None] - cx) * (y2[ids][:, None] - cy)) / a
            w2 = 1.0 - w0 - w1
            ins = (w0 >= 0) & (w1 >= 0) & (w2 >= 0) & (px >= 0) & (px < W) & (py >= 0) & (py < H)
            ti, pi = np.where(ins)
            pix.append(py[ti, pi] * W + px[ti, pi])
            tri.append(np.asarray(tris)[ids[ti]])
            bary.append(np.stack([w0[ti, pi], w1[ti, pi], w2[ti, pi]], 1))
        k *= 2
    if not pix:
        return np.zeros(0, np.int64), np.zeros(0, np.int64), np.zeros((0, 3))
    pix, tri, bary = np.concatenate(pix), np.concatenate(tri), np.concatenate(bary)
    # a texel on a shared edge is found twice: once will do
    _, first = np.unique(pix, return_index=True)
    return pix[first], tri[first], bary[first]


def at_texels(body, values, tri, bary):
    """A per-vertex value carried to those texels."""
    v = values[body.idx[tri]]
    if v.ndim == 2:
        return (v * bary).sum(1)
    return (v * bary[:, :, None]).sum(1)


def covered(body, W, H):
    """True for every texel some triangle of the model colours."""
    out = np.zeros(W * H, bool)
    n = len(body.idx)
    for s in range(0, n, 20000):
        pix, _, _ = texels(body, np.arange(s, min(n, s + 20000)), W, H)
        out[pix] = True
    return out.reshape(H, W)


def regutter(img, cover, changed, reach=8):
    """The margin round the islands near what was painted, filled again from
    the nearest texel of an island. img: H x W x 3, cover: H x W bool (the
    islands), changed: H x W bool (texels painted). Only margin texels within
    `reach` of a painted texel are touched."""
    import cv2
    from scipy import ndimage
    H, W = cover.shape
    ys, xs = np.where(changed)
    if len(ys) == 0:
        return 0
    k = np.ones((2 * reach + 1, 2 * reach + 1), np.uint8)
    near = cv2.dilate(changed.astype(np.uint8), k).astype(bool) & ~cover
    y0, y1 = max(ys.min() - reach - 2, 0), min(ys.max() + reach + 3, H)
    x0, x1 = max(xs.min() - reach - 2, 0), min(xs.max() + reach + 3, W)
    # worked a block at a time: the picture is big and the paint is in patches
    lab, n = ndimage.label(near[y0:y1, x0:x1])
    total = 0
    for sl in ndimage.find_objects(lab):
        a0, a1 = max(sl[0].start + y0 - reach, 0), min(sl[0].stop + y0 + reach, H)
        b0, b1 = max(sl[1].start + x0 - reach, 0), min(sl[1].stop + x0 + reach, W)
        cv, nr = cover[a0:a1, b0:b1], near[a0:a1, b0:b1]
        if not cv.any():
            continue
        _, (iy, ix) = ndimage.distance_transform_edt(~cv, return_indices=True)
        block = img[a0:a1, b0:b1]
        block[nr] = block[iy[nr], ix[nr]]
        total += int(nr.sum())
    return total
