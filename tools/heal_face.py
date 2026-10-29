"""Heals a stretch of a model's face texture, seen from the front.

Player A's Tripo3D atlas cuts his face into a hundred small islands, and
down the right side of his nose one of them is a smeared strip of orange
from the eye's corner to the nostril, with hard edges both sides, and the
other side of the nose has a hard seam (29 October, Gary: his "face still
look weird around the nose area"). This:

  1. renders the face's texture flat from the front (each pixel the colour
     of the nearest surface there), in the model's own metres (`--window`);
  2. fills each `--patch` (a polygon of x,y points) smoothly from the skin
     round it (its low tones solved as a membrane from its edges), with the
     fine grain of the skin `--grain` metres across laid over it (the other
     side of the face, mirrored, was tried: it has seams of its own);
  3. inside `--seams` (a box x0,y0:x1,y1) takes out the hard edges where two
     islands meet (inpainting a thin line along each);
  4. writes the change back into the atlas: every texel of every triangle
     that's seen from the front there takes the change at the point it
     lands on (the healed picture less the picture as it was), so texels
     nothing healed touched are left exactly as they were, and a triangle
     side-on to the front (the nose's steep sides) only partly (by how
     squarely it faces forward).

The atlas is rewritten in place. A picture of the face before and after
goes to `--debug` if given.

  python3 tools/heal_face.py MODEL.glb --window X0,X1,Y0,Y1 [--grain DX] \\
      --patch "x,y;x,y;..." [--patch ...] [--seams X0,Y0:X1,Y1] [--debug out.png]
"""
import argparse, json, os, struct
import numpy as np
import cv2
from PIL import Image

CT = {5126: "<f4", 5123: "<u2", 5125: "<u4", 5121: "<u1"}
N_OF = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
S = 5000.0   # pixels a metre in the front picture


def load(path):
    d = open(path, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    return j, d[off + 8:off + 8 + bl]


def get(j, b, i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    o = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    dt = CT[a["componentType"]]
    n = N_OF[a["type"]]
    isz = np.dtype(dt).itemsize * n
    st = v.get("byteStride", 0)
    if st and st != isz:
        return np.array([np.frombuffer(b[o + k * st:o + k * st + isz], dtype=dt) for k in range(a["count"])])
    return np.frombuffer(b[o:o + a["count"] * isz], dtype=dt).reshape(a["count"], n)


def bilinear(src, x, y):
    h, w = src.shape[:2]
    x = np.clip(x - 0.5, 0, w - 1.001)
    y = np.clip(y - 0.5, 0, h - 1.001)
    x0 = np.floor(x).astype(int)
    y0 = np.floor(y).astype(int)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    return (src[y0, x0] * (1 - fx) * (1 - fy) + src[y0, x0 + 1] * fx * (1 - fy) +
            src[y0 + 1, x0] * (1 - fx) * fy + src[y0 + 1, x0 + 1] * fx * fy)


def front(P, I, UV, win):
    x0, x1, y0, y1 = win
    w = int((x1 - x0) * S)
    h = int((y1 - y0) * S)
    zb = np.full((h, w), -np.inf)
    uvb = np.zeros((h, w, 2))
    tb = np.full((h, w), -1, np.int64)
    tri = P[I]
    cand = np.where((tri[:, :, 1].min(1) < y1) & (tri[:, :, 1].max(1) > y0) & (tri[:, :, 0].min(1) < x1) & (tri[:, :, 0].max(1) > x0))[0]
    for t in cand:
        pts = tri[t]
        xs = (pts[:, 0] - x0) * S
        ys = (y1 - pts[:, 1]) * S
        zs = pts[:, 2]
        minx, maxx = max(int(np.floor(xs.min())), 0), min(int(np.ceil(xs.max())), w - 1)
        miny, maxy = max(int(np.floor(ys.min())), 0), min(int(np.ceil(ys.max())), h - 1)
        if minx > maxx or miny > maxy:
            continue
        X, Y = np.meshgrid(np.arange(minx, maxx + 1) + 0.5, np.arange(miny, maxy + 1) + 0.5)
        (ax, bx, cx), (ay, by, cy) = xs, ys
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-14:
            continue
        l1 = ((by - cy) * (X - cx) + (cx - bx) * (Y - cy)) / d
        l2 = ((cy - ay) * (X - cx) + (ax - cx) * (Y - cy)) / d
        l3 = 1 - l1 - l2
        m = (l1 >= -1e-6) & (l2 >= -1e-6) & (l3 >= -1e-6)
        z = l1 * zs[0] + l2 * zs[1] + l3 * zs[2]
        sub = zb[miny:maxy + 1, minx:maxx + 1]
        upd = m & (z > sub)
        sub[upd] = z[upd]
        tb[miny:maxy + 1, minx:maxx + 1][upd] = t
        u = UV[I[t]]
        for k in range(2):
            uvb[miny:maxy + 1, minx:maxx + 1, k][upd] = (l1 * u[0, k] + l2 * u[1, k] + l3 * u[2, k])[upd]
    return zb, uvb, tb


def islands(P, UV, I, tris):
    key = np.round(P, 5)
    _, weld = np.unique(key, axis=0, return_inverse=True)
    weld = weld.ravel()
    edges = {}
    for t in tris:
        for k in range(3):
            x, y = I[t, k], I[t, (k + 1) % 3]
            edges.setdefault(tuple(sorted((weld[x], weld[y]))), []).append((t, x, y))
    parent = {int(t): int(t) for t in tris}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for k, v in edges.items():
        if len(v) != 2:
            continue
        (t1, a1, b1), (t2, a2, b2) = v
        uv1 = {weld[a1]: UV[a1], weld[b1]: UV[b1]}
        uv2 = {weld[a2]: UV[a2], weld[b2]: UV[b2]}
        if all(np.linalg.norm(uv1[q] - uv2[q]) < 1e-4 for q in k):
            parent[find(int(t1))] = find(int(t2))
    return {int(t): find(int(t)) for t in tris}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("--window", required=True)
    ap.add_argument("--grain", type=float, default=0.014)
    ap.add_argument("--patch", action="append", default=[])
    ap.add_argument("--seams", default="")
    ap.add_argument("--debug", default="")
    a = ap.parse_args()
    win = [float(v) for v in a.window.split(",")]
    x0, x1, y0, y1 = win
    j, b = load(a.model)
    prim = j["meshes"][0]["primitives"][0]
    P = get(j, b, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = get(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    I = get(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    mat = j["materials"][prim.get("material", 0)]
    img_i = j["textures"][mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]]["source"]
    atlas_path = os.path.join(os.path.dirname(a.model), j["images"][img_i]["uri"])
    atlas = np.asarray(Image.open(atlas_path).convert("RGB")).astype(np.float64)
    H, W = atlas.shape[:2]
    zb, uvb, tb = front(P, I, UV, win)
    h, w = tb.shape
    seen = tb >= 0
    A0 = bilinear(atlas, uvb[..., 0] * W, uvb[..., 1] * H)
    A0[~seen] = 0
    A = A0.copy()
    to_px = lambda x, y: ((x - x0) * S, (y1 - y) * S)
    healed = np.zeros((h, w), np.float64)
    # 2. the patches: filled smoothly from the skin round them (the low
    # tones), with the fine grain of the skin beside them (`--grain`: how far
    # across, in metres, to take it from) laid over, so it isn't flat
    from scipy.ndimage import gaussian_filter
    low0 = np.stack([gaussian_filter(A[..., c], 3) for c in range(3)], -1)
    for poly in a.patch:
        pts = np.array([[float(v) for v in q.split(",")] for q in poly.split(";")])
        px = np.array([to_px(x, y) for x, y in pts], np.int32)
        mask = np.zeros((h, w), np.uint8)
        cv2.fillPoly(mask, [px], 255)
        mask = cv2.dilate(mask, np.ones((7, 7), np.uint8)) > 0
        L = low0.copy()
        for it in range(3000):
            n = 0.25 * (np.roll(L, 1, 0) + np.roll(L, -1, 0) + np.roll(L, 1, 1) + np.roll(L, -1, 1))
            L[mask] = n[mask]
        grain = np.roll(A0 - low0, int(round(a.grain * S)), axis=1)
        A[mask] = (L + grain)[mask]
        healed = np.maximum(healed, mask.astype(np.float64))
        print("patch: %d px filled" % mask.sum())
    # 3. the hard edges where islands meet, inside the seams box
    if a.seams:
        (sx0, sy0), (sx1, sy1) = [[float(v) for v in s.split(",")] for s in a.seams.split(":")]
        vis = np.unique(tb[seen])
        isl = islands(P, UV, I, vis)
        lab = np.full((h, w), -1, np.int64)
        lab[seen] = np.array([isl[int(t)] for t in tb[seen]])
        edge = np.zeros((h, w), bool)
        edge[:, 1:] |= (lab[:, 1:] != lab[:, :-1]) & (lab[:, 1:] >= 0) & (lab[:, :-1] >= 0)
        edge[1:, :] |= (lab[1:, :] != lab[:-1, :]) & (lab[1:, :] >= 0) & (lab[:-1, :] >= 0)
        bx = np.zeros((h, w), bool)
        p0 = [int(v) for v in to_px(sx0, sy1)]
        p1 = [int(v) for v in to_px(sx1, sy0)]
        bx[max(p0[1], 0):min(p1[1], h), max(p0[0], 0):min(p1[0], w)] = True
        sm = (cv2.dilate((edge & bx).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0)
        out = cv2.inpaint(A.clip(0, 255).astype(np.uint8), sm.astype(np.uint8), 4, cv2.INPAINT_TELEA)
        A = np.where(sm[..., None], out.astype(np.float64), A)
        healed = np.maximum(healed, sm.astype(np.float64))
        print("seams: %d px of hard edges taken out" % sm.sum())
    # a soft edge to what was healed, so nothing shows where it stops
    healed = cv2.GaussianBlur(healed, (0, 0), 2.0)
    delta = (A - A0) * healed[..., None]
    if a.debug:
        Image.fromarray(np.concatenate([A0, A0 + delta], 1).clip(0, 255).astype(np.uint8)).save(a.debug)
    # 4. back into the atlas
    fn = np.cross(P[I[:, 1]] - P[I[:, 0]], P[I[:, 2]] - P[I[:, 0]])
    fn /= np.linalg.norm(fn, axis=1)[:, None] + 1e-12
    out = atlas.copy()
    touched = 0
    for t in np.unique(tb[seen]):
        facing = np.clip((fn[t, 2] - 0.08) / 0.25, 0.0, 1.0)
        if facing <= 0.0:
            continue
        u = UV[I[t]] * [W, H]
        xs, ys = u[:, 0], u[:, 1]
        minx, maxx = max(int(np.floor(xs.min())) - 1, 0), min(int(np.ceil(xs.max())) + 1, W - 1)
        miny, maxy = max(int(np.floor(ys.min())) - 1, 0), min(int(np.ceil(ys.max())) + 1, H - 1)
        X, Y = np.meshgrid(np.arange(minx, maxx + 1) + 0.5, np.arange(miny, maxy + 1) + 0.5)
        (ax, bx_, cx), (ay, by, cy) = xs, ys
        d = (by - cy) * (ax - cx) + (cx - bx_) * (ay - cy)
        if abs(d) < 1e-12:
            continue
        l1 = ((by - cy) * (X - cx) + (cx - bx_) * (Y - cy)) / d
        l2 = ((cy - ay) * (X - cx) + (ax - cx) * (Y - cy)) / d
        l3 = 1 - l1 - l2
        m = (l1 >= -0.01) & (l2 >= -0.01) & (l3 >= -0.01)
        if not m.any():
            continue
        p3 = (l1[..., None] * P[I[t, 0]] + l2[..., None] * P[I[t, 1]] + l3[..., None] * P[I[t, 2]])
        px, py = to_px(p3[..., 0], p3[..., 1])
        ix = np.clip(px.astype(int), 0, w - 1)
        iy = np.clip(py.astype(int), 0, h - 1)
        # only where this very surface is what the front sees (not behind
        # the nose or under the hair)
        vis_ok = np.abs(zb[iy, ix] - p3[..., 2]) < 0.003
        m &= vis_ok
        if not m.any():
            continue
        dd = bilinear(delta, px, py)
        sub = out[miny:maxy + 1, minx:maxx + 1]
        sub[m] = (sub[m] + dd[m] * facing).clip(0, 255)
        touched += int((np.abs(dd[m]).sum(-1) > 0.5).sum())
    # and out into the gutter round each island (the texels no triangle
    # covers): the GPU's filtering reads a texel or two past a triangle's
    # edge, and the old colour left there showed as a hairline down every
    # seam of the healed part
    from scipy.ndimage import distance_transform_edt
    cover = np.zeros((H, W), bool)
    for t in range(len(I)):
        u = UV[I[t]] * [W, H]
        poly = np.round(u * 4).astype(np.int32)
        cv2.fillPoly(cover.view(np.uint8), [poly], 1, shift=2)
    changed = np.abs(out - atlas).sum(-1) > 0.5
    dist, (iy, ix) = distance_transform_edt(~changed, return_indices=True)
    gut = (~cover) & (dist <= 6)
    out[gut] = (atlas[gut] + (out - atlas)[iy[gut], ix[gut]]).clip(0, 255)
    Image.fromarray(out.astype(np.uint8)).save(atlas_path)
    print("%s: %d texels healed, %d of the gutter beside them" % (atlas_path, touched, int(gut.sum())))


if __name__ == "__main__":
    main()
