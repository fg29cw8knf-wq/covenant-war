"""Gives a creature that's already in the game (split by split_creature.py,
its colour picture beside it) a glow map, <id>_glow.png, as its emission,
the way split_creature.py --glow does when a model first comes in
(12 November, Gary: yes to the glow on Bram's god's other creatures, after
the Glyph Warden's). DuelField3D.FLARE then breathes it at rest and blazes
it up as it strikes.

  python3 tools/add_glow.py assets/models/creatures/<id>.glb <mode> [<mode>...] [--factor k]

--factor k: how bright it shines at rest (the material's emissiveFactor;
1 = as painted); FLARE adds to it on a strike.

modes (any of them together; a pixel takes the brightest):
  ink            blue and violet accents (the Scrivener's quill and its ink)
  gold           gold flecks and trim
  light:<pct>    the brightest <pct>% of the creature, in its own colours
                 (threads catching the light, sand sparkling in the glass)
"""
import json, os, struct, sys
import numpy as np
from PIL import Image

path = sys.argv[1]
modes = [m for m in sys.argv[2:] if not m.startswith("--") and not m.replace(".", "").isdigit()]
factor = float(sys.argv[sys.argv.index("--factor") + 1]) if "--factor" in sys.argv else 1.0
stem = os.path.basename(path)[:-4]
out_dir = os.path.dirname(path)

data = open(path, "rb").read()
magic, ver, length = struct.unpack("<III", data[:12])
clen, ctype = struct.unpack("<II", data[12:20])
j = json.loads(data[20:20 + clen])
rest = data[20 + clen:]

atlas_uri = j["images"][0]["uri"]
img = Image.open(os.path.join(out_dir, atlas_uri)).convert("RGBA").resize((1024, 1024), Image.LANCZOS)
a = np.asarray(img).astype(np.float32) / 255.0
rgb, alpha = a[..., :3], a[..., 3]
hsv = np.asarray(img.convert("RGB").convert("HSV")).astype(np.float32) / 255.0
hue, sat, val = hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]
# the painted parts only (the atlas's empty space is black)
painted = (val > 0.06) & (alpha > 0.5)
ramp = lambda x, lo, hi: np.clip((x - lo) / (hi - lo), 0, 1)

em = np.zeros_like(rgb)
for mode in modes:
    if mode == "ink":
        k = ramp(sat, 0.25, 0.45) * ramp(val, 0.3, 0.5) * ((hue > 190) & (hue < 285))
        lift = np.clip(0.95 / np.maximum(val, 1e-3), 1.0, 2.5)
        em = np.maximum(em, rgb * (k * lift)[..., None])
    elif mode == "gold":
        k = ramp(sat, 0.3, 0.45) * ramp(val, 0.5, 0.7) * ((hue > 20) & (hue < 60))
        em = np.maximum(em, rgb * k[..., None])
    elif mode.startswith("light:"):
        pct = float(mode.split(":")[1])
        cut = np.percentile(val[painted], 100.0 - pct)
        k = ramp(val, cut - 0.04, cut + 0.06) * painted
        em = np.maximum(em, rgb * k[..., None])
    else:
        sys.exit("unknown mode " + mode)
em_img = Image.fromarray(np.clip(em * 255, 0, 255).astype(np.uint8), "RGB")
glow_name = "%s_glow.png" % stem
em_img.save(os.path.join(out_dir, glow_name), "PNG", optimize=True)
print("%s: %.1f%% of the creature shines" % (stem, 100.0 * float((em.max(axis=2) > 0.15).sum()) / max(1, int(painted.sum()))))

# the glow map as the material's emission (replacing any it had)
imgs = [im for im in j["images"] if im.get("uri") != glow_name]
j["images"] = imgs + [{"name": "glow", "uri": glow_name}]
gi = len(j["images"]) - 1
texs = [t for t in j["textures"] if t.get("source", -1) < len(imgs)]
j["textures"] = texs + [{"sampler": 0, "source": gi}]
ti = len(j["textures"]) - 1
for mat in j["materials"]:
    mat["emissiveTexture"] = {"index": ti}
    mat["emissiveFactor"] = [factor, factor, factor]

js = json.dumps(j, separators=(",", ":")).encode()
while len(js) % 4:
    js += b" "
out = struct.pack("<III", magic, ver, 12 + 8 + len(js) + len(rest)) + struct.pack("<II", len(js), ctype) + js + rest
open(path, "wb").write(out)
print("wrote", path, "and", glow_name)
