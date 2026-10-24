#!/usr/bin/env python3
"""Draws the crew job icons (Olivier, 2026-10-24: "hard to understand what the other AI are doing").

White glyphs with a dark outline, so they read on top of any player colour: helm wheel, shovel
(engine), hammer (carpenter), spyglass (lookout), cannon (gunner), pump (water drop), crate
(cargo), fish (fishing), and a plain disc for the badge behind them. Pure Python (no image
libraries): each shape is a signed distance function, sampled 3x3 per pixel for smooth edges.

    python3 tools/make_icons.py   ->  assets/art/export/ui/icons/*.png
"""
import math
import os
import struct
import zlib

SIZE = 128
OUTLINE = 7.0  # pixels of dark rim around each glyph
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "art", "export", "ui", "icons")


def circle(cx, cy, r):
    return lambda x, y: math.hypot(x - cx, y - cy) - r


def ring(cx, cy, r, width):
    return lambda x, y: abs(math.hypot(x - cx, y - cy) - r) - width / 2


def segment(ax, ay, bx, by, width):
    def sdf(x, y):
        px, py, dx, dy = x - ax, y - ay, bx - ax, by - ay
        t = max(0.0, min(1.0, (px * dx + py * dy) / (dx * dx + dy * dy)))
        return math.hypot(px - dx * t, py - dy * t) - width / 2
    return sdf


def box(cx, cy, hw, hh, angle=0.0, round_=0.0):
    c, s = math.cos(angle), math.sin(angle)

    def sdf(x, y):
        lx = (x - cx) * c + (y - cy) * s
        ly = -(x - cx) * s + (y - cy) * c
        qx, qy = abs(lx) - hw + round_, abs(ly) - hh + round_
        return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - round_
    return sdf


def polygon(points):
    def sdf(x, y):
        d = float("inf")
        inside = False
        n = len(points)
        for i in range(n):
            ax, ay = points[i]
            bx, by = points[(i + 1) % n]
            d = min(d, segment(ax, ay, bx, by, 0)(x, y))
            if (ay > y) != (by > y) and x < (bx - ax) * (y - ay) / (by - ay) + ax:
                inside = not inside
        return -d if inside else d
    return sdf


def union(*shapes):
    return lambda x, y: min(s(x, y) for s in shapes)


def subtract(a, b):
    return lambda x, y: max(a(x, y), -b(x, y))


ICONS = {
    "disc": circle(64, 64, 56),
    "helm": union(ring(64, 64, 30, 12), circle(64, 64, 10),
                  *[segment(64 + 14 * math.cos(a), 64 + 14 * math.sin(a), 64 + 50 * math.cos(a), 64 + 50 * math.sin(a), 9)
                    for a in [i * math.pi / 4 for i in range(8)]]),
    "engine": union(segment(30, 30, 72, 72, 10), segment(22, 36, 36, 22, 9),  # shovel: handle, grip
                    polygon([(62, 70), (86, 56), (104, 84), (96, 104), (76, 100)])),
    "carpenter": union(segment(34, 100, 74, 50, 12), box(76, 46, 30, 12, 0.67, 3)),  # hammer
    "navigator": union(segment(26, 92, 58, 64, 14), segment(56, 66, 82, 44, 19), segment(80, 46, 102, 28, 24)),  # spyglass
    "gunner": union(box(62, 56, 40, 14, -0.3, 2), box(99, 45, 5, 18, -0.3, 1), ring(50, 86, 15, 8), circle(50, 86, 5)),  # cannon
    "pump": union(polygon([(64, 18), (92, 68), (36, 68)]), circle(64, 76, 29)),  # water drop
    "cargo": union(subtract(box(64, 64, 40, 40, 0, 4), box(64, 64, 29, 29)),  # crate: frame and brace
                   segment(38, 38, 90, 90, 9), segment(38, 90, 90, 38, 9)),
    "fishing": union(polygon([(20, 64), (64, 34), (100, 64), (64, 94)]), polygon([(92, 64), (116, 40), (116, 88)])),
}


def render(sdf):
    """White inside, a dark rim around it, transparent outside."""
    rows = []
    for py in range(SIZE):
        row = bytearray()
        for px in range(SIZE):
            fill = rim = 0
            for sy in range(3):
                for sx in range(3):
                    d = sdf(px + (sx + 0.5) / 3, py + (sy + 0.5) / 3)
                    if d < 0:
                        fill += 1
                    elif d < OUTLINE:
                        rim += 1
            g = 25 + int(230 * fill / (fill + rim)) if fill + rim else 0
            row += bytes((g, g, g, int(255 * (fill + rim) / 9)))
        rows.append(bytes(row))
    return rows


def write_png(path, rows):
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, sdf in ICONS.items():
        write_png(os.path.join(OUT, name + ".png"), render(sdf))
        print("icon", name)
