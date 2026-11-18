#!/usr/bin/env python3
"""Rules tests/face_sheet.gd's stills in centimetres from the Head bone, for
reading off where a model's lips are (Figure3D.MOUTHS).

  python3 tools/face_grid.py <dir of stills> <out.jpg> model [model ...]

Each model: its face square on (left: x across, y up) and from its side
(right: z out of the face runs to the left, y up). A still is 34 cm top to
bottom, its middle 8 cm over the bone (and, from the side, 10 cm ahead of
it). Lines every centimetre, heavier and numbered every two.
"""
import sys
from PIL import Image, ImageDraw

SPAN, MID_UP, MID_AHEAD = 0.34, 0.08, 0.10
S = 1080   # each view drawn this many pixels square


def view(path, side):
    im = Image.open(path).convert("RGB").resize((S, S), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    ppm = S / SPAN
    for cm in range(-8, 26):
        y = S / 2 - (cm / 100.0 - MID_UP) * ppm
        if 0 <= y < S:
            heavy = cm % 2 == 0
            d.line([(0, y), (S, y)], fill=(255, 255, 0) if cm == 0 else ((255, 255, 255) if heavy else (150, 150, 150)), width=1)
            if heavy:
                d.text((S * 0.24 + 2, y - 11), str(cm), fill=(255, 255, 0))
    for cm in range(-12, 30):
        if side:
            x = S / 2 - (cm / 100.0 - MID_AHEAD) * ppm
        else:
            x = S / 2 + (cm / 100.0) * ppm
        if 0 <= x < S and cm % 2 == 0:
            d.line([(x, 0), (x, S)], fill=(255, 255, 0) if cm == 0 else (200, 200, 200), width=1)
            d.text((x + 2, S * 0.63), str(cm), fill=(0, 255, 255))
    return im


def low(im, side):
    """The lower face only, twice the size: 18 cm of it, from 6 cm under the
    bone to 12 over; across, 9 cm either side (from the side: 4 to 22 cm
    ahead of the bone)."""
    ppm = S / SPAN
    top = S / 2 - (0.12 - MID_UP) * ppm
    bot = S / 2 - (-0.06 - MID_UP) * ppm
    if side:
        left = S / 2 - (0.22 - MID_AHEAD) * ppm
        right = S / 2 - (0.04 - MID_AHEAD) * ppm
    else:
        left = S / 2 - 0.09 * ppm
        right = S / 2 + 0.09 * ppm
    return im.crop((int(left), int(top), int(right), int(bot))).resize((L, L), Image.LANCZOS)


L = 360


def main():
    args = sys.argv[1:]
    lower = "--low" in args
    kind = "shut"
    for a in list(args):
        if a.startswith("--kind="):
            kind = a[7:]
    args = [a for a in args if not a.startswith("--")]
    src, out, names = args[0], args[1], args[2:]
    cols = 3 if lower else 2
    w = L if lower else S
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w * 2, rows * w), (0, 0, 0))
    for k, nm in enumerate(names):
        x0 = (k % cols) * w * 2
        y0 = (k // cols) * w
        a = view(f"{src}/{nm}_{kind}_front.png", False)
        b = view(f"{src}/{nm}_{kind}_side.png", True)
        if lower:
            a, b = low(a, False), low(b, True)
        sheet.paste(a, (x0, y0))
        sheet.paste(b, (x0 + w, y0))
        ImageDraw.Draw(sheet).text((x0 + 40, y0 + 4), nm, fill=(255, 80, 80))
    sheet.save(out, quality=90)


main()
