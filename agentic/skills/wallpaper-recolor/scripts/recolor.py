#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["numpy", "pillow", "scipy"]
# ///

import argparse

import numpy as np
from PIL import Image
from scipy.ndimage import map_coordinates

N = 64

M1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
               [0.2119034982, 0.6806995451, 0.1073969566],
               [0.0883024619, 0.2817188376, 0.6299787005]])
M2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
               [1.9779984951, -2.4285922050, 0.4505937099],
               [0.0259040371, 0.7827717662, -0.8086757660]])


def to_oklab(rgb):
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    return np.cbrt(lin @ M1.T) @ M2.T


def from_oklab(lab):
    lin = np.clip(((lab @ np.linalg.inv(M2).T) ** 3) @ np.linalg.inv(M1).T, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)


def hex_lab(colors):
    return to_oklab(np.array([[int(h.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)] for h in colors]))


p = argparse.ArgumentParser()
p.add_argument("src")
p.add_argument("dst")
p.add_argument("palette", nargs="+")
p.add_argument("--sigma", type=float, default=0.04)
p.add_argument("--lum-keep", type=float, default=0.6)
p.add_argument("--gamma", type=float, default=1.0)
p.add_argument("--tint")
p.add_argument("--tint-amount", type=float, default=0.02)
a = p.parse_args()

pal = hex_lab(a.palette)
axis = np.linspace(0, 1, N)
lab = to_oklab(np.stack(np.meshgrid(axis, axis, axis, indexing="ij"), -1).reshape(-1, 3))

w = np.exp(-((lab[:, None] - pal) ** 2).sum(-1) / (2 * a.sigma**2))
out = (w / w.sum(1, keepdims=True)) @ pal
out[:, 0] = (a.lum_keep * lab[:, 0] + (1 - a.lum_keep) * out[:, 0]) ** a.gamma
if a.tint:
    ab = hex_lab([a.tint])[0, 1:]
    cool = (1 - np.hypot(out[:, 1], out[:, 2]) / 0.12).clip(0, 1)
    out[:, 1:] += a.tint_amount * cool[:, None] * ab / np.hypot(*ab)
lut = from_oklab(out).reshape(N, N, N, 3)

img = np.asarray(Image.open(a.src).convert("RGB")) / 255 * (N - 1)
res = np.stack([map_coordinates(lut[..., c], img.transpose(2, 0, 1), order=1) for c in range(3)], -1)
Image.fromarray((res * 255).round().astype(np.uint8)).save(a.dst)
