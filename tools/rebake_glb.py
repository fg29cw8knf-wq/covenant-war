"""Readies a raw Tripo3D prop (text to 3D: about two million triangles, its
pictures in thousands of small islands) for the game: a new low mesh, a new
unwrap, and Tripo's colour, roughness-metal and normal pictures baked across
onto it.

tools/slim_glb.py does this for a prop whose unwrap survives being decimated
(the baby bundle, 4 November). Gary's tunnel mouth and thorn bush (18
November) didn't: their unwraps are 2,600 and 4,300 islands, and a decimation
that keeps texture seams tears the mesh open along every one (the first try
left the bank full of triangle-shaped holes). So here the shape and the paint
are parted:

  1. stray pieces dropped if asked (--keep-main: the bush came with a second,
     smaller bush hanging in the air beside it);
  2. the mesh welded and decimated by shape alone to about --tris triangles
     (pymeshlab's quadric edge collapse; pip install pymeshlab, and libopengl0);
  3. a new unwrap in a few hundred charts (xatlas; pip install xatlas);
  4. each new texel finds the nearest point of Tripo's own surface and takes
     its colour and roughness-metal from Tripo's pictures there; its normal is
     Tripo's surface normal there (its mesh's with its normal map on top), said
     again in the new mesh's tangent space, so the low mesh is lit with the
     two million triangles' shape;
  5. written as slim_glb.py writes: <stem>.glb with <stem>_atlas.png (--size),
     <stem>_mr.png and <stem>_normal.png (half that) beside it and our import
     settings. The GLB carries the tangents the bake used, so Godot lights it
     with the same ones.

  python3 tools/rebake_glb.py in.glb assets/models/ashford/<stem>.glb --tris 30000 --size 4096 [--keep-main]

Prints how far the new surface is from the old (the mean and the worst, as a
share of the model's size) and how much of each picture is used.
tests/prop_peek.tscn renders the result.
"""
import argparse, io, json, os, struct, sys, time

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from scipy.spatial import cKDTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

Image.MAX_IMAGE_PIXELS = None


def read_glb(path):
    b = open(path, "rb").read()
    magic, _ver, length = struct.unpack("<III", b[:12])
    assert magic == 0x46546C67, "not a GLB"
    off = 12
    chunks = []
    while off < length:
        cl, ct = struct.unpack("<II", b[off:off + 8])
        chunks.append((ct, b[off + 8:off + 8 + cl]))
        off += 8 + cl
    return json.loads(chunks[0][1]), chunks[1][1]


def accessor(j, binc, i):
    ac = j["accessors"][i]
    v = j["bufferViews"][ac["bufferView"]]
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[ac["type"]]
    dt = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[ac["componentType"]]
    start = v.get("byteOffset", 0) + ac.get("byteOffset", 0)
    return np.frombuffer(binc, dt, count=ac["count"] * n, offset=start).reshape(ac["count"], n)


def unit(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-20)


def vertex_normals(P, F):
    fn = np.cross(P[F[:, 1]] - P[F[:, 0]], P[F[:, 2]] - P[F[:, 0]])   # (area-weighted)
    N = np.zeros_like(P)
    for k in range(3):
        np.add.at(N, F[:, k], fn)
    return unit(N)


def keep_main(P, F, share=0.02):
    """The faces of the biggest piece: pieces are told apart by the gaps
    between them (a grid of `share` of the model's size), not by the mesh's
    own joins (a bush's leaves needn't be joined to its twigs)."""
    lo = P.min(0)
    vox = float((P.max(0) - lo).max()) * share
    g = np.floor((P - lo) / vox).astype(np.int64)
    grid = np.zeros(g.max(0) + 1, bool)
    grid[g[:, 0], g[:, 1], g[:, 2]] = True
    lab, n = ndi.label(grid, structure=np.ones((3, 3, 3)))
    vl = lab[g[:, 0], g[:, 1], g[:, 2]]
    cnt = np.bincount(vl, minlength=n + 1)
    main = int(np.argmax(cnt))
    for c in range(1, n + 1):
        if c != main and cnt[c]:
            m = vl == c
            print("  dropped a stray piece: %d vertices, from %s to %s" % (cnt[c], np.round(P[m].min(0), 2), np.round(P[m].max(0), 2)))
    return F[(vl[F] == main).all(axis=1)]


def decimate(P, F, tris, quality=0.1, optimal=False):
    """Welded, then decimated by shape alone. `quality` low and `optimal`
    off keep thin things thin: a fern's leaflets need sliver triangles, and
    a vertex moved to the "best" place between two leaflets is in neither
    (at 0.5 and on, the bank's ferns and roots melted into smooth lumps at
    any count up to 100,000)."""
    import pymeshlab
    key = np.round(P.astype(np.float64) * 1e6).astype(np.int64)
    _, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    inv = inv.ravel()
    Pw = P[first].astype(np.float64)
    Fw = inv[F]
    Fw = Fw[(Fw[:, 0] != Fw[:, 1]) & (Fw[:, 1] != Fw[:, 2]) & (Fw[:, 0] != Fw[:, 2])]
    # (vertices no face uses any more, the stray piece's, left out)
    used = np.zeros(len(Pw), bool)
    used[Fw] = True
    remap = np.cumsum(used) - 1
    Pw, Fw = Pw[used], remap[Fw]
    ms = pymeshlab.MeshSet()
    ms.add_mesh(pymeshlab.Mesh(vertex_matrix=Pw, face_matrix=Fw.astype(np.int32)), "prop")
    ms.apply_filter("meshing_decimation_quadric_edge_collapse", targetfacenum=int(tris), qualitythr=float(quality),
                    preserveboundary=True, preservenormal=True, preservetopology=False, optimalplacement=bool(optimal),
                    planarquadric=True, autoclean=True)
    ms.apply_filter("meshing_remove_duplicate_faces")
    ms.apply_filter("meshing_remove_null_faces")
    ms.apply_filter("meshing_remove_unreferenced_vertices")
    m = ms.current_mesh()
    return m.vertex_matrix().astype(np.float64), m.face_matrix().astype(np.int64)


def tangents(P, F, UV, N):
    """Per-vertex tangent (xyz, w) from the unwrap, v counted upward (1 - v:
    glTF's and Godot's bitangent runs up the picture)."""
    p0, p1, p2 = P[F[:, 0]], P[F[:, 1]], P[F[:, 2]]
    u0, u1, u2 = UV[F[:, 0]], UV[F[:, 1]], UV[F[:, 2]]
    e1, e2 = p1 - p0, p2 - p0
    du1, du2 = u1[:, 0] - u0[:, 0], u2[:, 0] - u0[:, 0]
    dv1, dv2 = -(u1[:, 1] - u0[:, 1]), -(u2[:, 1] - u0[:, 1])
    det = du1 * dv2 - du2 * dv1
    ok = np.abs(det) > 1e-20
    r = np.where(ok, 1.0 / np.where(ok, det, 1.0), 0.0)
    ft = (e1 * dv2[:, None] - e2 * dv1[:, None]) * r[:, None]
    fb = (e2 * du1[:, None] - e1 * du2[:, None]) * r[:, None]
    area = np.linalg.norm(np.cross(e1, e2), axis=1)[:, None]
    ft, fb = unit(ft) * area, unit(fb) * area
    T = np.zeros_like(P)
    B = np.zeros_like(P)
    for k in range(3):
        np.add.at(T, F[:, k], ft)
        np.add.at(B, F[:, k], fb)
    T = T - N * (N * T).sum(1, keepdims=True)
    bad = np.linalg.norm(T, axis=1) < 1e-12
    if bad.any():
        # (a vertex whose charts cancel out: any direction across its normal)
        alt = np.where(np.abs(N[bad, :1]) < 0.9, [[1.0, 0, 0]], [[0, 1.0, 0]])
        T[bad] = np.cross(N[bad], alt)
    T = unit(T)
    w = np.where((np.cross(N, T) * B).sum(1) < 0.0, -1.0, 1.0)
    return T, w


def face_frames(P, F, UV):
    """Per-face tangent and bitangent (not normalised against anything yet)."""
    p0, p1, p2 = P[F[:, 0]], P[F[:, 1]], P[F[:, 2]]
    u0, u1, u2 = UV[F[:, 0]], UV[F[:, 1]], UV[F[:, 2]]
    e1, e2 = p1 - p0, p2 - p0
    du1, du2 = u1[:, 0] - u0[:, 0], u2[:, 0] - u0[:, 0]
    dv1, dv2 = -(u1[:, 1] - u0[:, 1]), -(u2[:, 1] - u0[:, 1])
    det = du1 * dv2 - du2 * dv1
    ok = np.abs(det) > 1e-20
    r = np.where(ok, 1.0 / np.where(ok, det, 1.0), 0.0)
    ft = (e1 * dv2[:, None] - e2 * dv1[:, None]) * r[:, None]
    fb = (e2 * du1[:, None] - e1 * du2[:, None]) * r[:, None]
    return ft, fb, ok


def closest_on_tris(p, a, b, c):
    """Closest point of each triangle (a, b, c) to each p: its barycentric
    weights and the squared distance. All arrays (..., 3)."""
    ab, ac, ap = b - a, c - a, p - a
    d00 = (ab * ab).sum(-1)
    d01 = (ab * ac).sum(-1)
    d11 = (ac * ac).sum(-1)
    d20 = (ap * ab).sum(-1)
    d21 = (ap * ac).sum(-1)
    den = d00 * d11 - d01 * d01
    den = np.where(np.abs(den) < 1e-30, 1e-30, den)
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    u = 1.0 - v - w
    inside = (u >= 0) & (v >= 0) & (w >= 0)
    best_bc = np.stack([u, v, w], -1)
    q = a + ab * v[..., None] + ac * w[..., None]
    best_d = ((p - q) ** 2).sum(-1)
    best_d = np.where(inside, best_d, np.inf)
    # the three edges, for the ones whose foot falls outside
    for (s, e, i0, i1) in ((a, b, 0, 1), (b, c, 1, 2), (c, a, 2, 0)):
        se = e - s
        t = np.clip(((p - s) * se).sum(-1) / np.maximum((se * se).sum(-1), 1e-30), 0.0, 1.0)
        q = s + se * t[..., None]
        d = ((p - q) ** 2).sum(-1)
        bc = np.zeros(d.shape + (3,))
        bc[..., i0] = 1.0 - t
        bc[..., i1] = t
        take = (~inside) & (d < best_d)
        best_d = np.where(take, d, best_d)
        best_bc = np.where(take[..., None], bc, best_bc)
    return best_bc, best_d


def sample(img, uv):
    """Bilinear, uv as glTF's (0,0 top left); img (h, w, c) float."""
    h, w = img.shape[:2]
    x = np.clip(uv[:, 0] * w - 0.5, 0, w - 1)
    y = np.clip(uv[:, 1] * h - 0.5, 0, h - 1)
    x0 = np.floor(x).astype(np.int64)
    y0 = np.floor(y).astype(np.int64)
    x1 = np.minimum(x0 + 1, w - 1)
    y1 = np.minimum(y0 + 1, h - 1)
    fx = (x - x0)[:, None]
    fy = (y - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x1] * fx * (1 - fy)
            + img[y1, x0] * (1 - fx) * fy + img[y1, x1] * fx * fy)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--tris", type=int, default=30000)
    ap.add_argument("--size", type=int, default=4096)
    ap.add_argument("--keep-main", action="store_true", help="drop pieces that hang apart from the biggest one")
    ap.add_argument("--near", type=int, default=8, help="how many of Tripo's triangles are tried for each texel")
    ap.add_argument("--quality", type=float, default=0.1, help="the decimation's triangle-shape threshold (low keeps thin leaves and twigs)")
    ap.add_argument("--optimal", action="store_true", help="let the decimation move vertices to new places (smoother, but thin things melt)")
    a = ap.parse_args()
    t0 = time.time()
    j, binc = read_glb(a.src)
    prim = j["meshes"][0]["primitives"][0]
    P = accessor(j, binc, prim["attributes"]["POSITION"]).astype(np.float64)
    UV = accessor(j, binc, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    F = accessor(j, binc, prim["indices"]).reshape(-1, 3).astype(np.int64)
    Nh = accessor(j, binc, prim["attributes"]["NORMAL"]).astype(np.float64) if "NORMAL" in prim["attributes"] else vertex_normals(P, F)
    print("in: %d vertices, %d triangles" % (len(P), len(F)))
    if a.keep_main:
        F = keep_main(P, F)
        print("  the main piece: %d triangles" % len(F))
    scale = float((P[np.unique(F)].max(0) - P[np.unique(F)].min(0)).max())

    # Tripo's pictures
    pics = {}
    for im in j["images"]:
        v = j["bufferViews"][im["bufferView"]]
        o = v.get("byteOffset", 0)
        nm = im.get("name", "")
        kind = "normal" if "normal" in nm else ("mr" if "_rm" in nm or "metallic" in nm else "atlas")
        pics[kind] = np.asarray(Image.open(io.BytesIO(binc[o:o + v["byteLength"]])).convert("RGB")).astype(np.float32) / 255.0
    assert "atlas" in pics, "no colour picture"

    # the low mesh and its unwrap
    Pl, Fl = decimate(P, F, a.tris, a.quality, a.optimal)
    Nl = vertex_normals(Pl, Fl)
    print("low mesh: %d vertices, %d triangles (%.0f s)" % (len(Pl), len(Fl), time.time() - t0))
    import xatlas
    atlas = xatlas.Atlas()
    atlas.add_mesh(Pl.astype(np.float32), Fl.astype(np.uint32), Nl.astype(np.float32))
    co = xatlas.ChartOptions()
    po = xatlas.PackOptions()
    po.resolution = a.size
    po.padding = max(2, a.size // 512)
    po.bilinear = True
    po.blockAlign = True
    atlas.generate(co, po)
    vmap, Fx, UVx = atlas[0]
    Px = Pl[vmap]
    Nx = Nl[vmap]
    Fx = Fx.astype(np.int64)
    UVx = UVx.astype(np.float64)
    print("unwrap: %d charts, %d vertices, used %.0f%% of the picture (%.0f s)" % (atlas.chart_count, len(Px), 100.0 * atlas.utilization, time.time() - t0))
    Tx, wx = tangents(Px, Fx, UVx, Nx)
    Bx = unit(np.cross(Nx, Tx) * wx[:, None])

    # which low triangle each texel lies in
    S = a.size
    idmap = Image.new("I", (S, S), 0)
    draw = ImageDraw.Draw(idmap)
    px = UVx * S
    for fi in range(len(Fx)):
        tri = [(float(px[k, 0]), float(px[k, 1])) for k in Fx[fi]]
        draw.polygon(tri, fill=fi + 1, outline=fi + 1)
    ids = np.asarray(idmap)
    ty, tx = np.nonzero(ids)
    fid = (ids[ty, tx] - 1).astype(np.int32)
    ty = ty.astype(np.int32)
    tx = tx.astype(np.int32)
    del ids, idmap, draw
    print("texels to bake: %d of %d (%.0f%%)" % (len(fid), S * S, 100.0 * len(fid) / (S * S)))

    # Tripo's surface: each texel's nearest point on it
    hp0, hp1, hp2 = P[F[:, 0]], P[F[:, 1]], P[F[:, 2]]
    cen = (hp0 + hp1 + hp2) / 3.0
    hfn = unit(np.cross(hp1 - hp0, hp2 - hp0))
    hft, hfb, _ = face_frames(P, F, UV)
    tree = cKDTree(cen)
    n = len(fid)
    out_c = np.zeros((n, 3), np.float32)
    out_m = np.zeros((n, 3), np.float32)
    out_n = np.zeros((n, 3), np.float32)
    dist = np.zeros(n)
    back = 0
    CH = 150000
    for s in range(0, n, CH):
        e = min(n, s + CH)
        # the texels' places in their triangles (barycentric, from each
        # texel's centre), a part at a time: ten million of them at once is
        # more memory than a session here has
        f3 = Fx[fid[s:e]]
        uvc = np.stack([(tx[s:e] + 0.5) / S, (ty[s:e] + 0.5) / S], 1)
        A0 = UVx[f3[:, 0]]
        v0, v1, v2 = UVx[f3[:, 1]] - A0, UVx[f3[:, 2]] - A0, uvc - A0
        den = v0[:, 0] * v1[:, 1] - v1[:, 0] * v0[:, 1]
        den = np.where(np.abs(den) < 1e-18, 1e-18, den)
        b1 = (v2[:, 0] * v1[:, 1] - v1[:, 0] * v2[:, 1]) / den
        b2 = (v0[:, 0] * v2[:, 1] - v2[:, 0] * v0[:, 1]) / den
        bc = np.clip(np.stack([1.0 - b1 - b2, b1, b2], 1), -0.25, 1.25)
        bc /= bc.sum(1, keepdims=True)

        def lerp(arr):
            return arr[f3[:, 0]] * bc[:, :1] + arr[f3[:, 1]] * bc[:, 1:2] + arr[f3[:, 2]] * bc[:, 2:]

        p = lerp(Px)
        Nq, Tq, Bq = unit(lerp(Nx)), unit(lerp(Tx)), unit(lerp(Bx))
        _, near = tree.query(p, k=a.near, workers=-1)
        bcs, d2 = closest_on_tris(p[:, None, :], hp0[near], hp1[near], hp2[near])
        # a triangle facing the other way (the far side of a leaf, the inside
        # of a root) only if nothing facing ours is about as near
        facing = (hfn[near] * Nq[:, None, :]).sum(-1) > 0.0
        d = np.sqrt(d2)
        pick_d = np.where(facing, d, d * 3.0 + scale * 0.004)
        k = np.argmin(pick_d, axis=1)
        row = np.arange(e - s)
        tri = near[row, k]
        hb = bcs[row, k]
        dist[s:e] = d[row, k]
        back += int((~facing[row, k]).sum())
        huv = UV[F[tri, 0]] * hb[:, :1] + UV[F[tri, 1]] * hb[:, 1:2] + UV[F[tri, 2]] * hb[:, 2:]
        out_c[s:e] = sample(pics["atlas"], huv)
        if "mr" in pics:
            out_m[s:e] = sample(pics["mr"], huv)
        # Tripo's normal there: its mesh's, with its normal map on top
        hn = unit(Nh[F[tri, 0]] * hb[:, :1] + Nh[F[tri, 1]] * hb[:, 1:2] + Nh[F[tri, 2]] * hb[:, 2:])
        if "normal" in pics:
            ts = sample(pics["normal"], huv).astype(np.float64) * 2.0 - 1.0
            ht = hft[tri] - hn * (hn * hft[tri]).sum(1, keepdims=True)
            flat = np.linalg.norm(ht, axis=1) < 1e-12
            ht = unit(ht)
            hbv = np.cross(hn, ht) * np.where((np.cross(hn, ht) * hfb[tri]).sum(1) < 0.0, -1.0, 1.0)[:, None]
            wn = unit(ht * ts[:, :1] + hbv * ts[:, 1:2] + hn * ts[:, 2:])
            wn = np.where(flat[:, None], hn, wn)
        else:
            wn = hn
        # a triangle taken from the far side: its normal turned to ours
        wn = np.where(((wn * Nq).sum(1) < 0.0)[:, None] & (~facing[row, k])[:, None], -wn, wn)
        # said in the low mesh's tangent space: x T + y B + z N = wn
        M = np.stack([Tq, Bq, Nq], axis=2)
        det = np.linalg.det(M)
        okm = np.abs(det) > 1e-6
        x = np.zeros_like(wn)
        x[okm] = np.linalg.solve(M[okm], wn[okm][:, :, None])[:, :, 0]
        x[~okm] = [0.0, 0.0, 1.0]
        x[:, 2] = np.maximum(x[:, 2], 0.08)
        out_n[s:e] = unit(x) * 0.5 + 0.5
    print("baked (%.0f s): the new surface is %.2f%% of the model's size from the old on average, %.2f%% at worst; %.1f%% of texels took the far side"
          % (time.time() - t0, 100.0 * dist.mean() / scale, 100.0 * dist.max() / scale, 100.0 * back / max(1, n)))

    # the pictures: every texel outside the charts takes its nearest inside one
    # (no dark edges in the mipmaps)
    covered = np.zeros((S, S), bool)
    covered[ty, tx] = True
    _, (iy, ix) = ndi.distance_transform_edt(~covered, return_indices=True)
    stem = os.path.basename(a.out)[:-4]
    out_dir = os.path.dirname(os.path.abspath(a.out))
    os.makedirs(out_dir, exist_ok=True)
    try:
        from rig_character import write_tex_import
    except Exception:   # (run outside the project: no import settings written)
        write_tex_import = None
    imgs = []
    for kind, data in (("atlas", out_c), ("mr", out_m), ("normal", out_n)):
        if kind != "atlas" and kind not in pics:
            continue
        full = np.zeros((S, S, 3), np.float32)
        full[ty, tx] = data
        full = full[iy, ix]
        img = Image.fromarray(np.clip(full * 255.0 + 0.5, 0, 255).astype(np.uint8), "RGB")
        if kind != "atlas":
            img = img.resize((S // 2, S // 2), Image.LANCZOS)
            if kind == "normal":
                nn = np.asarray(img).astype(np.float32) / 127.5 - 1.0
                img = Image.fromarray(np.clip((unit(nn) * 0.5 + 0.5) * 255.0 + 0.5, 0, 255).astype(np.uint8), "RGB")
        png = "%s_%s.png" % (stem, kind)
        img.save(os.path.join(out_dir, png), "PNG", optimize=True)
        if write_tex_import is not None:
            write_tex_import(os.path.join(out_dir, png), normal=(kind == "normal"))
        imgs.append((kind, png))
        print(" picture", png, img.size, os.path.getsize(os.path.join(out_dir, png)) // 1024, "KB")

    # the GLB
    out_bin = bytearray()
    views = []
    accs = []

    def add(arr, typ, ctype, target, minmax=False):
        while len(out_bin) % 4:
            out_bin.append(0)
        data = arr.tobytes()
        views.append({"buffer": 0, "byteOffset": len(out_bin), "byteLength": len(data), "target": target})
        out_bin.extend(data)
        d = {"bufferView": len(views) - 1, "componentType": ctype, "count": len(arr), "type": typ}
        if minmax:
            d["min"] = arr.min(0).tolist()
            d["max"] = arr.max(0).tolist()
        accs.append(d)
        return len(accs) - 1

    ip = add(Px.astype(np.float32), "VEC3", 5126, 34962, True)
    inn = add(Nx.astype(np.float32), "VEC3", 5126, 34962)
    it = add(np.concatenate([Tx, wx[:, None]], 1).astype(np.float32), "VEC4", 5126, 34962)
    iuv = add(UVx.astype(np.float32), "VEC2", 5126, 34962)
    ii = add(Fx.reshape(-1).astype(np.uint32), "SCALAR", 5125, 34963)
    src_mat = j["materials"][0]
    mat = {"name": stem, "pbrMetallicRoughness": {}}
    for key in ("doubleSided", "alphaMode", "alphaCutoff", "emissiveFactor"):
        if key in src_mat:
            mat[key] = src_mat[key]
    for key in ("baseColorFactor", "metallicFactor", "roughnessFactor"):
        if key in src_mat.get("pbrMetallicRoughness", {}):
            mat["pbrMetallicRoughness"][key] = src_mat["pbrMetallicRoughness"][key]
    images, textures = [], []
    for kind, png in imgs:
        images.append({"name": kind, "uri": png})
        textures.append({"source": len(images) - 1, "sampler": 0})
        if kind == "atlas":
            mat["pbrMetallicRoughness"]["baseColorTexture"] = {"index": len(textures) - 1}
        elif kind == "mr":
            mat["pbrMetallicRoughness"]["metallicRoughnessTexture"] = {"index": len(textures) - 1}
        else:
            mat["normalTexture"] = {"index": len(textures) - 1}
    g = {"asset": {"version": "2.0", "generator": "Tripo, rebaked by tools/rebake_glb.py"},
         "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": stem, "mesh": 0}],
         "meshes": [{"name": stem, "primitives": [{"attributes": {"POSITION": ip, "NORMAL": inn, "TANGENT": it, "TEXCOORD_0": iuv},
                                                    "indices": ii, "material": 0}]}],
         "materials": [mat], "textures": textures, "images": images,
         "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33071}],
         "bufferViews": views, "accessors": accs, "buffers": [{"byteLength": len(out_bin)}]}
    while len(out_bin) % 4:
        out_bin.append(0)
    g["buffers"][0]["byteLength"] = len(out_bin)
    js = json.dumps(g, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    with open(a.out, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(out_bin)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(out_bin), 0x004E4942))
        f.write(out_bin)
    lo, hi = Px.min(0), Px.max(0)
    print("wrote %s: %d KB, %d triangles, size %s (%.0f s)" % (a.out, os.path.getsize(a.out) // 1024, len(Fx), np.round(hi - lo, 3), time.time() - t0))


if __name__ == "__main__":
    main()
