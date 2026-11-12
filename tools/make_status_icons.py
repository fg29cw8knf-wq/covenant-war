"""Draws the little signs that hang over a Totem while an effect lasts
(DuelStatusMarks; 12 November, Gary: "every effect shows on the person
affected somehow"), white on clear, softened into a glow, to be tinted in the
game: assets/art/fx/status/<name>.png, 256 square.

  heart    Charmed: a heart
  zed      Asleep: a Z
  question Confused: a question mark
  target   Marked: a target, four ticks round a ring and a dot
  eye      Doomed: an eye, half shut
  hex      Hexed: a crooked sigil, three hooked arms out of a ring

and the badges (DuelStatusMarks._badge): the round back each sign sits on
over the Totem's head, and a sign for every effect without one of its own:

  badge    the back: a dark disc in a bright rim (tinted in the game)
  flame    Burn          venom    Poison (a drop, two bubbles)
  drips    Corroded      claws    Bleed (three slashes)
  flake    Frozen        bolt     Shocked
  drop     Soaked        sprout   Rooted
  rock     Petrified     swirl    Staggered
  eye_shut Blinded       bang     Terrified
  vein     Enraged       skull    Cursed
  down     Drained       shield   Shielded
  up       Empowered     plus     Regenerating
  mist     Veiled        fast     Hastened
  hush     Silenced (a speech bubble, struck through)
  star     Stunned       halo     Blessed
  strings  Possessed (a puppet's cross and strings)
  (and Asleep, Confused and Charmed take zed, question and heart)
  pip      a turn left: the dots under a badge

  python3 tools/make_status_icons.py
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = "assets/art/fx/status"
N, S = 256, 4
W = N * S


def canvas():
    img = Image.new("L", (W, W), 0)
    return img, ImageDraw.Draw(img)


def finish(img, name):
    img = img.resize((N, N), Image.LANCZOS)
    glow = img.filter(ImageFilter.GaussianBlur(9))
    a = np.clip(np.asarray(img, np.float32) + np.asarray(glow, np.float32) * 0.8, 0, 255).astype(np.uint8)
    rgba = np.dstack([np.full_like(a, 255)] * 3 + [a])
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name)


def heart():
    img, d = canvas()
    pts = []
    for i in range(200):
        t = 2 * math.pi * i / 200
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((W / 2 + x * W / 40, W / 2 - y * W / 40 - W * 0.03))
    d.polygon(pts, fill=255)
    finish(img, "heart")


def zed():
    img, d = canvas()
    w = W * 0.11
    a, b = W * 0.24, W * 0.76
    d.line([(a, a), (b, a)], fill=255, width=int(w))
    d.line([(b, a), (a, b)], fill=255, width=int(w))
    d.line([(a, b), (b, b)], fill=255, width=int(w))
    finish(img, "zed")


def question():
    # in the game's own rounded face (Lilita One), so it reads as a question mark
    from PIL import ImageFont
    img, d = canvas()
    f = ImageFont.truetype("assets/fonts/LilitaOne-Regular.ttf", int(W * 0.78))
    bb = d.textbbox((0, 0), "?", font=f)
    d.text(((W - (bb[2] - bb[0])) / 2 - bb[0], (W - (bb[3] - bb[1])) / 2 - bb[1]), "?", font=f, fill=255)
    finish(img, "question")


def target():
    img, d = canvas()
    c = W / 2
    r = W * 0.3
    w = int(W * 0.045)
    d.ellipse([c - r, c - r, c + r, c + r], outline=255, width=w)
    r2 = W * 0.16
    d.ellipse([c - r2, c - r2, c + r2, c + r2], outline=255, width=int(w * 0.7))
    for k in range(4):
        a = k * math.pi / 2
        d.line([(c + math.cos(a) * (r - W * 0.05), c + math.sin(a) * (r - W * 0.05)),
                (c + math.cos(a) * (r + W * 0.13), c + math.sin(a) * (r + W * 0.13))], fill=255, width=w)
    rd = W * 0.045
    d.ellipse([c - rd, c - rd, c + rd, c + rd], fill=255)
    finish(img, "target")


def eye():
    img, d = canvas()
    c = W / 2
    w = int(W * 0.045)
    # the lids: two arcs meeting at the corners, the top one coming down
    d.arc([W * 0.12, c - W * 0.2, W * 0.88, c + W * 0.28], 200, 340, fill=255, width=w)
    d.arc([W * 0.12, c - W * 0.34, W * 0.88, c + W * 0.2], 20, 160, fill=255, width=w)
    r = W * 0.1
    d.ellipse([c - r, c - r * 0.6, c + r, c + r * 1.2], fill=255)
    # lashes under, three
    for k in (-1, 0, 1):
        x = c + k * W * 0.16
        d.line([(x, c + W * 0.2), (x + k * W * 0.03, c + W * 0.3)], fill=255, width=int(w * 0.8))
    finish(img, "eye")


def hexsign():
    # a crooked sigil (the Hex Mark's card: "a crooked violet sigil ... chains
    # of tiny runes"): three hooked arms turning out of a ring, a dot between each
    img, d = canvas()
    c = W / 2
    w = int(W * 0.045)
    r0 = W * 0.13
    d.ellipse([c - r0, c - r0, c + r0, c + r0], outline=255, width=w)
    for k in range(3):
        a = -math.pi / 2 + k * 2 * math.pi / 3
        pts = []
        for i in range(30):
            u = i / 29
            rr = r0 + u * W * 0.25
            aa = a + u * 0.9
            pts.append((c + rr * math.cos(aa), c + rr * math.sin(aa)))
        d.line(pts, fill=255, width=w, joint="curve")
        # the hook at its end, turned back
        ex, ey = pts[-1]
        hb = a + 0.9 + 2.2
        d.line([(ex, ey), (ex + W * 0.08 * math.cos(hb), ey + W * 0.08 * math.sin(hb))], fill=255, width=w)
        da = a + math.pi / 3 + 0.35
        dr = W * 0.3
        rd = W * 0.028
        d.ellipse([c + dr * math.cos(da) - rd, c + dr * math.sin(da) - rd, c + dr * math.cos(da) + rd, c + dr * math.sin(da) + rd], fill=255)
    finish(img, "hex")


def finish_badge(img, name):
    img = img.resize((N, N), Image.LANCZOS)
    rgba = np.asarray(img, np.float32)
    Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name)


def badge():
    # the back: a dark disc (so the sign reads on the bright floors) in a rim
    # of light; the game tints it the effect's colour
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = W / 2
    r = W * 0.47
    d.ellipse([c - r, c - r, c + r, c + r], fill=(255, 255, 255, 255))
    r2 = W * 0.41
    d.ellipse([c - r2, c - r2, c + r2, c + r2], fill=(40, 40, 40, 215))
    finish_badge(img, "badge")


def poly(d, pts, c=W / 2, s=1.0):
    d.polygon([(c + x * W * s, c + y * W * s) for x, y in pts], fill=255)


def flame():
    # a tongue of fire, tip up and leaning, a smaller one licking up beside it
    # and a hollow at its heart
    img, d = canvas()

    def tongue(cx, cy, r, lean, tall):
        pts = []
        for i in range(120):
            t = i / 119 * 2 * math.pi
            x, y = math.cos(t), math.sin(t)
            if y < 0:
                k = -y
                x *= (1 - k) ** 1.3
                y *= tall
                x += lean * k ** 2
            pts.append((cx + x * r, cy + y * r))
        return pts

    d.polygon(tongue(W * 0.52, W * 0.62, W * 0.24, 0.35, 2.3), fill=255)
    d.polygon(tongue(W * 0.33, W * 0.7, W * 0.13, -0.5, 2.0), fill=255)
    d.polygon(tongue(W * 0.54, W * 0.68, W * 0.1, 0.2, 1.8), fill=0)
    finish(img, "flame")


def drop_pts(cx, cy, r):
    pts = []
    for i in range(100):
        t = i / 99 * 2 * math.pi
        x = math.cos(t)
        y = math.sin(t)
        if y < 0:
            # the top drawn up to a point
            x *= (1 + y) ** 1.2
            y *= 1.7
        pts.append((cx + x * r, cy + y * r))
    return pts


def venom():
    img, d = canvas()
    d.polygon(drop_pts(W * 0.45, W * 0.58, W * 0.22), fill=255)
    for (x, y, r) in ((0.74, 0.3, 0.07), (0.8, 0.52, 0.045)):
        w = int(W * 0.03)
        d.ellipse([W * (x - r), W * (y - r), W * (x + r), W * (y + r)], outline=255, width=w)
    finish(img, "venom")


def drop():
    img, d = canvas()
    d.polygon(drop_pts(W * 0.5, W * 0.58, W * 0.26), fill=255)
    # its shine
    d.arc([W * 0.33, W * 0.44, W * 0.6, W * 0.72], 110, 190, fill=0, width=int(W * 0.04))
    finish(img, "drop")


def drips():
    img, d = canvas()
    w = W * 0.62
    d.rounded_rectangle([W * 0.19, W * 0.2, W * 0.81, W * 0.34], radius=W * 0.06, fill=255)
    for (x, l) in ((0.3, 0.36), (0.5, 0.5), (0.7, 0.28)):
        d.rectangle([W * (x - 0.045), W * 0.3, W * (x + 0.045), W * (0.3 + l)], fill=255)
        d.ellipse([W * (x - 0.07), W * (0.3 + l - 0.07), W * (x + 0.07), W * (0.3 + l + 0.07)], fill=255)
    finish(img, "drips")


def claws():
    img, d = canvas()
    for k in (-1, 0, 1):
        pts = []
        for i in range(40):
            u = i / 39
            x = 0.32 + u * 0.38 + k * 0.15
            y = 0.2 + u * 0.6 + 0.05 * math.sin(u * math.pi)
            pts.append((x, y))
        # thick in the middle, fine at both ends
        for i in range(len(pts) - 1):
            u = i / (len(pts) - 1)
            w = int(W * (0.015 + 0.06 * math.sin(u * math.pi)))
            d.line([(pts[i][0] * W, pts[i][1] * W), (pts[i + 1][0] * W, pts[i + 1][1] * W)], fill=255, width=max(1, w))
    finish(img, "claws")


def flake():
    img, d = canvas()
    c = W / 2
    w = int(W * 0.05)
    for k in range(3):
        a = k * math.pi / 3
        dx, dy = math.cos(a) * W * 0.36, math.sin(a) * W * 0.36
        d.line([(c - dx, c - dy), (c + dx, c + dy)], fill=255, width=w)
        for sgn in (-1, 1):
            for f in (0.55,):
                bx, by = c + sgn * dx * f, c + sgn * dy * f
                for t in (-1, 1):
                    b = a + t * math.pi / 4 + (0 if sgn > 0 else math.pi)
                    d.line([(bx, by), (bx + math.cos(b) * W * 0.13, by + math.sin(b) * W * 0.13)], fill=255, width=int(w * 0.8))
    finish(img, "flake")


def bolt():
    img, d = canvas()
    poly(d, [(0.06, -0.38), (-0.2, 0.04), (-0.02, 0.04), (-0.1, 0.38), (0.2, -0.08), (0.02, -0.08), (0.12, -0.38)])
    finish(img, "bolt")


def sprout():
    img, d = canvas()
    c = W / 2
    w = int(W * 0.045)
    d.line([(c, W * 0.62), (c, W * 0.32)], fill=255, width=w)
    # two leaves
    d.chord([W * 0.22, W * 0.2, W * 0.52, W * 0.42], 0, 360, fill=255)
    d.chord([W * 0.48, W * 0.12, W * 0.8, W * 0.34], 0, 360, fill=255)
    # the roots, gripping
    for k in (-1, 0, 1):
        pts = []
        for i in range(20):
            u = i / 19
            pts.append((c + k * u * W * 0.25 + k * W * 0.05 * math.sin(u * 3), W * 0.62 + u * W * 0.22))
        d.line(pts, fill=255, width=int(w * (0.9 if k == 0 else 0.75)), joint="curve")
    d.line([(W * 0.16, W * 0.62), (W * 0.84, W * 0.62)], fill=255, width=int(w * 0.6))
    finish(img, "sprout")


def rock():
    img, d = canvas()
    poly(d, [(-0.34, 0.22), (-0.3, -0.05), (-0.14, -0.26), (0.12, -0.3), (0.3, -0.1), (0.36, 0.2), (0.2, 0.3), (-0.2, 0.3)])
    c = W / 2
    w = int(W * 0.04)
    d.line([(c - W * 0.05, c - W * 0.28), (c + W * 0.02, c - W * 0.08), (c - W * 0.08, c + W * 0.06), (c + W * 0.04, c + W * 0.2)], fill=0, width=w, joint="curve")
    d.line([(c + W * 0.02, c - W * 0.08), (c + W * 0.2, c - W * 0.02)], fill=0, width=int(w * 0.8))
    finish(img, "rock")


def swirl():
    img, d = canvas()
    c = W / 2
    pts = []
    for i in range(200):
        u = i / 199
        a = u * 2.6 * 2 * math.pi
        r = W * (0.03 + 0.33 * u)
        pts.append((c + r * math.cos(a), c + r * math.sin(a)))
    d.line(pts, fill=255, width=int(W * 0.055), joint="curve")
    finish(img, "swirl")


def eye_shut():
    img, d = canvas()
    c = W / 2
    w = int(W * 0.05)
    d.arc([W * 0.12, c - W * 0.3, W * 0.88, c + W * 0.3], 20, 160, fill=255, width=w)
    d.arc([W * 0.12, c - W * 0.3, W * 0.88, c + W * 0.3], 200, 340, fill=255, width=w)
    r = W * 0.1
    d.ellipse([c - r, c - r, c + r, c + r], fill=255)
    # struck through
    d.line([(W * 0.2, W * 0.8), (W * 0.8, W * 0.2)], fill=0, width=int(w * 2.6))
    d.line([(W * 0.2, W * 0.8), (W * 0.8, W * 0.2)], fill=255, width=w)
    finish(img, "eye_shut")


def bang():
    from PIL import ImageFont
    img, d = canvas()
    f = ImageFont.truetype("assets/fonts/LilitaOne-Regular.ttf", int(W * 0.72))
    bb = d.textbbox((0, 0), "!", font=f)
    d.text(((W - (bb[2] - bb[0])) / 2 - bb[0], (W - (bb[3] - bb[1])) / 2 - bb[1]), "!", font=f, fill=255)
    # the shiver marks either side
    w = int(W * 0.035)
    for sgn in (-1, 1):
        for k in range(2):
            x = W / 2 + sgn * W * (0.2 + k * 0.08)
            d.line([(x, W * 0.36), (x + sgn * W * 0.02, W * 0.64)], fill=255, width=w)
    finish(img, "bang")


def vein():
    # the four bent strokes of an angry vein, back to back round a cross
    img, d = canvas()
    c = W / 2
    w = int(W * 0.065)
    g = W * 0.06
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx, cy = c + sx * (g + W * 0.16), c + sy * (g + W * 0.16)
            r = W * 0.16
            # an arc bulging away from the middle
            start = {(1, 1): 180, (-1, 1): 270, (-1, -1): 0, (1, -1): 90}[(sx, sy)]
            d.arc([cx - r, cy - r, cx + r, cy + r], start, start + 90, fill=255, width=w)
    finish(img, "vein")


def skull():
    img, d = canvas()
    c = W / 2
    d.ellipse([W * 0.2, W * 0.16, W * 0.8, W * 0.68], fill=255)
    d.rounded_rectangle([W * 0.33, W * 0.55, W * 0.67, W * 0.82], radius=W * 0.05, fill=255)
    for sx in (-1, 1):
        r = W * 0.085
        x = c + sx * W * 0.13
        d.ellipse([x - r, W * 0.43 - r, x + r, W * 0.43 + r], fill=0)
    poly(d, [(0, 0.06), (-0.04, 0.13), (0.04, 0.13)])
    d.polygon([(c, W * 0.56), (c - W * 0.04, W * 0.63), (c + W * 0.04, W * 0.63)], fill=0)
    for k in (-1, 0, 1):
        x = c + k * W * 0.08
        d.line([(x, W * 0.7), (x, W * 0.82)], fill=0, width=int(W * 0.025))
    finish(img, "skull")


def chevrons(name, up):
    img, d = canvas()
    c = W / 2
    w = int(W * 0.08)
    for k in (0, 1):
        y = c + (k - 0.5) * W * 0.24 * (1 if up else -1) + (W * 0.08 if up else -W * 0.08)
        tip = y - W * 0.14 if up else y + W * 0.14
        d.line([(c - W * 0.24, y), (c, tip), (c + W * 0.24, y)], fill=255, width=w, joint="curve")
    finish(img, name)


def shield():
    img, d = canvas()
    pts = []
    for i in range(60):
        u = i / 59
        # the side running down from the shoulder to the point
        pts.append((0.3 * math.cos(u * math.pi / 2) ** 0.7, -0.24 + u * 0.6))
    outline = [(-0.3, -0.3), (0, -0.36), (0.3, -0.3)] + pts + [(-x, y) for x, y in reversed(pts)]
    poly(d, outline)
    c = W / 2
    inner = [(c + x * W * 0.62, c + (y + 0.03) * W * 0.62) for x, y in outline]
    d.polygon(inner, fill=0)
    d.line([(c, c - W * 0.18), (c, c + W * 0.22)], fill=255, width=int(W * 0.05))
    d.line([(c - W * 0.15, c - W * 0.02), (c + W * 0.15, c - W * 0.02)], fill=255, width=int(W * 0.05))
    finish(img, "shield")


def plus():
    img, d = canvas()
    c = W / 2
    a, b = W * 0.1, W * 0.32
    d.rounded_rectangle([c - a, c - b, c + a, c + b], radius=W * 0.04, fill=255)
    d.rounded_rectangle([c - b, c - a, c + b, c + a], radius=W * 0.04, fill=255)
    finish(img, "plus")


def mist():
    img, d = canvas()
    w = int(W * 0.055)
    for k, (x0, x1) in enumerate(((0.18, 0.7), (0.3, 0.84), (0.16, 0.66))):
        y = W * (0.32 + k * 0.18)
        pts = []
        for i in range(60):
            u = i / 59
            x = W * (x0 + (x1 - x0) * u)
            pts.append((x, y + W * 0.035 * math.sin(u * 2 * math.pi * 1.5 + k)))
        d.line(pts, fill=255, width=w, joint="curve")
    finish(img, "mist")


def fast():
    img, d = canvas()
    w = int(W * 0.075)
    c = W / 2
    for k in (0, 1):
        x = W * (0.36 + k * 0.2)
        d.line([(x - W * 0.12, c - W * 0.2), (x + W * 0.06, c), (x - W * 0.12, c + W * 0.2)], fill=255, width=w, joint="curve")
    for k, y in enumerate((-0.12, 0.0, 0.12)):
        d.line([(W * 0.08, c + y * W), (W * (0.2 - abs(y)), c + y * W)], fill=255, width=int(w * 0.5))
    finish(img, "fast")


def hush():
    img, d = canvas()
    w = int(W * 0.05)
    d.rounded_rectangle([W * 0.16, W * 0.2, W * 0.84, W * 0.66], radius=W * 0.14, outline=255, width=w)
    d.polygon([(W * 0.32, W * 0.6), (W * 0.28, W * 0.82), (W * 0.48, W * 0.62)], fill=255)
    for k in (-1, 0, 1):
        x = W / 2 + k * W * 0.16
        d.ellipse([x - W * 0.045, W * 0.43 - W * 0.045, x + W * 0.045, W * 0.43 + W * 0.045], fill=255)
    d.line([(W * 0.14, W * 0.86), (W * 0.86, W * 0.14)], fill=0, width=int(w * 2.6))
    d.line([(W * 0.14, W * 0.86), (W * 0.86, W * 0.14)], fill=255, width=w)
    finish(img, "hush")


def star():
    img, d = canvas()
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 0.36 if i % 2 == 0 else 0.15
        pts.append((r * math.cos(a), r * math.sin(a) + 0.02))
    poly(d, pts)
    finish(img, "star")


def halo():
    img, d = canvas()
    w = int(W * 0.06)
    d.ellipse([W * 0.14, W * 0.3, W * 0.86, W * 0.62], outline=255, width=w)
    # a glint on it
    poly(d, [(0.22, -0.2), (0.25, -0.12), (0.33, -0.09), (0.25, -0.06), (0.22, 0.02), (0.19, -0.06), (0.11, -0.09), (0.19, -0.12)])
    finish(img, "halo")


def strings():
    img, d = canvas()
    w = int(W * 0.05)
    c = W / 2
    # the cross the puppeteer holds
    d.line([(W * 0.22, W * 0.24), (W * 0.78, W * 0.24)], fill=255, width=w)
    d.line([(c, W * 0.14), (c, W * 0.36)], fill=255, width=w)
    # three strings down to three little hands
    for k, x in enumerate((0.26, 0.5, 0.74)):
        d.line([(W * x, W * 0.26), (W * (x + (0.5 - x) * 0.25), W * 0.74)], fill=255, width=int(w * 0.45))
        xx = W * (x + (0.5 - x) * 0.25)
        r = W * 0.06
        d.ellipse([xx - r, W * 0.74 - r, xx + r, W * 0.74 + r], fill=255)
    finish(img, "strings")


def pip():
    img, d = canvas()
    r = W * 0.3
    d.ellipse([W / 2 - r, W / 2 - r, W / 2 + r, W / 2 + r], fill=255)
    finish(img, "pip")


os.makedirs(OUT, exist_ok=True)
heart(); zed(); question(); target(); eye(); hexsign()
badge(); flame(); venom(); drips(); claws(); flake(); bolt(); drop(); sprout(); rock(); swirl()
eye_shut(); bang(); vein(); skull(); chevrons("down", False); shield(); chevrons("up", True); plus(); mist(); fast(); hush()
star(); halo(); strings(); pip()
