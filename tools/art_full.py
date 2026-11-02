"""Puts Gary's painted art back in at the size he painted it (2 November, Gary:
"can we make the scenery and assets 4k?"): the game's copies were cut down
(cards to 640, gods to 512, the arenas to 2560, the Summons' scenes to 1920)
when phones were thought to need it. Each picture in a game folder is matched
to its original in one of Gary's folders by what it shows (the two shrunk to a
thumbnail and compared), so his file names needn't match the game's ids:

  python3 tools/art_full.py assets/art/cards "<Covenant Art>/cards" [--dry]

A match must be close (mean difference under MATCH on 0-255) and clearly
better than the next best; anything without one is left as it is and listed.
The original is cropped to the game picture's shape if it differs a little,
saved under the game's own file name and format (a .jpg at quality 95, a
.webp losslessly, keeping its transparency), and its import set to VRAM
compression at high quality (ASTC 4x4 on iPhone, BPTC on Mac), so on the
phone a 1536 card takes about the memory the 640 one did.
"""
import argparse, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from atlas_4k import set_vram_import  # noqa: E402

MATCH = 14.0
EXTS = (".png", ".jpg", ".jpeg", ".webp")


def flat(img):
    """RGB over mid-grey (a cut-out's transparency shown as grey)."""
    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGBA")
        bg = Image.new("RGBA", img.size, (128, 128, 128, 255))
        bg.alpha_composite(img)
        return bg.convert("RGB")
    return img.convert("RGB")


def crop_to(img, aspect):
    w, h = img.size
    if abs(w / h - aspect) < 0.01:
        return img
    if w / h > aspect:
        nw = int(round(h * aspect))
        x = (w - nw) // 2
        return img.crop((x, 0, x + nw, h))
    nh = int(round(w / aspect))
    y = (h - nh) // 2
    return img.crop((0, y, w, y + nh))


def thumb(img, aspect):
    return np.asarray(flat(crop_to(img, aspect)).resize((40, 40), Image.BILINEAR)).astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("game_dir")
    ap.add_argument("orig_dir")
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--only", default="", help="only game files with this ending (e.g. _scene.jpg: the Summons' cut-outs have\n                    their transparency made in the game, so they stay)")
    a = ap.parse_args()
    origs = [os.path.join(a.orig_dir, f) for f in sorted(os.listdir(a.orig_dir)) if f.lower().endswith(EXTS)]
    oimg = {p: Image.open(p) for p in origs}
    done, left = 0, []
    for f in sorted(os.listdir(a.game_dir)):
        if not f.lower().endswith(EXTS) or (a.only and not f.endswith(a.only)):
            continue
        gp = os.path.join(a.game_dir, f)
        g = Image.open(gp)
        aspect = g.width / g.height
        gt = thumb(g, aspect)
        scores = sorted((float(np.abs(thumb(oimg[p], aspect) - gt).mean()), p) for p in origs)
        best, bp = scores[0]
        second = scores[1][0] if len(scores) > 1 else 999.0
        o = oimg[bp]
        if best > MATCH or best > 0.7 * second:
            left.append("%s (closest %s, %.1f)" % (f, os.path.basename(bp), best))
            continue
        if o.width <= g.width:
            left.append("%s (%s is no bigger)" % (f, os.path.basename(bp)))
            continue
        out = crop_to(o, aspect)
        print("%-28s <- %-28s %4dx%-4d -> %4dx%-4d (difference %.1f)" % (
            f, os.path.basename(bp), g.width, g.height, out.width, out.height, best))
        if a.dry:
            continue
        ext = os.path.splitext(f)[1].lower()
        if ext in (".jpg", ".jpeg"):
            flat(out).save(gp, "JPEG", quality=95, subsampling=0)
        elif ext == ".webp":
            out.convert("RGBA").save(gp, "WEBP", lossless=True, method=4)
        else:
            out.save(gp, "PNG", optimize=True)
        if os.path.exists(gp + ".import"):
            set_vram_import(gp)
        done += 1
    print("%d at full size; left as they were: %d" % (done, len(left)))
    for l in left:
        print("  " + l)


if __name__ == "__main__":
    main()
