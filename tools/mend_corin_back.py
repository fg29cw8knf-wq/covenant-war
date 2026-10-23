"""Corin's back (23 October, Gary: "a hole in the back of him"): a patch of
triangles at his left shoulder blade whose texture coordinates point at the
shirt and the skin on the atlas, so the vest looked torn through. Seen from
behind (an orthographic raster of the back, triangle by triangle, coloured
from the atlas), the triangles in that patch that don't sample the vest's
leather are mapped onto it. Run on the exported model after rig_villager.sh:
    python3 tools/mend_corin_back.py assets/models/characters/corin.glb
"""
import json, struct, sys
import numpy as np
from PIL import Image, ImageDraw

f = sys.argv[1]
atlas = f[:-4] + "_atlas.png"
d = open(f, "rb").read()
ln = struct.unpack_from("<I", d, 12)[0]
j = json.loads(d[20:20 + ln])
off = 20 + ln
bl = struct.unpack_from("<I", d, off)[0]
b = bytearray(d[off + 8:off + 8 + bl])


def span(i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    o = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    ct = {5126: ("<f4", 4), 5123: ("<u2", 2), 5125: ("<u4", 4), 5121: ("<u1", 1)}[a["componentType"]]
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    return o, a["count"], n, ct[0], ct[1]


p = j["meshes"][0]["primitives"][0]
o, c, n, dt, sz = span(p["attributes"]["POSITION"])
P = np.frombuffer(bytes(b[o:o + c * n * sz]), dtype=dt).reshape(c, n).astype(np.float64)
ou, cu, nu, dtu, szu = span(p["attributes"]["TEXCOORD_0"])
UV = np.frombuffer(bytes(b[ou:ou + cu * nu * szu]), dtype=dtu).reshape(cu, nu).astype(np.float64)
oi, ci, ni, dti, szi = span(p["indices"])
I = np.frombuffer(bytes(b[oi:oi + ci * szi]), dtype=dti).reshape(-1, 3).astype(np.int64)
im = Image.open(atlas).convert("RGB")
W, H = im.size
A = np.asarray(im)
# the back from behind: x 0.3 .. -0.3 across the picture, y 1.75 .. 1.15 down
S = 1200
x0, x1, y0, y1 = -0.3, 0.3, 1.15, 1.75
ids = Image.new("I", (int((x1 - x0) * S), int((y1 - y0) * S)), -1)
di = ImageDraw.Draw(ids)
fn = np.cross(P[I[:, 1]] - P[I[:, 0]], P[I[:, 2]] - P[I[:, 0]])
cz = P[I].mean(1)[:, 2]
for t in np.argsort(-cz):
    if fn[t, 2] > 0:
        continue
    pts = P[I[t]]
    if pts[:, 1].max() < y0 or pts[:, 1].min() > y1 or pts[:, 0].max() < x0 or pts[:, 0].min() > x1:
        continue
    di.polygon([((x1 - x) * S, (y1 - y) * S) for x, y, z in pts], fill=int(t))
# the patch: 7 cm wide, over his left shoulder blade
box = np.asarray(ids)[430:550, 240:350]
seen = np.unique(box)
seen = seen[seen >= 0]
vest = np.array([0.095, 0.939])   # a spot of the vest's leather on the atlas
vc = A[int(vest[1] * H) % H, int(vest[0] * W) % W].astype(float)
total = 0
for thresh in [45, 30]:
    corner = np.array([A[int(v * H) % H, int(u * W) % W] for u, v in UV[I[seen]].reshape(-1, 2)]).reshape(-1, 3, 3).astype(float)
    odd = seen[(np.linalg.norm(corner - vc, axis=2) > thresh).any(1)]
    hv = np.unique(I[odd])
    UV[hv] = vest
    total += len(odd)
# and what's left that's darker than the leather (a last sliver of shadowed shirt)
corner = np.array([A[int(v * H) % H, int(u * W) % W] for u, v in UV[I[seen]].reshape(-1, 2)]).reshape(-1, 3, 3).astype(float)
dark = seen[(corner.mean(2) < vc.mean() - 22).any(1)]
UV[np.unique(I[dark])] = vest
total += len(dark)
b[ou:ou + cu * nu * szu] = UV.astype(dtu).tobytes()
open(f, "wb").write(bytes(bytearray(d[:off + 8]) + b))
print("%s: %d triangles of the back mapped onto the vest" % (f, total))
