"""Draws assets/art/fx/glyph_ring.png: the ring of glyphs that lies on the
ground under a Totem whose markings glow (DuelField3D.FLARE; 12 November,
Gary: yes to a ring under the Glyph Warden, so its glow shows from behind
too, where its markings don't). Its marks are the Warden's own: pointed
violet diamonds edged in gold, the arches of its inlays between them, two
thin gold circles, all softened into a glow. Drawn additively, so black is
nothing and colour is light.

  python3 tools/make_glyph_ring.py [out.png]
"""
import math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

out = sys.argv[1] if len(sys.argv) > 1 else "assets/art/fx/glyph_ring.png"
N = 1024
S = 4  # drawn at 4x, then shrunk, for clean edges
W = N * S
c = W / 2
VIOLET = (150, 105, 255)
GOLD = (255, 205, 120)

img = Image.new("RGB", (W, W), (0, 0, 0))
d = ImageDraw.Draw(img)


def circle(r, width, col):
    d.ellipse([c - r, c - r, c + r, c + r], outline=col, width=width)


def polar(r, a):
    return (c + r * math.cos(a), c + r * math.sin(a))


R_OUT, R_IN = 0.455 * W, 0.335 * W
R_MID = (R_OUT + R_IN) / 2
circle(R_OUT, int(0.006 * W), GOLD)
circle(R_IN, int(0.005 * W), GOLD)
circle(R_OUT - 0.018 * W, int(0.002 * W), VIOLET)
circle(R_IN + 0.018 * W, int(0.002 * W), VIOLET)

K = 12
for i in range(K):
    a = 2 * math.pi * i / K
    # a tall pointed diamond across the band, violet with a gold edge
    t = (math.cos(a + math.pi / 2), math.sin(a + math.pi / 2))
    h_out, h_in, half = R_MID + 0.05 * W, R_MID - 0.05 * W, 0.018 * W
    pts = [polar(h_out, a), (c + R_MID * math.cos(a) + t[0] * half, c + R_MID * math.sin(a) + t[1] * half),
           polar(h_in, a), (c + R_MID * math.cos(a) - t[0] * half, c + R_MID * math.sin(a) - t[1] * half)]
    d.polygon(pts, fill=VIOLET, outline=GOLD, width=int(0.003 * W))
    # its gold heart
    hh = 0.007 * W
    hp = [polar(R_MID + hh * 1.6, a), (c + R_MID * math.cos(a) + t[0] * hh, c + R_MID * math.sin(a) + t[1] * hh),
          polar(R_MID - hh * 1.6, a), (c + R_MID * math.cos(a) - t[0] * hh, c + R_MID * math.sin(a) - t[1] * hh)]
    d.polygon(hp, fill=GOLD)
    # the inlay's arches between this diamond and the next: two pointed arcs
    a0, a1 = a + 0.06, a + 2 * math.pi / K - 0.06
    for r, col, w in ((R_MID + 0.022 * W, VIOLET, int(0.004 * W)), (R_MID - 0.022 * W, GOLD, int(0.0025 * W))):
        steps = 40
        pts = []
        for k in range(steps + 1):
            u = k / steps
            aa = a0 + (a1 - a0) * u
            # a pointed arch: the radius swells to the middle and meets in a point
            rr = r + (0.016 * W) * (1 - abs(2 * u - 1)) ** 0.6 * (1 if col == VIOLET else -1)
            pts.append(polar(rr, aa))
        d.line(pts, fill=col, width=w, joint="curve")

img = img.resize((N, N), Image.LANCZOS)
glow = img.filter(ImageFilter.GaussianBlur(10))
arr = np.clip(np.asarray(img, np.float32) * 0.8 + np.asarray(glow, np.float32) * 0.9, 0, 255)
# alpha from brightness, so the material's own alpha scales all of it
alpha = np.clip(arr.max(axis=2) * 1.2, 0, 255)
rgba = np.dstack([arr, alpha]).astype(np.uint8)
Image.fromarray(rgba, "RGBA").save(out, optimize=True)
print("wrote", out)
