#!/usr/bin/env python3
"""The attic blanket's woven wool (18 November, Gary's yes to "a real wool
picture with fringed ends"): a tile of 2/2 twill, 16 threads each way, the
yarn round and twisted, its fibres fuzzy, each thread a shade of its own.
One RGBA picture that repeats every TILE metres on the cloth
(assets/shaders/village/blanket.gdshader):
  R, G  how the surface slopes across the tile and along it (0.5 flat;
        SLOPE_K of slope per unit), so the light picks out the threads;
  B     how light the wool is there (the dips between threads darker, the
        fuzz lighter).
It's made to repeat: everything in it is periodic over the tile.

  python3 tools/make_wool_texture.py   # writes assets/art/blanket/wool_weave.png
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "art", "blanket", "wool_weave.png")
N = 512           # pixels a side
THREADS = 16      # threads each way across the tile
TILE = 0.05       # m (blanket.gdshader's weave_tile)
SLOPE_K = 8.0     # the picture's slope scale (blanket.gdshader's slope_k)
rng = np.random.default_rng(1171)


def periodic_noise(n, scale):
    """Random noise that repeats over the tile, its grain about `scale` pixels."""
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    k = np.sqrt(fx * fx + fy * fy) * scale
    spec = (rng.normal(size=(n, n)) + 1j * rng.normal(size=(n, n))) * np.exp(-k * k)
    v = np.real(np.fft.ifft2(spec))
    v -= v.mean()
    return v / (np.abs(v).max() + 1e-9)


def main():
    px = N / THREADS
    y, x = np.mgrid[0:N, 0:N].astype(np.float64) + 0.5
    i = np.floor(x / px).astype(int) % THREADS     # which warp thread (runs along y)
    j = np.floor(y / px).astype(int) % THREADS     # which weft thread (runs along x)
    u = (x / px) % 1.0                             # across a warp thread
    v = (y / px) % 1.0                             # across a weft thread
    # 2/2 twill: the warp over two wefts, under two, a step on each thread
    warp_up = ((i + j) % 4) < 2
    # each thread round across its width and dipping where it goes under
    round_warp = np.sin(np.pi * u) ** 0.7
    round_weft = np.sin(np.pi * v) ** 0.7
    # along a float the yarn rises to its middle (it lies over two)
    pos_in_float_w = (((i + j) % 4) + v) / 2.0     # 0..1 along the warp's float of two
    pos_in_float_f = (((i + j + 2) % 4) + u) / 2.0
    lift_w = np.sin(np.pi * np.clip(pos_in_float_w, 0, 1)) ** 0.5
    lift_f = np.sin(np.pi * np.clip(pos_in_float_f, 0, 1)) ** 0.5
    h = np.where(warp_up, round_warp * (0.55 + 0.45 * lift_w), round_weft * (0.55 + 0.45 * lift_f))
    # the yarn's twist: fine slants across each thread
    twist = np.where(warp_up, np.sin(2 * np.pi * (v * 2.0 + u * 0.8) * 2.0), np.sin(2 * np.pi * (u * 2.0 + v * 0.8) * 2.0))
    h = h + 0.08 * twist * h
    # fuzz: fine fibres standing off it
    fuzz = periodic_noise(N, 2.5)
    h = h + 0.12 * fuzz
    # each thread a shade of its own (dyed and spun by hand)
    warp_shade = rng.uniform(-1, 1, THREADS)
    weft_shade = rng.uniform(-1, 1, THREADS)
    shade = np.where(warp_up, warp_shade[i], weft_shade[j])
    # the slope (periodic differences)
    dhdx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5 * N / TILE   # per metre? scaled below
    dhdy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5 * N / TILE
    # heights in metres: a thread stands about a millimetre
    depth = 0.0009
    sx = dhdx * depth
    sy = dhdy * depth
    r = np.clip(0.5 + sx / SLOPE_K, 0, 1)
    g = np.clip(0.5 + sy / SLOPE_K, 0, 1)
    light = 0.72 + 0.26 * np.clip(h, 0, 1) + 0.05 * shade + 0.06 * periodic_noise(N, 6.0)
    b = np.clip(light, 0, 1)
    img = np.stack([r, g, b, np.ones_like(b)], axis=-1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(OUT)
    print("make_wool_texture: %s (slopes %.2f..%.2f, %.2f..%.2f)" % (os.path.relpath(OUT, ROOT), sx.min(), sx.max(), sy.min(), sy.max()))


if __name__ == "__main__":
    main()
