#!/usr/bin/env python3
"""Generate the original, deterministic RGBA8 texture fixtures (stdlib only)."""
import math
from pathlib import Path
import struct
import zlib

WIDTH, HEIGHT = 640, 400
OUT = Path(__file__).resolve().parent.parent / "assets"

def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

def png(path, pixels):
    rows = b"".join(b"\0" + pixels[y * WIDTH * 4:(y + 1) * WIDTH * 4] for y in range(HEIGHT))
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b"")
    path.write_bytes(payload)

def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))

def smooth(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)

def grid(x, y):
    u, v = (x + 0.5) / WIDTH, (y + 0.5) / HEIGHT
    color = mix((26, 175, 182), (156, 64, 207), u)
    color = tuple(c * (1 - 0.36 * v) for c in color)
    line = min(x % 40, 39 - x % 40, y % 40, 39 - y % 40)
    color = mix((12, 21, 37), color, smooth(0, 2, line))
    radius = math.hypot(x + 0.5 - 320, y + 0.5 - 200)
    ring = 1 - smooth(2.0, 3.5, abs(radius - 115))
    color = mix(color, (242, 241, 226), ring)
    # Asymmetric corner markers reveal accidental Y flips.
    for cx, cy, tint in [(61, 61, (255, 163, 75)), (579, 339, (239, 79, 132))]:
        disk = 1 - smooth(18, 19, math.hypot(x + 0.5 - cx, y + 0.5 - cy))
        color = mix(color, tint, disk)
    return color

def stripes(x, y):
    u, v = (x + 0.5) / WIDTH, (y + 0.5) / HEIGHT
    phase = (u * 4.0 + v * 1.9) % 1.0
    band = smooth(0.10, 0.22, phase) * (1 - smooth(0.66, 0.78, phase))
    color = mix((38, 27, 82), (255, 108, 93), band)
    highlight = (1 - smooth(0.025, 0.055, abs(phase - 0.84))) * 0.8
    return mix(color, (255, 216, 130), highlight)

if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for name, effect in [("grid.png", grid), ("stripes.png", stripes)]:
        data = bytearray()
        for y in range(HEIGHT):
            for x in range(WIDTH):
                data.extend(int(min(255, max(0, round(c)))) for c in effect(x, y))
                data.append(255)
        png(OUT / name, bytes(data))
        print(OUT / name)
