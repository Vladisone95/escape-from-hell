#!/usr/bin/env python3
"""Generate tileset atlas (13 tile variants, 128x128) + lava noise texture."""
from PIL import Image, ImageDraw
import random, math

S = 32  # tile size
COLS = 4
ROWS = 4
OUT_DIR = "/root/home-projects/escape-from-hell/assets/sprites/tiles"

# Base colors
FLOOR_BASE = (20, 8, 10)
FLOOR_MORTAR = (15, 5, 7)
FLOOR_SPECK = (30, 12, 14)
EDGE_DARK = (12, 4, 6)
EDGE_HIGHLIGHT = (35, 14, 12)

def _textured_fill(draw, rng, x0, y0, w, h, base, variation=6):
    """Fill a region with per-pixel noise texture."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            v = rng.randint(-variation, variation)
            r = max(0, min(255, base[0] + v))
            g = max(0, min(255, base[1] + v // 2))
            b = max(0, min(255, base[2] + v // 2))
            draw.point((x, y), fill=(r, g, b, 255))

def _draw_stone_pattern(draw, rng):
    """Draw the brick/stone mortar pattern on a 32x32 tile."""
    mortar = FLOOR_MORTAR + (255,)
    for x in range(S):
        draw.point((x, 0), fill=mortar)
        draw.point((x, 16), fill=mortar)
    for y in range(1, 16):
        draw.point((0, y), fill=mortar)
        draw.point((16, y), fill=mortar)
    for y in range(17, S):
        draw.point((8, y), fill=mortar)
        draw.point((24, y), fill=mortar)
    # Brighter specks
    for _ in range(4):
        x, y = rng.randint(2, S - 3), rng.randint(2, S - 3)
        draw.point((x, y), fill=FLOOR_SPECK + (255,))

def generate_floor_center(rng):
    """Standard floor tile."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _textured_fill(draw, rng, 0, 0, S, S, FLOOR_BASE)
    _draw_stone_pattern(draw, rng)
    return img

def _apply_edge(img, rng, sides):
    """Apply dark edge + highlight on specified sides (n/s/e/w)."""
    draw = ImageDraw.Draw(img)
    edge_width = 6
    for side in sides:
        if side == 'n':
            for y in range(edge_width):
                alpha = 1.0 - y / edge_width
                for x in range(S):
                    _blend_pixel(img, x, y, EDGE_DARK, alpha * 0.8, rng)
                if y == edge_width - 1:
                    for x in range(S):
                        if rng.random() < 0.6:
                            draw.point((x, y), fill=EDGE_HIGHLIGHT + (200,))
        elif side == 's':
            for y in range(S - edge_width, S):
                alpha = (y - (S - edge_width)) / edge_width
                for x in range(S):
                    _blend_pixel(img, x, y, EDGE_DARK, alpha * 0.8, rng)
                if y == S - edge_width:
                    for x in range(S):
                        if rng.random() < 0.6:
                            draw.point((x, y), fill=EDGE_HIGHLIGHT + (200,))
        elif side == 'w':
            for x in range(edge_width):
                alpha = 1.0 - x / edge_width
                for y in range(S):
                    _blend_pixel(img, x, y, EDGE_DARK, alpha * 0.8, rng)
                if x == edge_width - 1:
                    for y in range(S):
                        if rng.random() < 0.6:
                            draw.point((x, y), fill=EDGE_HIGHLIGHT + (200,))
        elif side == 'e':
            for x in range(S - edge_width, S):
                alpha = (x - (S - edge_width)) / edge_width
                for y in range(S):
                    _blend_pixel(img, x, y, EDGE_DARK, alpha * 0.8, rng)
                if x == S - edge_width:
                    for y in range(S):
                        if rng.random() < 0.6:
                            draw.point((x, y), fill=EDGE_HIGHLIGHT + (200,))
    # Jagged edge pixels
    for side in sides:
        for _ in range(8):
            if side == 'n':
                x, y = rng.randint(0, S-1), rng.randint(0, 3)
            elif side == 's':
                x, y = rng.randint(0, S-1), rng.randint(S-4, S-1)
            elif side == 'w':
                x, y = rng.randint(0, 3), rng.randint(0, S-1)
            elif side == 'e':
                x, y = rng.randint(S-4, S-1), rng.randint(0, S-1)
            else:
                continue
            draw.point((x, y), fill=(8, 2, 3, 255))

def _blend_pixel(img, x, y, color, alpha, rng):
    """Blend a color onto existing pixel with noise."""
    if x < 0 or x >= S or y < 0 or y >= S:
        return
    existing = img.getpixel((x, y))
    v = rng.randint(-3, 3)
    r = int(existing[0] * (1 - alpha) + (color[0] + v) * alpha)
    g = int(existing[1] * (1 - alpha) + (color[1] + v) * alpha)
    b = int(existing[2] * (1 - alpha) + (color[2] + v) * alpha)
    img.putpixel((x, y), (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255))

def generate_edge(rng, sides):
    """Floor tile with edge(s) facing lava."""
    img = generate_floor_center(rng)
    _apply_edge(img, rng, sides)
    return img

# Atlas layout (4x4 grid):
# Row 0: center, edge_n, edge_e, edge_s
# Row 1: edge_w, corner_nw, corner_ne, corner_sw
# Row 2: corner_se, inner_nw, inner_ne, inner_sw
# Row 3: inner_se, wall_top, (unused), (unused)

TILE_INDEX = {
    "center": (0, 0),
    "edge_n": (1, 0),
    "edge_e": (2, 0),
    "edge_s": (3, 0),
    "edge_w": (0, 1),
    "corner_nw": (1, 1),
    "corner_ne": (2, 1),
    "corner_sw": (3, 1),
    "corner_se": (0, 2),
    "inner_nw": (1, 2),
    "inner_ne": (2, 2),
    "inner_sw": (3, 2),
    "inner_se": (0, 3),
    "wall_top": (1, 3),
}

def generate_wall_tile(rng):
    """Dark hellish wall tile."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _textured_fill(draw, rng, 0, 0, S, S, (64, 15, 5), variation=8)
    mortar = (40, 10, 3, 255)
    for x in range(S):
        draw.point((x, 0), fill=mortar)
        draw.point((x, 10), fill=mortar)
        draw.point((x, 20), fill=mortar)
    for y in range(1, 10):
        draw.point((0, y), fill=mortar)
        draw.point((16, y), fill=mortar)
    for y in range(11, 20):
        draw.point((8, y), fill=mortar)
        draw.point((24, y), fill=mortar)
    for y in range(21, S):
        draw.point((0, y), fill=mortar)
        draw.point((16, y), fill=mortar)
    hl = (80, 22, 10, 255)
    for x in range(S):
        draw.point((x, 1), fill=hl)
        draw.point((x, 11), fill=hl)
        draw.point((x, 21), fill=hl)
    return img

def generate_tileset_atlas():
    """Generate the full tileset atlas PNG."""
    atlas = Image.new('RGBA', (COLS * S, ROWS * S), (0, 0, 0, 0))
    rng = random.Random(42)

    tiles = {}
    tiles["center"] = generate_floor_center(random.Random(42))
    tiles["edge_n"] = generate_edge(random.Random(43), ['n'])
    tiles["edge_e"] = generate_edge(random.Random(44), ['e'])
    tiles["edge_s"] = generate_edge(random.Random(45), ['s'])
    tiles["edge_w"] = generate_edge(random.Random(46), ['w'])
    tiles["corner_nw"] = generate_edge(random.Random(47), ['n', 'w'])
    tiles["corner_ne"] = generate_edge(random.Random(48), ['n', 'e'])
    tiles["corner_sw"] = generate_edge(random.Random(49), ['s', 'w'])
    tiles["corner_se"] = generate_edge(random.Random(50), ['s', 'e'])
    # Inner corners: floor with a concave lava notch in one corner
    tiles["inner_nw"] = _generate_inner_corner(random.Random(51), 'nw')
    tiles["inner_ne"] = _generate_inner_corner(random.Random(52), 'ne')
    tiles["inner_sw"] = _generate_inner_corner(random.Random(53), 'sw')
    tiles["inner_se"] = _generate_inner_corner(random.Random(54), 'se')
    tiles["wall_top"] = generate_wall_tile(random.Random(99))

    for name, (col, row) in TILE_INDEX.items():
        atlas.paste(tiles[name], (col * S, row * S))

    atlas.save(f"{OUT_DIR}/tileset.png")
    print(f"  tileset atlas: {COLS * S}x{ROWS * S} ({len(tiles)} tiles)")

def _generate_inner_corner(rng, corner):
    """Floor tile with a concave lava notch in one corner."""
    img = generate_floor_center(rng)
    draw = ImageDraw.Draw(img)
    notch_size = 8
    if corner == 'nw':
        for y in range(notch_size):
            for x in range(notch_size - y):
                _blend_pixel(img, x, y, EDGE_DARK, 0.85, rng)
        for i in range(notch_size):
            draw.point((notch_size - i, i), fill=EDGE_HIGHLIGHT + (220,))
    elif corner == 'ne':
        for y in range(notch_size):
            for x in range(S - notch_size + y, S):
                _blend_pixel(img, x, y, EDGE_DARK, 0.85, rng)
        for i in range(notch_size):
            draw.point((S - notch_size + i - 1, i), fill=EDGE_HIGHLIGHT + (220,))
    elif corner == 'sw':
        for y in range(S - notch_size, S):
            dy = y - (S - notch_size)
            for x in range(notch_size - dy):
                _blend_pixel(img, x, y, EDGE_DARK, 0.85, rng)
        for i in range(notch_size):
            draw.point((notch_size - i, S - notch_size + i - 1), fill=EDGE_HIGHLIGHT + (220,))
    elif corner == 'se':
        for y in range(S - notch_size, S):
            dy = y - (S - notch_size)
            for x in range(S - notch_size + dy, S):
                _blend_pixel(img, x, y, EDGE_DARK, 0.85, rng)
        for i in range(notch_size):
            draw.point((S - notch_size + i - 1, S - notch_size + i - 1), fill=EDGE_HIGHLIGHT + (220,))
    return img


def generate_lava_noise():
    """Generate a 64x64 tileable Perlin-like noise texture for the lava shader."""
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    rng = random.Random(777)

    # Layered random blobs for organic noise
    noise = [[0.0] * size for _ in range(size)]

    for octave in range(4):
        scale = 2 ** octave
        weight = 1.0 / (scale * 0.7)
        # Place random value points
        grid_s = max(2, size // (4 * scale))
        values = [[rng.random() for _ in range(grid_s + 2)] for _ in range(grid_s + 2)]
        for y in range(size):
            for x in range(size):
                fx = (x / size) * grid_s
                fy = (y / size) * grid_s
                ix, iy = int(fx) % grid_s, int(fy) % grid_s
                fx_frac = fx - int(fx)
                fy_frac = fy - int(fy)
                # Bilinear interpolation with wrapping
                v00 = values[iy % len(values)][ix % len(values[0])]
                v10 = values[iy % len(values)][(ix + 1) % len(values[0])]
                v01 = values[(iy + 1) % len(values)][ix % len(values[0])]
                v11 = values[(iy + 1) % len(values)][(ix + 1) % len(values[0])]
                # Smoothstep
                fx_frac = fx_frac * fx_frac * (3 - 2 * fx_frac)
                fy_frac = fy_frac * fy_frac * (3 - 2 * fy_frac)
                v = v00 * (1-fx_frac) * (1-fy_frac) + v10 * fx_frac * (1-fy_frac) + \
                    v01 * (1-fx_frac) * fy_frac + v11 * fx_frac * fy_frac
                noise[y][x] += v * weight

    # Normalize to 0-255
    min_v = min(min(row) for row in noise)
    max_v = max(max(row) for row in noise)
    rng_v = max_v - min_v if max_v > min_v else 1.0
    for y in range(size):
        for x in range(size):
            val = int(((noise[y][x] - min_v) / rng_v) * 255)
            img.putpixel((x, y), (val, val, val, 255))

    img.save(f"{OUT_DIR}/lava_noise.png")
    print(f"  lava noise: {size}x{size}")

    # Also keep old floor.png and wall.png for backward compat
    generate_legacy_tiles()

def generate_legacy_tiles():
    """Generate the old standalone floor.png and wall.png."""
    rng = random.Random(42)
    floor_img = generate_floor_center(rng)
    floor_img.save(f"{OUT_DIR}/floor.png")

    wall_rng = random.Random(99)
    wall_img = generate_wall_tile(wall_rng)
    wall_img.save(f"{OUT_DIR}/wall.png")
    print("  legacy floor.png + wall.png preserved")


if __name__ == "__main__":
    print("Generating tiles...")
    generate_tileset_atlas()
    generate_lava_noise()
    print("Done!")
