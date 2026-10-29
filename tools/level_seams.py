"""Evens out the colour across a model's texture seams in one part of it.

A Tripo3D face is cut into many islands on its atlas, and its colours don't
always meet: down each side of Player A's nose (29 October, Gary: his
"face still look weird around the nose area") the islands either side of
the seam are a different shade, so the nose has a hard light band down one
side and a smudge down the other, and looks pinched and pasted on. This
finds every seam in a region of the model (a box in its own metres), takes
the colour a few texels in on each side all the way along it, and moves
both sides to meet halfway, the change fading out over `--reach` texels into
each island, so the seam is gone and the painting away from it is as it was.
The atlas is rewritten in place (its old self kept as ATLAS.orig.png the
first time).

    python3 tools/level_seams.py MODEL.glb --box X0,Y0,Z0:X1,Y1,Z1 [--reach 18] [--passes 2]
    (the atlas is the model's baseColor image, beside it)
"""
import argparse, json, os, struct
from collections import defaultdict
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, distance_transform_edt
from scipy.spatial import cKDTree

CT = {5126: "<f4", 5123: "<u2", 5125: "<u4", 5121: "<u1"}
N_OF = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


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


def raster_ids(UV, I, tris, W, H):
    """Which triangle covers each texel (-1: none), for the given triangles."""
    ids = np.full((H, W), -1, np.int64)
    for t in tris:
        u = UV[I[t]] * [W, H]
        xs, ys = u[:, 0] - 0.5, u[:, 1] - 0.5
        minx, maxx = max(int(np.floor(xs.min())) - 1, 0), min(int(np.ceil(xs.max())) + 1, W - 1)
        miny, maxy = max(int(np.floor(ys.min())) - 1, 0), min(int(np.ceil(ys.max())) + 1, H - 1)
        if minx > maxx or miny > maxy:
            continue
        X, Y = np.meshgrid(np.arange(minx, maxx + 1), np.arange(miny, maxy + 1))
        (ax, bx, cx), (ay, by, cy) = xs, ys
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-12:
            continue
        l1 = ((by - cy) * (X - cx) + (cx - bx) * (Y - cy)) / d
        l2 = ((cy - ay) * (X - cx) + (ax - cx) * (Y - cy)) / d
        l3 = 1 - l1 - l2
        m = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
        sub = ids[miny:maxy + 1, minx:maxx + 1]
        sub[m & (sub < 0)] = t
    return ids


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("--box", required=True)
    ap.add_argument("--reach", type=float, default=18.0)
    ap.add_argument("--passes", type=int, default=2)
    a = ap.parse_args()
    lo, hi = [np.array([float(v) for v in s.split(",")]) for s in a.box.split(":")]
    j, b = load(a.model)
    prim = j["meshes"][0]["primitives"][0]
    P = get(j, b, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = get(j, b, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    I = get(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    mat = j["materials"][prim.get("material", 0)]
    img_i = j["textures"][mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]]["source"]
    atlas = os.path.join(os.path.dirname(a.model), j["images"][img_i]["uri"])
    orig = atlas[:-4] + ".orig.png"
    if not os.path.exists(orig):
        Image.open(atlas).save(orig)
    img = np.asarray(Image.open(atlas).convert("RGB")).astype(np.float64)
    H, W = img.shape[:2]
    C = P[I].mean(1)
    region = np.where(np.all((C >= lo) & (C <= hi), axis=1))[0]
    inreg = np.zeros(len(I), bool)
    inreg[region] = True
    key = np.round(P, 5)
    _, weld = np.unique(key, axis=0, return_inverse=True)
    weld = weld.ravel()
    edges = defaultdict(list)
    for t in region:
        for k in range(3):
            x, y = I[t, k], I[t, (k + 1) % 3]
            edges[tuple(sorted((weld[x], weld[y])))].append((t, x, y))
    ids = raster_ids(UV, I, region, W, H)
    covered = ids >= 0
    # the islands: triangles joined by edges that aren't seams
    parent = {int(t): int(t) for t in region}
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
    island = np.full(len(I), -1, np.int64)
    for t in region:
        island[t] = find(int(t))
    tex_island = np.where(covered, island[np.maximum(ids, 0)], -1)
    for ps in range(a.passes):
        blur = np.stack([gaussian_filter(img[..., c], 1.5) for c in range(3)], -1)
        pts, deltas, owner = [], [], []
        nseam = 0
        for k, v in edges.items():
            if len(v) != 2:
                continue
            (t1, a1, b1), (t2, a2, b2) = v
            uv1 = {weld[a1]: UV[a1], weld[b1]: UV[b1]}
            uv2 = {weld[a2]: UV[a2], weld[b2]: UV[b2]}
            if all(np.linalg.norm(uv1[q] - uv2[q]) < 1e-4 for q in k):
                continue
            nseam += 1
            # along the edge on each side, a few texels in towards each
            # triangle's middle
            ca1 = UV[I[t1]].mean(0)
            ca2 = UV[I[t2]].mean(0)
            L = max(np.linalg.norm((uv1[k[1]] - uv1[k[0]]) * [W, H]), 2.0)
            n = int(np.clip(L / 2.0, 3, 60))
            for s in (np.arange(n) + 0.5) / n:
                p1 = uv1[k[0]] * (1 - s) + uv1[k[1]] * s
                p2 = uv2[k[0]] * (1 - s) + uv2[k[1]] * s
                in1 = p1 + (ca1 - p1) / max(np.linalg.norm((ca1 - p1) * [W, H]), 1e-6) * 2.5
                in2 = p2 + (ca2 - p2) / max(np.linalg.norm((ca2 - p2) * [W, H]), 1e-6) * 2.5
                c1 = blur[int(np.clip(in1[1] * H, 0, H - 1)), int(np.clip(in1[0] * W, 0, W - 1))]
                c2 = blur[int(np.clip(in2[1] * H, 0, H - 1)), int(np.clip(in2[0] * W, 0, W - 1))]
                mid = (c1 + c2) * 0.5
                pts.append(p1 * [W, H]); deltas.append(mid - c1); owner.append(island[t1])
                pts.append(p2 * [W, H]); deltas.append(mid - c2); owner.append(island[t2])
        pts = np.array(pts)
        deltas = np.array(deltas)
        owner = np.array(owner)
        print("pass %d: %d seams, %d samples, mean mismatch %.1f" % (ps + 1, nseam, len(pts) // 2, np.abs(deltas).mean() * 2))
        # each texel near a seam takes the samples near it on its own island
        # (islands packed side by side on the atlas mustn't trade colours)
        for isl in np.unique(owner):
            sel = owner == isl
            tree = cKDTree(pts[sel])
            dl = deltas[sel]
            yy, xx = np.where(tex_island == isl)
            if len(yy) == 0:
                continue
            q = np.stack([xx + 0.5, yy + 0.5], 1)
            kk = min(8, int(sel.sum()))
            dist, idx = tree.query(q, k=kk, distance_upper_bound=a.reach)
            if kk == 1:
                dist, idx = dist[:, None], idx[:, None]
            ok = np.isfinite(dist)
            wts = np.where(ok, 1.0 / np.maximum(dist, 1.0) ** 2, 0.0)
            idx = np.where(ok, idx, 0)
            sw = wts.sum(1)
            corr = (dl[idx] * wts[..., None]).sum(1) / np.maximum(sw, 1e-9)[:, None]
            dmin = np.where(ok[:, 0], dist[:, 0], a.reach)
            fade = np.clip(1.0 - dmin / a.reach, 0.0, 1.0) ** 1.5
            img[yy, xx] += corr * fade[:, None]
        img = img.clip(0, 255)
    Image.fromarray(img.astype(np.uint8)).save(atlas)
    print("%s: seams levelled in %d triangles" % (atlas, len(region)))


if __name__ == "__main__":
    main()
