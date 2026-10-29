"""Covers a hole in a character's back with a patch of its own surface.

Corin's model (29 October, Gary: "there is still a hole in the back of Corin
at the top when he turns around") has a pit at his left shoulder blade
about 5 by 6 cm, where the back's skin dips in through the body, so from
behind you see into him and out through his chest. mend_winding.py and
mend_corin_back.py (23 October) only turned triangles round and recoloured
them. This lays a patch over it: the back seen from behind is rastered (the
nearest surface at each point, and what it shows), the pit's depth filled
in smoothly from the back round it, and a disc of new triangles laid on
that filled surface a few millimetres proud of it, as a second surface of
the same mesh with the same material:
  - where the surface round the pit shows the vest, the patch shows the very
    same texture (its UVs are the surface's own there), so it melts into it;
  - over the pit itself, and anywhere a triangle would span two islands of
    the atlas, it shows a spot of the vest's leather (`--leather U,V`),
    spread a little so it isn't flat;
  - each corner takes the skin weights of the nearest vertex of the back
    round the pit, so it moves with him.

    python3 tools/patch_hole.py MODEL.glb --at X,Y --radius R [--leather U,V] [--view back|front] [--mirror] [--bake] [--dry]

--mirror takes the patch's texture from the other side of the back, the
same place mirrored across his middle (x to -x): a clean stretch of the
same vest, so the patch reads as the vest itself rather than a smear of
its colour (29 October: Corin's left shoulder blade, his right one clean).
--bake (with --mirror) paints the patch a texture of its own instead,
MODEL_patch.png and MODEL_patch_mr.png beside the model (the atlas and its
metal-roughness map as the surface shows them, mirrored across the back),
with its own material: the surface's own colours at its rim, blending to
the mirrored side's towards its middle, so no seam of the atlas and no edge
shows.

X and Y are in the model's own metres (x to his left, y up); the model is
rewritten in place (unless --dry, which writes MODEL_patch_debug.png only).
"""
import argparse, json, struct
import numpy as np

CT = {5126: ("<f4", 4), 5123: ("<u2", 2), 5125: ("<u4", 4), 5121: ("<u1", 1)}
N_OF = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load(path):
    d = open(path, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    b = bytearray(d[off + 8:off + 8 + bl])
    tail = d[off + 8 + bl:]
    return j, b, tail


def get(j, b, i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    o = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    dt, sz = CT[a["componentType"]]
    n = N_OF[a["type"]]
    st = v.get("byteStride", 0)
    isz = sz * n
    if st and st != isz:
        arr = np.array([np.frombuffer(bytes(b[o + k * st:o + k * st + isz]), dtype=dt) for k in range(a["count"])])
    else:
        arr = np.frombuffer(bytes(b[o:o + a["count"] * isz]), dtype=dt).reshape(a["count"], n)
    return arr


def save(path, j, b, tail):
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    while len(b) % 4:
        b.append(0)
    out = bytearray()
    total = 12 + 8 + len(js) + 8 + len(b) + len(tail)
    out += struct.pack("<4sII", b"glTF", 2, total)
    out += struct.pack("<I4s", len(js), b"JSON") + js
    out += struct.pack("<I4s", len(b), b"BIN\x00") + b
    out += tail
    open(path, "wb").write(bytes(out))


def raster(P, I, UV, x0, x1, y0, y1, S, sign):
    """The nearest surface seen along +z (sign 1: from behind) or -z (from the front)."""
    w = int((x1 - x0) * S)
    h = int((y1 - y0) * S)
    zb = np.full((h, w), np.inf)
    uvb = np.zeros((h, w, 2))
    tb = np.full((h, w), -1)
    tri = P[I]
    cand = np.where((tri[:, :, 1].min(1) < y1) & (tri[:, :, 1].max(1) > y0) & (tri[:, :, 0].min(1) < x1) & (tri[:, :, 0].max(1) > x0))[0]
    for t in cand:
        pts = tri[t]
        xs = (x1 - pts[:, 0]) * S if sign > 0 else (pts[:, 0] - x0) * S
        ys = (y1 - pts[:, 1]) * S
        zs = pts[:, 2] * sign
        minx = max(int(np.floor(xs.min())), 0)
        maxx = min(int(np.ceil(xs.max())), w - 1)
        miny = max(int(np.floor(ys.min())), 0)
        maxy = min(int(np.ceil(ys.max())), h - 1)
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
        m = (l1 >= 0) & (l2 >= 0) & (l3 >= 0)
        z = l1 * zs[0] + l2 * zs[1] + l3 * zs[2]
        sub = zb[miny:maxy + 1, minx:maxx + 1]
        upd = m & (z < sub)
        sub[upd] = z[upd]
        tb[miny:maxy + 1, minx:maxx + 1][upd] = t
        u = UV[I[t]]
        uvb[miny:maxy + 1, minx:maxx + 1, 0][upd] = (l1 * u[0, 0] + l2 * u[1, 0] + l3 * u[2, 0])[upd]
        uvb[miny:maxy + 1, minx:maxx + 1, 1][upd] = (l1 * u[0, 1] + l2 * u[1, 1] + l3 * u[2, 1])[upd]
    return zb * sign, uvb, tb


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("--at", required=True)
    ap.add_argument("--radius", type=float, default=0.05)
    ap.add_argument("--leather", default="0.095,0.939")
    ap.add_argument("--view", default="back")
    ap.add_argument("--proud", type=float, default=0.003)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--mirror", action="store_true")
    ap.add_argument("--bake", action="store_true")
    a = ap.parse_args()
    cx, cy = [float(v) for v in a.at.split(",")]
    lu, lv = [float(v) for v in a.leather.split(",")]
    R = a.radius
    sign = 1 if a.view == "back" else -1
    j, b, tail = load(a.model)
    prim = j["meshes"][0]["primitives"][0]
    at = prim["attributes"]
    P = get(j, b, at["POSITION"]).astype(np.float64)
    UV = get(j, b, at["TEXCOORD_0"]).astype(np.float64)
    I = get(j, b, prim["indices"]).reshape(-1, 3).astype(np.int64)
    J = get(j, b, at["JOINTS_0"])
    W = get(j, b, at["WEIGHTS_0"]).astype(np.float64)
    S = 1000.0
    m = R + 0.03
    x0, x1, y0, y1 = cx - m, cx + m, cy - m, cy + m
    if a.mirror:
        x0, x1 = -abs(cx) - m, abs(cx) + m
    zb, uvb, tb = raster(P, I, UV, x0, x1, y0, y1, S, sign)
    h, w = zb.shape
    def pix(x, y):
        px = (x1 - x) * S if sign > 0 else (x - x0) * S
        return int(np.clip((y1 - y) * S, 0, h - 1)), int(np.clip(px, 0, w - 1))
    # the back round about: its median depth in a ring; the pit is anything
    # much deeper (further into him) than that, or nothing at all
    Yg, Xg = np.mgrid[0:h, 0:w]
    xs = x1 - (Xg + 0.5) / S if sign > 0 else x0 + (Xg + 0.5) / S
    ys = y1 - (Yg + 0.5) / S
    rr = np.hypot(xs - cx, ys - cy)
    ring = (rr > R * 0.8) & (rr < R) & np.isfinite(zb)
    ref = np.median(zb[ring])
    deep = ~np.isfinite(zb) | ((zb - ref) * sign > 0.025)
    hole = deep & (rr < R)
    # its depth filled in from round it (Jacobi on the masked pixels)
    zf = np.where(np.isfinite(zb), zb, ref)
    zf[hole] = ref
    for _ in range(1500):
        zn = 0.25 * (np.roll(zf, 1, 0) + np.roll(zf, -1, 0) + np.roll(zf, 1, 1) + np.roll(zf, -1, 1))
        zf[hole] = zn[hole]
    # where the texture can be the surface's own: shown, not the pit, and a
    # centimetre clear of it
    near = hole.copy()
    for _ in range(10):
        near = near | np.roll(near, 1, 0) | np.roll(near, -1, 0) | np.roll(near, 1, 1) | np.roll(near, -1, 1)
    own = np.isfinite(zb) & ~near
    print("%s: the pit %d mm square across, %.1f cm deep at most; the back round it at z %.3f" % (
        a.model, hole.sum(), np.nanmax(np.where(hole & np.isfinite(zb), (zb - ref) * sign, 0)) * 100, ref))
    if a.dry:
        from PIL import Image
        img = np.zeros((h, w, 3), np.uint8)
        img[np.isfinite(zb)] = [90, 90, 90]
        img[own] = [70, 140, 70]
        img[hole] = [220, 60, 60]
        Image.fromarray(img).save(a.model[:-4] + "_patch_debug.png")
        return
    # the patch: a grid over the disc, on the filled surface, proud of it
    n = 28
    gx = np.linspace(cx - R, cx + R, n + 1)
    gy = np.linspace(cy - R, cy + R, n + 1)
    pos = {}
    def corner(ix, iy):
        x, y = gx[ix], gy[iy]
        r, c = pix(x, y)
        return np.array([x, y, zf[r, c] - sign * a.proud]), (r, c)
    # the slope of the filled surface, for the normals
    gz0, gz1 = np.gradient(zf, 1.0 / S)   # d/drow (y down), d/dcol
    verts, norms, uvs, joints, weights, idx = [], [], [], [], [], []
    # skin: the nearest vertex of the back round the pit
    good = []
    for vi in np.where((np.abs(P[:, 0] - cx) < m) & (np.abs(P[:, 1] - cy) < m))[0]:
        r, c = pix(P[vi, 0], P[vi, 1])
        if np.isfinite(zb[r, c]) and abs(P[vi, 2] - zb[r, c]) < 0.01 and not hole[r, c]:
            good.append(vi)
    good = np.array(good)
    for ix in range(n):
        for iy in range(n):
            quad = [(ix, iy), (ix + 1, iy), (ix + 1, iy + 1), (ix, iy + 1)]
            mids = np.array([[gx[q[0]], gy[q[1]]] for q in quad]).mean(0)
            if np.hypot(*(mids - [cx, cy])) > R:
                continue
            for tri in ([quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]):
                cs = [corner(*q) for q in tri]
                p3 = np.array([c[0] for c in cs])
                # its texture from the surface there (or, mirrored, across
                # his back); a triangle that would straddle a seam of the
                # atlas looks a little way off for a spot that doesn't
                ok = False
                tuv_arr = None
                for sh in ([(0.0, 0.0)] + [(dx, dy) for dx in (0.0, 0.006, -0.006, 0.012, -0.012) for dy in (0.0, 0.006, -0.006, 0.012, -0.012)][1:]) if a.mirror else [(0.0, 0.0)]:
                    tuv = []
                    good_t = True
                    for (pp, (r, c)) in cs:
                        if a.mirror:
                            r, c = pix(-pp[0] + sh[0], pp[1] + sh[1])
                        if own[r, c]:
                            tuv.append(uvb[r, c])
                        else:
                            good_t = False
                            break
                    if not good_t:
                        continue
                    arr = np.array(tuv)
                    if np.ptp(arr[:, 0]) <= 0.02 and np.ptp(arr[:, 1]) <= 0.02:
                        ok = True
                        tuv_arr = arr
                        break
                if not ok:
                    tuv_arr = np.array([[lu + (pp[0] - cx) * 0.06, lv - (pp[1] - cy) * 0.06] for pp in p3])
                fnrm = np.cross(p3[1] - p3[0], p3[2] - p3[0])
                out = np.array([0, 0, -sign], float)
                order = [0, 1, 2] if fnrm.dot(out) > 0 else [0, 2, 1]
                base = len(verts)
                for k in order:
                    pp = p3[k]
                    r, c = cs[k][1]
                    dzdx = -gz1[r, c] if sign > 0 else gz1[r, c]
                    dzdy = -gz0[r, c]
                    nv = np.array([dzdx, dzdy, -1.0]) * sign if sign > 0 else np.array([-dzdx, -dzdy, 1.0])
                    nv = nv / np.linalg.norm(nv)
                    verts.append(pp)
                    norms.append(nv)
                    uvs.append(tuv_arr[k])
                    d2 = (P[good, 0] - pp[0]) ** 2 + (P[good, 1] - pp[1]) ** 2 + (P[good, 2] - pp[2]) ** 2
                    src = good[int(np.argmin(d2))]
                    joints.append(J[src])
                    weights.append(W[src])
                idx += [base, base + 1, base + 2]
    if a.bake:
        from PIL import Image
        import os
        base = os.path.dirname(a.model)
        imgs = [os.path.join(base, im["uri"]) for im in j["images"]]
        tex_of = lambda k: j["textures"][j["materials"][prim.get("material", 0)]["pbrMetallicRoughness"][k]["index"]]["source"]
        pbr = j["materials"][prim.get("material", 0)]["pbrMetallicRoughness"]
        N = 256
        ii, jj = np.mgrid[0:N, 0:N]
        tx = cx - R + (jj + 0.5) / N * 2 * R
        ty = cy + R - (ii + 0.5) / N * 2 * R
        def look(x, y):
            px = ((x1 - x) * S if sign > 0 else (x - x0) * S).astype(int).clip(0, w - 1)
            py = ((y1 - y) * S).astype(int).clip(0, h - 1)
            return py, px
        ra, ca = look(tx, ty)
        rm, cm = look(-tx, ty)
        r_t = np.hypot(tx - cx, ty - cy)
        wa = np.clip((r_t - 0.55 * R) / (0.4 * R), 0, 1) * own[ra, ca]
        okm = np.isfinite(zb[rm, cm])
        out_names = []
        for key, suffix in (("baseColorTexture", "_patch.png"), ("metallicRoughnessTexture", "_patch_mr.png")):
            if key not in pbr:
                continue
            src = np.asarray(Image.open(imgs[tex_of(key)]).convert("RGB")).astype(np.float64)
            H2, W2 = src.shape[:2]
            def sample(uv):
                u = (uv[..., 0] % 1.0) * W2 - 0.5
                v = (uv[..., 1] % 1.0) * H2 - 0.5
                u0 = np.floor(u).astype(int); v0 = np.floor(v).astype(int)
                fu = (u - u0)[..., None]; fv = (v - v0)[..., None]
                g = lambda yy, xx: src[yy % H2, xx % W2]
                return (g(v0, u0) * (1 - fu) * (1 - fv) + g(v0, u0 + 1) * fu * (1 - fv) + g(v0 + 1, u0) * (1 - fu) * fv + g(v0 + 1, u0 + 1) * fu * fv)
            ca_col = sample(uvb[ra, ca])
            cm_col = sample(uvb[rm, cm])
            med = np.median(cm_col[okm], axis=0)
            cm_col[~okm] = med
            col = ca_col * wa[..., None] + cm_col * (1 - wa[..., None])
            name = os.path.basename(a.model)[:-4] + suffix
            Image.fromarray(col.clip(0, 255).astype(np.uint8)).save(os.path.join(base, name))
            out_names.append((key, name))
        newmat = {"name": j["materials"][prim.get("material", 0)].get("name", "") + "_patch", "pbrMetallicRoughness": {
            "metallicFactor": pbr.get("metallicFactor", 1.0), "roughnessFactor": pbr.get("roughnessFactor", 1.0)}}
        for key, name in out_names:
            j["images"].append({"name": name[:-4], "uri": name})
            j["textures"].append({"sampler": j["textures"][0].get("sampler", 0), "source": len(j["images"]) - 1})
            newmat["pbrMetallicRoughness"][key] = {"index": len(j["textures"]) - 1}
        j["materials"].append(newmat)
        uvs = [np.array([(v[0] - (cx - R)) / (2 * R), (cy + R - v[1]) / (2 * R)]) for v in verts]
    verts = np.array(verts, np.float32)
    norms = np.array(norms, np.float32)
    uvs = np.array(uvs, np.float32)
    joints = np.array(joints).astype(CT[j["accessors"][at["JOINTS_0"]]["componentType"]][0])
    weights = np.array(weights, np.float32)
    idx = np.array(idx, np.uint32)
    # appended to the buffer, each its own view, a second primitive
    def add(arr, typ, ctype, target=None, minmax=False):
        while len(b) % 4:
            b.append(0)
        o = len(b)
        raw = arr.tobytes()
        b.extend(raw)
        view = {"buffer": 0, "byteOffset": o, "byteLength": len(raw)}
        if target:
            view["target"] = target
        j["bufferViews"].append(view)
        acc = {"bufferView": len(j["bufferViews"]) - 1, "componentType": ctype, "count": int(arr.shape[0]) if typ != "SCALAR" else int(arr.size), "type": typ}
        if minmax:
            acc["min"] = arr.min(0).tolist()
            acc["max"] = arr.max(0).tolist()
        j["accessors"].append(acc)
        return len(j["accessors"]) - 1
    jt = j["accessors"][at["JOINTS_0"]]["componentType"]
    newp = {"attributes": {
        "POSITION": add(verts, "VEC3", 5126, 34962, True),
        "NORMAL": add(norms, "VEC3", 5126, 34962),
        "TEXCOORD_0": add(uvs, "VEC2", 5126, 34962),
        "JOINTS_0": add(joints, "VEC4", jt, 34962),
        "WEIGHTS_0": add(weights, "VEC4", 5126, 34962)},
        "indices": add(idx, "SCALAR", 5125, 34963), "mode": 4}
    if a.bake:
        newp["material"] = len(j["materials"]) - 1
    elif "material" in prim:
        newp["material"] = prim["material"]
    j["meshes"][0]["primitives"].append(newp)
    j["buffers"][0]["byteLength"] = len(b)
    save(a.model, j, b, tail)
    print("%s: a patch of %d triangles laid over it" % (a.model, len(idx) // 3))


if __name__ == "__main__":
    main()
