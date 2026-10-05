"""Moves a GLB's embedded colour atlas out to <model>_atlas.png (downscaled to `size`, 2048 by default)
so Godot imports the texture once, next to the model, with our own settings.
Usage: split_glb.py in.glb out_dir [size]"""
import io, json, os, struct, sys
import numpy as np
from PIL import Image

src, out_dir = sys.argv[1], sys.argv[2]
size = int(sys.argv[3]) if len(sys.argv) > 3 else 2048
stem = os.path.basename(src)[:-4]
b = open(src, "rb").read()
magic, ver, length = struct.unpack("<III", b[:12])
assert magic == 0x46546C67
off = 12
chunks = []
while off < length:
    cl, ct = struct.unpack("<II", b[off:off + 8])
    chunks.append([ct, b[off + 8:off + 8 + cl]])
    off += 8 + cl
j = json.loads(chunks[0][1])
binc = chunks[1][1]
views = j["bufferViews"]
datas = [bytes(binc[v["byteOffset"]:v["byteOffset"] + v["byteLength"]]) for v in views]
assert len(j.get("images", [])) == 1, "expected one atlas"
im = j["images"][0]
vi = im["bufferView"]
img = Image.open(io.BytesIO(datas[vi])).convert("RGBA")
if img.width > size:
    a = np.asarray(img).astype(np.float32)
    al = a[..., 3:4] / 255.0
    pre = np.concatenate([a[..., :3] * al, a[..., 3:4]], axis=2)
    pim = Image.fromarray(np.clip(pre, 0, 255).astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS)
    p = np.asarray(pim).astype(np.float32)
    al2 = np.maximum(p[..., 3:4] / 255.0, 1e-4)
    rgb = np.clip(p[..., :3] / al2, 0, 255)
    img = Image.fromarray(np.concatenate([rgb, p[..., 3:4]], axis=2).astype(np.uint8), "RGBA")
png_name = "%s_atlas.png" % stem
img.save(os.path.join(out_dir, png_name), "PNG", optimize=True)
j["images"][0] = {"name": "atlas", "uri": png_name}
# drop the image's buffer view: anything after it shifts down one index
keep = [i for i in range(len(views)) if i != vi]
remap = {old: new for new, old in enumerate(keep)}
def fix(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "bufferView" and isinstance(v, int):
                o[k] = remap[v]
            else:
                fix(v)
    elif isinstance(o, list):
        for v in o:
            fix(v)
fix(j["accessors"])
fix(j.get("images", []))
for acc in j["accessors"]:
    if "sparse" in acc:
        fix(acc["sparse"])
j["bufferViews"] = [views[i] for i in keep]
datas = [datas[i] for i in keep]
newbin = bytearray()
for i, v in enumerate(j["bufferViews"]):
    while len(newbin) % 4:
        newbin.append(0)
    v["byteOffset"] = len(newbin)
    v["byteLength"] = len(datas[i])
    newbin += datas[i]
while len(newbin) % 4:
    newbin.append(0)
j["buffers"][0]["byteLength"] = len(newbin)
js = json.dumps(j, separators=(",", ":")).encode()
while len(js) % 4:
    js += b" "
total = 12 + 8 + len(js) + 8 + len(newbin)
with open(os.path.join(out_dir, stem + ".glb"), "wb") as f:
    f.write(struct.pack("<III", magic, ver, total))
    f.write(struct.pack("<II", len(js), 0x4E4F534A))
    f.write(js)
    f.write(struct.pack("<II", len(newbin), 0x004E4942))
    f.write(newbin)
print(stem, len(b) // 1024, "KB -> glb", total // 1024, "KB + png", os.path.getsize(os.path.join(out_dir, png_name)) // 1024, "KB")
