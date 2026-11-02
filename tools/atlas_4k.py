"""Puts a model's colour picture (its atlas) back to the full size Gary's
Tripo3D export came at, 4096, in place of the 2048 copy the rig tools made,
keeping anything painted onto the game's copy since (Bram's open eyes,
mended patches):

  python3 tools/atlas_4k.py <Gary's master .glb> assets/models/characters/bram_atlas.png

The master's base colour (4096) is shrunk to the game atlas's size and
compared with it, pixel by pixel. If the two don't match overall (a
different UV layout, a different texture), nothing is written. Where they
differ in places (a fix painted on), the game atlas, enlarged, is used there,
feathered in, and the master's own 4096 everywhere else. The atlas's import
is set to VRAM compression at high quality (ASTC 4x4 on iPhone, BPTC on Mac):
in memory a 4096 picture that way takes about what a 2048 lossy one did
(a lossy picture is decoded to full RGBA), so the phone holds as many people
at once. (2 November, Gary: "do they need to be smaller or would they be
better bigger in the game?")
"""
import io, json, os, re, struct, sys
import numpy as np
from PIL import Image, ImageFilter

THRESH = 12        # 0-255: a pixel this far from the master's is painted over
MATCH_MEAN = 7.0   # mean difference above which the two aren't the same picture


def base_colour(path):
    b = open(path, "rb").read()
    n = struct.unpack_from("<I", b, 12)[0]
    j = json.loads(b[20:20 + n])
    binc = b[20 + n + 8:]
    mat = j["materials"][0]
    info = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
    if info is None:
        raise SystemExit("%s has no base colour picture" % path)
    im = j["images"][j["textures"][info["index"]]["source"]]
    bv = j["bufferViews"][im["bufferView"]]
    data = binc[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
    return Image.open(io.BytesIO(data))


def set_vram_import(png):
    imp = png + ".import"
    s = open(imp).read()
    s = re.sub(r"(?m)^compress/mode=\d+$", "compress/mode=2", s)
    s = re.sub(r"(?m)^compress/high_quality=\w+$", "compress/high_quality=true", s)
    s = re.sub(r"(?m)^process/size_limit=\d+$", "process/size_limit=0", s)
    s = re.sub(r"(?m)^mipmaps/generate=\w+$", "mipmaps/generate=true", s)
    # (the .ctex Godot made for the lossy import goes stale: re-import)
    s = re.sub(r'(?m)^dest_files=.*$\n?', "", s)
    s = re.sub(r'(?m)^path=.*$\n?', "", s)
    s = re.sub(r'(?m)^path\.\w+=.*$\n?', "", s)
    s = re.sub(r'(?ms)^metadata=\{.*?^\}\n?', "", s)
    s = re.sub(r'(?m)^metadata=.*$\n?', "", s)
    open(imp, "w").write(s)


def main(master, atlas):
    big = base_colour(master)
    cur = Image.open(atlas)
    mode = "RGBA" if (cur.mode == "RGBA" or big.mode == "RGBA") else "RGB"
    big = big.convert(mode)
    cur = cur.convert(mode)
    if big.width <= cur.width:
        print("%s: the master is %d wide, no bigger than the game's %d: left as it is" % (atlas, big.width, cur.width))
        return 1
    small = np.asarray(big.resize(cur.size, Image.LANCZOS)).astype(np.float32)
    c = np.asarray(cur).astype(np.float32)
    d = np.abs(small[..., :3] - c[..., :3]).max(axis=2)
    mean = float(np.abs(small[..., :3] - c[..., :3]).mean())
    if mean > MATCH_MEAN:
        print("%s: not the same picture as %s (mean difference %.1f): left as it is" % (atlas, master, mean))
        return 2
    edited = d > THRESH
    frac = float(edited.mean())
    # the painted part grown a little and feathered at its edge only: inside
    # it the game's own paint is used whole (Bram's eyes kept their colour)
    m = Image.fromarray((edited * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(1.5))
    m = np.asarray(m.resize(big.size, Image.BILINEAR)).astype(np.float32)[..., None] / 255.0
    m = np.clip(m * 2.0, 0.0, 1.0)
    up = np.asarray(cur.resize(big.size, Image.LANCZOS)).astype(np.float32)
    out = np.asarray(big).astype(np.float32) * (1 - m) + up * m
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), mode).save(atlas, "PNG", optimize=True)
    set_vram_import(atlas)
    print("%s: %dx%d from %s (mean difference %.1f; %.2f%% painted on in the game, kept)" % (
        atlas, big.width, big.height, os.path.basename(master), mean, frac * 100))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
