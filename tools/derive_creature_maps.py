"""Gives a Totem's or a Summon's model a normal map made from its own colour
atlas, one island at a time (18 November, the duel's look pass).

Gary's creature models (Tripo3D) came with a colour atlas and nothing else:
no normal map, no roughness map, so every Totem in the duel was drawn as
smooth as a painted toy, its fur, scales, bark and plates flat to the light.
tools/derive_maps.py reads the fine shape back out of the paint for the
village's props, but a creature's atlas is hundreds of small islands on
black, and filtered as one picture every island came out with a ridge round
its edge (the black beyond it read as a cliff). Here the islands are found
from the model's own UVs, the paint's small detail is taken as height inside
each island only (the black beyond each edge never enters it: the island's
own paint is carried outwards first), and the normal map is then carried
out past every edge too, so its mipmaps don't bleed black into the seams.

  <id>_normal.png  the normal map (OpenGL way up, as Godot reads them),
                   beside the model, with its import settings

DuelField3D._dress_model() puts it on the model's materials as it loads
(not on its eyes, mouths or tongues, nor on fire or mist), at
DuelField3D.SKIN_NORMAL.

    python3 tools/derive_creature_maps.py assets/models/creatures/<id>.glb [--size 1024] [--strength 1.0]
    python3 tools/derive_creature_maps.py --all            # every creature and Summon that hasn't one
    python3 tools/derive_creature_maps.py --all --force    # ...and the ones that have
"""
import argparse, glob, io, json, os, struct, sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from derive_maps import SPREAD_FLOOR, write_import  # noqa: E402

COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    d = open(path, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    return j, d[off + 8:off + 8 + bl]


def accessor(j, b, i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    dt = np.dtype(COMP[a["componentType"]])
    n = NCOMP[a["type"]]
    start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = v.get("byteStride", 0) or dt.itemsize * n
    raw = np.frombuffer(b, dtype=np.uint8, count=stride * (a["count"] - 1) + dt.itemsize * n, offset=start)
    out = np.lib.stride_tricks.as_strided(raw, shape=(a["count"], dt.itemsize * n), strides=(stride, 1)).copy()
    out = out.view(dt).reshape(a["count"], n)
    if a.get("normalized"):
        out = out.astype(np.float32) / float(np.iinfo(dt).max)
    return out


def colour_texture(j):
    """The index of the texture the materials take their colour from."""
    for m in j.get("materials", []):
        t = m.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if t is not None:
            return t["index"], t.get("texCoord", 0)
    return None, 0


def colour_image(path, j, b, tex):
    im = j["images"][j["textures"][tex]["source"]]
    if "uri" in im:
        return Image.open(os.path.join(os.path.dirname(path), im["uri"]))
    v = j["bufferViews"][im["bufferView"]]
    o = v.get("byteOffset", 0)
    return Image.open(io.BytesIO(b[o:o + v["byteLength"]]))


def island_mask(j, b, tex, size):
    """Where the model's triangles lie in its atlas (those that use the
    colour atlas), at `size`, as a bool picture."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    users = set()
    for mi, m in enumerate(j.get("materials", [])):
        t = m.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if t is not None and t["index"] == tex:
            users.add(mi)
    tris = 0
    for mesh in j.get("meshes", []):
        for p in mesh.get("primitives", []):
            if p.get("material") not in users or "TEXCOORD_0" not in p.get("attributes", {}):
                continue
            uv = accessor(j, b, p["attributes"]["TEXCOORD_0"]).astype(np.float64)
            if "indices" in p:
                idx = accessor(j, b, p["indices"]).reshape(-1)
            else:
                idx = np.arange(len(uv))
            idx = idx[: len(idx) // 3 * 3].reshape(-1, 3)
            # (wrapped into the atlas: a UV past 1 is the same spot repeated)
            px = (uv - np.floor(uv)) * size
            for a, c, e in idx:
                draw.polygon([tuple(px[a]), tuple(px[c]), tuple(px[e])], fill=255)
            tris += len(idx)
    return np.asarray(mask) > 0, tris


def carry_out(a, inside):
    """`a` with every pixel outside `inside` given the value of the nearest
    one inside it."""
    if inside.all() or not inside.any():
        return a
    _, (iy, ix) = ndimage.distance_transform_edt(~inside, return_indices=True)
    return a[iy, ix]


def masked_blur(a, inside, sigma):
    """A gaussian blur of `a` that only ever averages pixels inside the
    islands (each pixel's blur weighed by how much of it was inside)."""
    w = inside.astype(np.float32)
    num = ndimage.gaussian_filter(a * w, sigma, mode="wrap")
    den = ndimage.gaussian_filter(w, sigma, mode="wrap")
    out = num / np.maximum(den, 1e-4)
    return np.where(den > 1e-3, out, a)


def derive(path, size=0, strength=1.0):
    j, b = read_glb(path)
    tex, uvset = colour_texture(j)
    if tex is None:
        print("%s: no colour texture, skipped" % os.path.basename(path))
        return False
    src = colour_image(path, j, b, tex)
    size = size or max(1024, min(2048, src.width // 2))
    mask, tris = island_mask(j, b, tex, size)
    # one pixel's grace round each island (the edge of a triangle drawn a
    # hair short)
    mask = ndimage.binary_dilation(mask, iterations=1)
    rgb = np.asarray(src.convert("RGB").resize((size, size), Image.LANCZOS), dtype=np.float32) / 255.0
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    lum = carry_out(lum, mask)

    # the paint's small detail as height (as derive_maps.py: the broad
    # painted shading off, the strength evened out, quiet paint shallower),
    # every blur kept inside the islands
    k = size / 1024.0
    broad = masked_blur(lum, mask, 10.7 * k)
    detail = np.where(mask, lum - broad, 0.0)
    spread = np.sqrt(masked_blur(detail * detail, mask, 21.3 * k)) + SPREAD_FLOOR
    h = np.tanh(detail / (spread * 2.5))
    h = masked_blur(h, mask, 0.7 * k)
    h = carry_out(h, mask)   # (so a slope at an island's edge sees only its own paint)

    gx = ndimage.sobel(h, axis=1, mode="wrap") / 8.0 * k
    gy = ndimage.sobel(h, axis=0, mode="wrap") / 8.0 * k
    s = 2.2 * strength
    gx, gy = gx * s, gy * s
    g = np.sqrt(gx * gx + gy * gy)
    soft = 1.0 / (1.0 + g / 0.9)
    gx, gy = gx * soft, gy * soft
    n = np.stack([-gx, gy, np.ones_like(gx)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    # flat outside the islands, then each island's own carried outwards
    n[~mask] = (0.0, 0.0, 1.0)
    n = np.stack([carry_out(n[..., c], mask) for c in range(3)], axis=-1)
    out = path[:-4] + "_normal.png"
    nimg = ((n * 0.5 + 0.5) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)
    Image.fromarray(nimg, "RGB").save(out, optimize=True)
    write_import(out, True)
    print("%s: normal %d from %dx%d, %d triangles, islands cover %.0f%%%s" % (os.path.basename(path)[:-4], size,
        src.width, src.height, tris, mask.mean() * 100.0, "" if uvset == 0 else " (colour on UV set %d: drawn from set 0)" % uvset))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("models", nargs="*")
    ap.add_argument("--all", action="store_true", help="every creature and Summon model")
    ap.add_argument("--force", action="store_true", help="with --all: remake the ones that have one")
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--strength", type=float, default=1.0)
    a = ap.parse_args()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    models = list(a.models)
    if a.all:
        for sub in ("creatures", "summons"):
            for p in sorted(glob.glob(os.path.join(root, "assets/models", sub, "*.glb"))):
                if a.force or not os.path.exists(p[:-4] + "_normal.png"):
                    models.append(p)
    if not models:
        ap.error("name a model, or --all")
    for p in models:
        derive(p, a.size, a.strength)


if __name__ == "__main__":
    main()
