"""Gives one of Gary's prop or building models a normal map and a roughness
map made from its own colour atlas.

Gary's Tripo3D props (the inn, the cottages, the well, the stall, the carts,
the oaks, the walls...) come with one painted colour atlas and a flat
roughness: his atlases are swatches of material (plaster, thatch, planks,
stone, bark, iron), so the fine shape is all in the paint. This reads that
shape back out of it: the small light-and-dark of the paint (wood grain, the
mortar between stones, the bark's ridges, the weave of a sack) is taken as
height, with the broad painted shading taken off first so a swatch painted
darker at one end doesn't come out as a slope. Two pictures are written
beside the model:

  <id>_normal.png  the normal map (OpenGL way up, as Godot reads them)
  <id>_mr.png      G: how much rougher or smoother than the material's own
                   roughness each spot is (0.75 to 1, multiplied by it; the
                   raised grain a touch glossier than the cracks), B: how
                   metal it is (only with --metal: the dark, grey iron of a
                   barrel's hoops or a cart's tyres; else 0)

with import settings (VRAM-compressed, so a 2048 normal map costs 4 MB on
the Mac and about as much on the iPhone; the normal map as a normal map).
LevelKit.dress_models() puts them on the model's materials when it loads.

    python3 tools/derive_maps.py assets/models/ashford/<id>.glb [--metal] [--size 1024] [--strength 1.0]

Only for swatch atlases: a character's atlas (thousands of small islands on
black) would come out with a seam round every island; a character's normal
map comes from the maker's own file (tools/add_normal_map.py).
"""
import argparse, io, json, os, struct, sys

import numpy as np
from PIL import Image
from scipy import ndimage

IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://{res}"

[params]

compress/mode=2
compress/high_quality=false
compress/lossy_quality=0.9
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map={normal}
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


## Paint whose light and dark varies less than about this (in the 0 to 1 of
## its brightness) comes out shallower than the rest (5 November: 0.02 left
## the inn's whitewash a little lumpy on Forward+).
SPREAD_FLOOR = 0.03


def base_colour(glb):
    """The model's colour atlas: the file it names, or the picture inside it."""
    d = open(glb, "rb").read()
    ln = struct.unpack_from("<I", d, 12)[0]
    j = json.loads(d[20:20 + ln])
    off = 20 + ln
    bl = struct.unpack_from("<I", d, off)[0]
    b = d[off + 8:off + 8 + bl]
    for m in j.get("materials", []):
        t = m.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if t is None:
            continue
        im = j["images"][j["textures"][t["index"]]["source"]]
        if "uri" in im:
            return Image.open(os.path.join(os.path.dirname(glb), im["uri"]))
        v = j["bufferViews"][im["bufferView"]]
        o = v.get("byteOffset", 0)
        return Image.open(io.BytesIO(b[o:o + v["byteLength"]]))
    sys.exit("%s has no colour texture" % glb)


def write_import(png, normal):
    root = os.path.abspath(png)
    proj = root
    while proj != "/" and not os.path.exists(os.path.join(proj, "project.godot")):
        proj = os.path.dirname(proj)
    res = os.path.relpath(root, proj)
    imp = png + ".import"
    keep = ""
    if os.path.exists(imp):
        # keep the uid Godot gave it, so nothing that names it breaks
        for line in open(imp):
            if line.startswith("uid="):
                keep = line
    text = IMPORT.format(res=res, normal=1 if normal else 0)
    if keep:
        text = text.replace('type="CompressedTexture2D"\n', 'type="CompressedTexture2D"\n' + keep, 1)
    open(imp, "w").write(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("--size", type=int, default=0, help="output size (default: half the atlas, 1024 to 2048)")
    ap.add_argument("--strength", type=float, default=1.0)
    ap.add_argument("--metal", action="store_true", help="the dark grey swatches are iron")
    a = ap.parse_args()

    src = base_colour(a.model)
    size = a.size or max(1024, min(2048, src.width // 2))
    rgba = np.asarray(src.convert("RGBA").resize((size, size), Image.LANCZOS), dtype=np.float32) / 255.0
    rgb = rgba[..., :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)

    # the paint's small detail, as height: the broad shading taken off, and
    # its strength evened out (a pale swatch and a dark one come out about
    # as deep: the whitewash's faint painted blocks show as whitewashed
    # stone), except that paint with very little in it stays a little
    # shallower (SPREAD_FLOOR); then a hair of smoothing against noise
    broad = ndimage.gaussian_filter(lum, size / 96.0, mode="wrap")
    detail = lum - broad
    spread = np.sqrt(ndimage.gaussian_filter(detail * detail, size / 48.0, mode="wrap")) + SPREAD_FLOOR
    h = np.tanh(detail / (spread * 2.5))
    h = ndimage.gaussian_filter(h, 0.7, mode="wrap")

    # slopes (per pixel at 1024, so the look doesn't change with the size)
    k = size / 1024.0
    gx = ndimage.sobel(h, axis=1, mode="wrap") / 8.0 * k
    gy = ndimage.sobel(h, axis=0, mode="wrap") / 8.0 * k
    s = 2.2 * a.strength
    gx, gy = gx * s, gy * s
    # a hard edge (where two swatches meet, the edge of a painted board)
    # mustn't stand up as a wall: steep slopes are eased off
    g = np.sqrt(gx * gx + gy * gy)
    soft = 1.0 / (1.0 + g / 0.9)
    gx, gy = gx * soft, gy * soft
    # OpenGL's way up (Godot's): x against the slope along the row, y with
    # the slope down the rows (the picture's rows run down, its v up)
    n = np.stack([-gx, gy, np.ones_like(gx)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    out = model_stem = a.model[:-4]
    nimg = ((n * 0.5 + 0.5) * 255.0 + 0.5).clip(0, 255).astype(np.uint8)
    Image.fromarray(nimg, "RGB").save(out + "_normal.png", optimize=True)
    write_import(out + "_normal.png", True)

    # roughness: the raised grain a touch glossier than the cracks
    rough = np.clip(0.9 - 0.12 * h, 0.75, 1.0)
    metal = np.zeros_like(rough)
    if a.metal:
        mx = rgb.max(axis=-1)
        mn = rgb.min(axis=-1)
        sat = (mx - mn) / np.maximum(mx, 1e-3)
        iron = ((sat < 0.22) & (mx < 0.36) & (mx > 0.03)).astype(np.float32)
        # whole swatches, not specks: an iron spot keeps its neighbours
        iron = ndimage.gaussian_filter(iron, size / 256.0, mode="wrap")
        iron = np.clip((iron - 0.5) * 4.0 + 0.5, 0.0, 1.0)
        metal = iron * 0.8
        rough = rough * (1.0 - iron) + np.clip(0.62 - 0.1 * h, 0.45, 0.8) * iron
    mr_size = max(256, size // 2)
    mr = np.stack([np.ones_like(rough), rough, metal], axis=-1)
    mimg = Image.fromarray((mr * 255.0 + 0.5).clip(0, 255).astype(np.uint8), "RGB").resize((mr_size, mr_size), Image.LANCZOS)
    mimg.save(out + "_mr.png", optimize=True)
    write_import(out + "_mr.png", False)
    print("%s: normal %d, mr %d%s (from %dx%d)" % (os.path.basename(model_stem), size, mr_size,
        ", iron %.0f%%" % (metal.mean() / 0.8 * 100.0) if a.metal else "", src.width, src.height))


if __name__ == "__main__":
    main()
