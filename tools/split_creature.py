"""Readies a Tripo3D creature (one material, a 4K base colour with a roughness-
metal map and a normal map embedded) for assets/models/creatures/: the base
colour goes out beside it as <id>_atlas.png (2048, imported once with our
settings like the other creatures'), the roughness-metal and normal maps are
dropped (a phone doesn't need them), and with --glow the fire-coloured parts
of the atlas (bright orange, red and yellow: a Cinderpup's flames) become an
emission map, <id>_glow.png, so they shine through the duel's bloom the way
the first creature packs' flame surfaces do.

  python3 tools/split_creature.py <in.glb> assets/models/creatures/<id>.glb [--glow]
"""
import io, json, os, struct, sys
import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
glow = "--glow" in sys.argv
size = 2048
stem = os.path.basename(dst)[:-4]
out_dir = os.path.dirname(dst)
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
assert len(j["materials"]) == 1, "expected one material"
mat = j["materials"][0]
pbr = mat.get("pbrMetallicRoughness", {})
assert "baseColorTexture" in pbr, "no base colour texture"
img_i = j["textures"][pbr["baseColorTexture"]["index"]]["source"]
im = j["images"][img_i]
img = Image.open(io.BytesIO(datas[im["bufferView"]])).convert("RGB")
if img.width > size:
    img = img.resize((size, size), Image.LANCZOS)
atlas = "%s_atlas.png" % stem
img.save(os.path.join(out_dir, atlas), "PNG", optimize=True)
images = [{"name": "atlas", "uri": atlas}]
textures = [{"sampler": 0, "source": 0}]
pbr["baseColorTexture"] = {"index": 0}
# --tone 0.75: the colour held back (a saturated orange coat flares to flat
# red under the duel's warm lights and bloom)
tone = 1.0
for i, a in enumerate(sys.argv):
    if a == "--tone":
        tone = float(sys.argv[i + 1])
if tone != 1.0:
    pbr["baseColorFactor"] = [tone, tone, tone, 1.0]
pbr.pop("metallicRoughnessTexture", None)
pbr["metallicFactor"] = 0.0
pbr["roughnessFactor"] = 0.9
mat.pop("normalTexture", None)
mat.pop("occlusionTexture", None)
if glow:
    a = np.asarray(img.resize((1024, 1024), Image.LANCZOS)).astype(np.float32) / 255.0
    r, g, bl = a[..., 0], a[..., 1], a[..., 2]
    bright = np.maximum(r, np.maximum(g, bl))
    sat = bright - np.minimum(r, np.minimum(g, bl))
    # fire: red leading, blue well below, bright, saturated and yellow enough
    # (the Cinderpup's orange fur is darker and redder than its flames and
    # the lava cracks in it, which are what should shine)
    k = (np.clip((r - bl - 0.25) / 0.35, 0, 1) * np.clip((bright - 0.7) / 0.2, 0, 1)
         * np.clip((sat - 0.3) / 0.3, 0, 1) * np.clip((g - 0.4) / 0.15, 0, 1))
    k = k[..., None]
    em = (a * k * 255).astype(np.uint8)
    glow_name = "%s_glow.png" % stem
    Image.fromarray(em, "RGB").save(os.path.join(out_dir, glow_name), "PNG", optimize=True)
    images.append({"name": "glow", "uri": glow_name})
    textures.append({"sampler": 0, "source": 1})
    mat["emissiveTexture"] = {"index": 1}
    mat["emissiveFactor"] = [1.0, 1.0, 1.0]
    print("glow: %.1f%% of the atlas shines" % (100.0 * float((k > 0.2).mean())))
mat["name"] = stem
j["images"] = images
j["textures"] = textures
j.setdefault("samplers", [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}])
j["samplers"] = j["samplers"][:1]
# drop every image's buffer view; renumber the rest
img_views = {v for v in [im.get("bufferView") for im in json.loads(chunks[0][1])["images"]] if v is not None}
keep = [i for i in range(len(views)) if i not in img_views]
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
with open(dst, "wb") as f:
    f.write(struct.pack("<III", magic, ver, total))
    f.write(struct.pack("<II", len(js), 0x4E4F534A))
    f.write(js)
    f.write(struct.pack("<II", len(newbin), 0x004E4942))
    f.write(newbin)
print(stem, len(b) // 1024, "KB -> glb", total // 1024, "KB + atlas", os.path.getsize(os.path.join(out_dir, atlas)) // 1024, "KB")
