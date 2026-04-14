#!/usr/bin/env python3
"""Generate tileset atlas (14 tile variants, 512x512) + lava noise texture."""
from PIL import Image, ImageDraw, ImageFilter
import random, math, os

S = 128  # tile size (128px source, displayed at 64px = 2:1 supersampling)
COLS = 4
ROWS = 4
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "tiles")

# Base colors — cooler gray-brown for character contrast
FLOOR_BASE = (20, 15, 17)
FLOOR_MID = (16, 12, 14)
FLOOR_LIGHT = (30, 23, 26)
FLOOR_MORTAR = (8, 5, 7)
FLOOR_SPECK = (36, 27, 29)
FLOOR_SPECK2 = (24, 18, 20)
EDGE_DARK = (7, 4, 6)
EDGE_HIGHLIGHT = (40, 30, 28)
EDGE_HIGHLIGHT2 = (32, 24, 22)
LAVA_HOT = (220, 88, 18)
LAVA_WARM = (170, 52, 10)
LAVA_GLOW = (120, 30, 5)

# Mortar groove colors (3-tone for ambient occlusion)
MORTAR_DEEP = (5, 2, 4)
MORTAR_MID = (8, 5, 7)
MORTAR_HIGHLIGHT = (18, 12, 14)

# Bevel colors
BEVEL_LIGHT = (30, 23, 26)
BEVEL_SHADOW = (10, 7, 9)


def _noise_grid(rng, grid_w, grid_h):
    """Generate a 2D grid of random values for noise interpolation."""
    return [[rng.random() for _ in range(grid_w)] for _ in range(grid_h)]


def _sample_noise(grid, x_frac, y_frac, grid_w, grid_h):
    """Bilinear sample from noise grid."""
    fx = x_frac * grid_w
    fy = y_frac * grid_h
    ix = int(fx) % grid_w
    iy = int(fy) % grid_h
    fx_f = fx - int(fx)
    fy_f = fy - int(fy)
    # Smoothstep
    fx_f = fx_f * fx_f * (3 - 2 * fx_f)
    fy_f = fy_f * fy_f * (3 - 2 * fy_f)
    v00 = grid[iy][ix]
    v10 = grid[iy][(ix + 1) % grid_w]
    v01 = grid[(iy + 1) % grid_h][ix]
    v11 = grid[(iy + 1) % grid_h][(ix + 1) % grid_w]
    return (v00 * (1 - fx_f) * (1 - fy_f) + v10 * fx_f * (1 - fy_f) +
            v01 * (1 - fx_f) * fy_f + v11 * fx_f * fy_f)


def _noise_textured_fill(img_arr, rng, x0, y0, w, h, base, variation=10):
    """Fill region with 3-octave spatially coherent noise for organic stone look."""
    # Pre-generate noise grids for each octave
    grids = []
    grid_sizes = [(4, 4), (8, 8), (16, 16)]
    weights = [1.0, 0.5, 0.3]
    for gw, gh in grid_sizes:
        grids.append(_noise_grid(rng, gw, gh))

    total_weight = sum(weights)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            xf = (x - x0) / max(w, 1)
            yf = (y - y0) / max(h, 1)
            noise_val = 0.0
            for i, (gw, gh) in enumerate(grid_sizes):
                noise_val += _sample_noise(grids[i], xf, yf, gw, gh) * weights[i]
            noise_val /= total_weight
            # Map to [-variation, +variation]
            v = int((noise_val - 0.5) * 2.0 * variation)
            warm = rng.randint(-2, 2)
            r = max(0, min(255, base[0] + v + warm))
            g = max(0, min(255, base[1] + v // 2))
            b = max(0, min(255, base[2] + v // 2))
            img_arr[y][x] = (r, g, b, 255)


def _draw_stone_pattern(img, draw, rng):
    """Draw varied stone blocks with beveling, mortar grooves, and weathering on 128x128 tile."""
    # Generate irregular stone layout: 3-4 rows with varied heights
    row_count = rng.randint(3, 4)
    mortar_width = 2
    total_height = S - mortar_width * (row_count + 1)
    row_heights = []
    remaining = total_height
    for i in range(row_count):
        if i == row_count - 1:
            row_heights.append(remaining)
        else:
            h = rng.randint(int(total_height * 0.2), int(total_height * 0.35))
            h = min(h, remaining - (row_count - i - 1) * 12)
            row_heights.append(h)
            remaining -= h

    # For each row, generate stone blocks with varied widths
    blocks = []  # list of (x, y, w, h, color_offset) for each block
    y_pos = mortar_width
    for row_idx in range(row_count):
        rh = row_heights[row_idx]
        # Generate seam positions for this row
        x_pos = mortar_width
        # Offset every other row for running bond pattern
        if row_idx % 2 == 1:
            x_pos += rng.randint(12, 28)
        while x_pos < S - mortar_width - 10:
            block_w = rng.randint(24, 52)
            block_w = min(block_w, S - mortar_width - x_pos)
            if block_w < 10:
                break
            color_off = rng.randint(-5, 5)
            blocks.append((x_pos, y_pos, block_w, rh, color_off))
            x_pos += block_w + mortar_width
        y_pos += rh + mortar_width

    # Draw mortar everywhere first (the gaps between stones)
    for y in range(S):
        for x in range(S):
            draw.point((x, y), fill=MORTAR_DEEP + (255,))

    # Draw each stone block
    for (bx, by, bw, bh, col_off) in blocks:
        # Fill block with per-block color variation
        base = (
            max(0, min(255, FLOOR_BASE[0] + col_off)),
            max(0, min(255, FLOOR_BASE[1] + col_off // 2)),
            max(0, min(255, FLOOR_BASE[2] + col_off // 2)),
        )
        for y in range(by, min(by + bh, S)):
            for x in range(bx, min(bx + bw, S)):
                v = rng.randint(-6, 6)
                r = max(0, min(255, base[0] + v))
                g = max(0, min(255, base[1] + v // 2))
                b = max(0, min(255, base[2] + v // 2))
                img.putpixel((x, y), (r, g, b, 255))

        # 3D Bevel: highlight on top and left edges
        for x in range(bx, min(bx + bw, S)):
            if by < S:
                draw.point((x, by), fill=BEVEL_LIGHT + (180,))
            if by + 1 < S:
                draw.point((x, by + 1), fill=BEVEL_LIGHT + (100,))
        for y in range(by, min(by + bh, S)):
            if bx < S:
                draw.point((bx, y), fill=BEVEL_LIGHT + (140,))
            if bx + 1 < S:
                draw.point((bx + 1, y), fill=BEVEL_LIGHT + (80,))

        # Shadow on bottom and right edges
        for x in range(bx, min(bx + bw, S)):
            yb = by + bh - 1
            if yb >= 0 and yb < S:
                draw.point((x, yb), fill=BEVEL_SHADOW + (200,))
            if yb - 1 >= 0 and yb - 1 < S:
                draw.point((x, yb - 1), fill=BEVEL_SHADOW + (120,))
        for y in range(by, min(by + bh, S)):
            xr = bx + bw - 1
            if xr >= 0 and xr < S:
                draw.point((xr, y), fill=BEVEL_SHADOW + (160,))
            if xr - 1 >= 0 and xr - 1 < S:
                draw.point((xr - 1, y), fill=BEVEL_SHADOW + (90,))

        # Mortar groove highlight (top edge of mortar below block)
        for x in range(bx, min(bx + bw, S)):
            yh = by + bh
            if yh < S:
                draw.point((x, yh), fill=MORTAR_HIGHLIGHT + (160,))

        # Pitting: dark erosion spots
        pit_count = rng.randint(6, 12)
        for _ in range(pit_count):
            px = rng.randint(bx + 2, min(bx + bw - 3, S - 1))
            py = rng.randint(by + 2, min(by + bh - 3, S - 1))
            if px < S and py < S:
                ex = img.getpixel((px, py))
                dark = (max(0, ex[0] - 8), max(0, ex[1] - 4), max(0, ex[2] - 4), 255)
                draw.point((px, py), fill=dark)
                if px + 1 < bx + bw and px + 1 < S:
                    draw.point((px + 1, py), fill=dark)

        # Surface specks
        speck_count = rng.randint(4, 8)
        for _ in range(speck_count):
            sx = rng.randint(bx + 2, min(bx + bw - 3, S - 1))
            sy = rng.randint(by + 2, min(by + bh - 3, S - 1))
            if sx < S and sy < S:
                draw.point((sx, sy), fill=FLOOR_SPECK + (255,))
                if sx + 1 < bx + bw and sx + 1 < S:
                    draw.point((sx + 1, sy), fill=FLOOR_SPECK2 + (180,))

    # Micro-cracks across the tile
    crack_count = rng.randint(3, 5)
    for _ in range(crack_count):
        cx = rng.randint(5, S - 15)
        cy = rng.randint(5, S - 15)
        points = [(cx, cy)]
        for seg in range(rng.randint(2, 4)):
            nx = points[-1][0] + rng.randint(3, 12)
            ny = points[-1][1] + rng.randint(-5, 5)
            nx = max(0, min(S - 1, nx))
            ny = max(0, min(S - 1, ny))
            points.append((nx, ny))
        if len(points) >= 2:
            draw.line(points, fill=(FLOOR_MORTAR[0], FLOOR_MORTAR[1], FLOOR_MORTAR[2], 140), width=1)


def _pix_array(img):
    """Return mutable 2D array of (r,g,b,a) from img."""
    w, h = img.size
    arr = [[None] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            arr[y][x] = img.getpixel((x, y))
    return arr


def _array_to_img(arr, w, h):
    out = Image.new('RGBA', (w, h))
    for y in range(h):
        for x in range(w):
            out.putpixel((x, y), arr[y][x])
    return out


def generate_floor_center(rng):
    """Standard floor tile — 128x128 with detailed stone pattern."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    arr = _pix_array(img)
    _noise_textured_fill(arr, rng, 0, 0, S, S, FLOOR_BASE, variation=10)
    img = _array_to_img(arr, S, S)
    draw = ImageDraw.Draw(img)
    _draw_stone_pattern(img, draw, rng)
    return img


def _generate_jagged_edge(rng, length, amplitude=3):
    """Generate a smoothed jagged edge offset array for organic borders."""
    raw = [rng.randint(-amplitude, amplitude) for _ in range(length)]
    # 3-tap smooth
    smoothed = [0] * length
    for i in range(length):
        prev = raw[max(0, i - 1)]
        curr = raw[i]
        nxt = raw[min(length - 1, i + 1)]
        smoothed[i] = (prev + curr + nxt) // 3
    return smoothed


def _apply_edge(img, rng, sides):
    """Apply multi-zone lava transition on specified sides, 128px version."""
    draw = ImageDraw.Draw(img)

    def _blend(x, y, color, alpha):
        if x < 0 or x >= S or y < 0 or y >= S:
            return
        ex = img.getpixel((x, y))
        v = rng.randint(-2, 2)
        r = int(ex[0] * (1 - alpha) + (color[0] + v) * alpha)
        g = int(ex[1] * (1 - alpha) + (color[1] + v) * alpha)
        b = int(ex[2] * (1 - alpha) + (color[2] + v) * alpha)
        img.putpixel((x, y), (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255))

    for side in sides:
        # Generate jagged edge mask
        jag = _generate_jagged_edge(rng, S, amplitude=3)

        for pos_along in range(S):
            jag_off = jag[pos_along]

            # Zone 1: Hot rim (0-4px from edge)
            for d in range(4):
                t = 1.0 - d / 4.0
                t_sq = t * t
                rim_r = int(255 * t_sq + 240 * (1 - t_sq))
                rim_g = int(200 * t_sq + 130 * (1 - t_sq))
                rim_b = int(80 * t_sq + 30 * (1 - t_sq))
                alpha = t_sq * 0.92
                px, py = _edge_pixel(side, pos_along, d + jag_off)
                _blend(px, py, (rim_r, rim_g, rim_b), alpha)

            # Zone 2: Lava glow (4-14px)
            for d in range(4, 14):
                t = (14.0 - d) / 10.0
                t_cb = t * t * t
                glow_r = int(LAVA_HOT[0] * t_cb + LAVA_GLOW[0] * (1 - t_cb))
                glow_g = int(LAVA_HOT[1] * t_cb + LAVA_GLOW[1] * (1 - t_cb))
                glow_b = int(LAVA_HOT[2] * t_cb + LAVA_GLOW[2] * (1 - t_cb))
                alpha = t_cb * 0.80
                px, py = _edge_pixel(side, pos_along, d + jag_off)
                _blend(px, py, (glow_r, glow_g, glow_b), alpha)

            # Zone 3: Charred stone (14-30px)
            for d in range(14, 30):
                t = (30.0 - d) / 16.0
                t_sq = t * t
                alpha = t_sq * 0.65
                px, py = _edge_pixel(side, pos_along, d + jag_off)
                _blend(px, py, (8, 4, 5), alpha)

            # Zone 4: Heat influence (30-45px)
            for d in range(30, 45):
                t = (45.0 - d) / 15.0
                alpha = t * 0.18
                px, py = _edge_pixel(side, pos_along, d + jag_off)
                _blend(px, py, (FLOOR_BASE[0] + 8, FLOOR_BASE[1] - 2, FLOOR_BASE[2] - 2), alpha)

        # Charring cracks in the 14-28px zone
        for _ in range(rng.randint(12, 18)):
            pos_along = rng.randint(0, S - 1)
            depth = rng.randint(14, 26)
            crack_len = rng.randint(2, 5)
            for cl in range(crack_len):
                px, py = _edge_pixel(side, pos_along, depth + cl)
                if 0 <= px < S and 0 <= py < S:
                    draw.point((px, py), fill=(4, 2, 3, 200))

        # Ember specks in the 0-20px zone
        ember_colors = [(255, 180, 40), (220, 100, 20), (180, 55, 8), (255, 220, 80)]
        for _ in range(rng.randint(28, 40)):
            pos_along = rng.randint(0, S - 1)
            depth = rng.randint(0, 18)
            ec = ember_colors[rng.randint(0, len(ember_colors) - 1)]
            px, py = _edge_pixel(side, pos_along, depth + jag[pos_along % len(jag)])
            if 0 <= px < S and 0 <= py < S:
                alpha_val = rng.randint(160, 255)
                draw.point((px, py), fill=ec + (alpha_val,))
                # Some embers are 2px for brightness
                if rng.random() < 0.3:
                    px2, py2 = _edge_pixel(side, min(pos_along + 1, S - 1), depth + jag[pos_along % len(jag)])
                    if 0 <= px2 < S and 0 <= py2 < S:
                        draw.point((px2, py2), fill=ec + (alpha_val // 2,))


def _edge_pixel(side, pos_along, depth):
    """Convert (side, position along edge, depth into tile) to (x, y)."""
    if side == 'n':
        return (pos_along, depth)
    elif side == 's':
        return (pos_along, S - 1 - depth)
    elif side == 'w':
        return (depth, pos_along)
    elif side == 'e':
        return (S - 1 - depth, pos_along)
    return (0, 0)


def generate_edge(rng, sides):
    img = generate_floor_center(rng)
    _apply_edge(img, rng, sides)
    return img


# Atlas layout (4x4 grid, each cell 128x128 → 512x512 atlas):
# Row 0: center, edge_n, edge_e, edge_s
# Row 1: edge_w, corner_nw, corner_ne, corner_sw
# Row 2: corner_se, inner_nw, inner_ne, inner_sw
# Row 3: inner_se, wall_top, (unused), (unused)

TILE_INDEX = {
    "center":    (0, 0),
    "edge_n":    (1, 0),
    "edge_e":    (2, 0),
    "edge_s":    (3, 0),
    "edge_w":    (0, 1),
    "corner_nw": (1, 1),
    "corner_ne": (2, 1),
    "corner_sw": (3, 1),
    "corner_se": (0, 2),
    "inner_nw":  (1, 2),
    "inner_ne":  (2, 2),
    "inner_sw":  (3, 2),
    "inner_se":  (0, 3),
    "wall_top":  (1, 3),
}


def generate_wall_tile(rng):
    """Dark hellish wall tile — 128x128 with varied bricks and beveling."""
    wall_base = (70, 17, 6)
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    arr = _pix_array(img)
    _noise_textured_fill(arr, rng, 0, 0, S, S, wall_base, variation=12)
    img = _array_to_img(arr, S, S)
    draw = ImageDraw.Draw(img)
    mortar = (42, 11, 3, 255)
    mortar_deep = (28, 7, 2, 255)
    mortar_hl = (55, 15, 5, 200)
    brick_hl = (90, 25, 12, 220)

    # 5 rows of bricks with 2px mortar grooves
    mortar_rows = [0, 24, 50, 76, 102]
    for my in mortar_rows:
        for x in range(S):
            if my < S:
                draw.point((x, my), fill=mortar_deep)
            if my + 1 < S:
                draw.point((x, my + 1), fill=mortar)
            if my + 2 < S:
                draw.point((x, my + 2), fill=mortar_hl)

    # Vertical seams — varied positions per row
    row_bounds = [(2, 22), (26, 48), (52, 74), (78, 100), (104, 126)]
    for ri, (ry0, ry1) in enumerate(row_bounds):
        # Generate random seam positions
        seams = [0]
        x = rng.randint(28, 42)
        while x < S - 10:
            seams.append(x)
            x += rng.randint(28, 48)
        for sx in seams:
            for y in range(ry0, min(ry1 + 1, S)):
                if sx < S:
                    draw.point((sx, y), fill=mortar_deep)
                if sx + 1 < S:
                    draw.point((sx + 1, y), fill=mortar)

        # Bevel highlights at top of each brick
        for x in range(S):
            if ry0 < S:
                draw.point((x, ry0), fill=brick_hl)

    # Subtle cracks
    for _ in range(6):
        x1 = rng.randint(3, S - 20)
        y1 = rng.randint(3, S - 10)
        draw.line([(x1, y1), (x1 + rng.randint(3, 12), y1 + rng.randint(-3, 3))],
                  fill=(30, 7, 2, 150), width=1)
    return img


def _generate_inner_corner(rng, corner):
    """Floor tile with a concave lava notch in one corner, 128px."""
    img = generate_floor_center(rng)
    draw = ImageDraw.Draw(img)
    notch_size = 28  # proportional to 128px

    def _blend(x, y, color, alpha):
        if x < 0 or x >= S or y < 0 or y >= S:
            return
        ex = img.getpixel((x, y))
        v = rng.randint(-2, 2)
        r = int(ex[0] * (1 - alpha) + (color[0] + v) * alpha)
        g = int(ex[1] * (1 - alpha) + (color[1] + v) * alpha)
        b = int(ex[2] * (1 - alpha) + (color[2] + v) * alpha)
        img.putpixel((x, y), (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255))

    # Draw the triangular notch with multi-zone treatment
    if corner == 'nw':
        for y in range(notch_size):
            for x in range(notch_size - y):
                dist = max(0, notch_size - x - y)
                if dist < 4:
                    _blend(x, y, (255, 200, 80), 0.85)
                elif dist < 12:
                    t = (12 - dist) / 8.0
                    _blend(x, y, LAVA_HOT, t * 0.75)
                else:
                    _blend(x, y, EDGE_DARK, 0.85)
        for i in range(notch_size):
            if notch_size - i >= 0 and notch_size - i < S and i < S:
                draw.point((notch_size - i, i), fill=EDGE_HIGHLIGHT + (230,))
                if notch_size - i + 1 < S:
                    draw.point((notch_size - i + 1, i), fill=EDGE_HIGHLIGHT2 + (160,))
    elif corner == 'ne':
        for y in range(notch_size):
            for x in range(S - notch_size + y, S):
                dist = max(0, notch_size - (S - 1 - x) - y)
                if dist < 4:
                    _blend(x, y, (255, 200, 80), 0.85)
                elif dist < 12:
                    t = (12 - dist) / 8.0
                    _blend(x, y, LAVA_HOT, t * 0.75)
                else:
                    _blend(x, y, EDGE_DARK, 0.85)
        for i in range(notch_size):
            px = S - notch_size + i - 1
            if 0 <= px < S and i < S:
                draw.point((px, i), fill=EDGE_HIGHLIGHT + (230,))
    elif corner == 'sw':
        for y in range(S - notch_size, S):
            dy = y - (S - notch_size)
            for x in range(notch_size - dy):
                dist = max(0, notch_size - x - dy)
                if dist < 4:
                    _blend(x, y, (255, 200, 80), 0.85)
                elif dist < 12:
                    t = (12 - dist) / 8.0
                    _blend(x, y, LAVA_HOT, t * 0.75)
                else:
                    _blend(x, y, EDGE_DARK, 0.85)
        for i in range(notch_size):
            py = S - notch_size + i - 1
            if notch_size - i >= 0 and notch_size - i < S and 0 <= py < S:
                draw.point((notch_size - i, py), fill=EDGE_HIGHLIGHT + (230,))
    elif corner == 'se':
        for y in range(S - notch_size, S):
            dy = y - (S - notch_size)
            for x in range(S - notch_size + dy, S):
                dist = max(0, notch_size - (S - 1 - x) - dy)
                if dist < 4:
                    _blend(x, y, (255, 200, 80), 0.85)
                elif dist < 12:
                    t = (12 - dist) / 8.0
                    _blend(x, y, LAVA_HOT, t * 0.75)
                else:
                    _blend(x, y, EDGE_DARK, 0.85)
        for i in range(notch_size):
            px = S - notch_size + i - 1
            py = S - notch_size + i - 1
            if 0 <= px < S and 0 <= py < S:
                draw.point((px, py), fill=EDGE_HIGHLIGHT + (230,))
    return img


def generate_tileset_atlas():
    """Generate the full tileset atlas PNG (512x512)."""
    atlas = Image.new('RGBA', (COLS * S, ROWS * S), (0, 0, 0, 0))

    tiles = {
        "center":    generate_floor_center(random.Random(42)),
        "edge_n":    generate_edge(random.Random(43), ['n']),
        "edge_e":    generate_edge(random.Random(44), ['e']),
        "edge_s":    generate_edge(random.Random(45), ['s']),
        "edge_w":    generate_edge(random.Random(46), ['w']),
        "corner_nw": generate_edge(random.Random(47), ['n', 'w']),
        "corner_ne": generate_edge(random.Random(48), ['n', 'e']),
        "corner_sw": generate_edge(random.Random(49), ['s', 'w']),
        "corner_se": generate_edge(random.Random(50), ['s', 'e']),
        "inner_nw":  _generate_inner_corner(random.Random(51), 'nw'),
        "inner_ne":  _generate_inner_corner(random.Random(52), 'ne'),
        "inner_sw":  _generate_inner_corner(random.Random(53), 'sw'),
        "inner_se":  _generate_inner_corner(random.Random(54), 'se'),
        "wall_top":  generate_wall_tile(random.Random(99)),
    }

    for name, (col, row) in TILE_INDEX.items():
        atlas.paste(tiles[name], (col * S, row * S))

    os.makedirs(OUT_DIR, exist_ok=True)
    atlas.save(os.path.join(OUT_DIR, "tileset.png"))
    print(f"  tileset atlas: {COLS * S}x{ROWS * S} ({len(tiles)} tiles, {S}px each)")


def generate_lava_noise():
    """Generate a 64x64 tileable Perlin-like noise texture for the lava shader."""
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    rng = random.Random(777)

    noise = [[0.0] * size for _ in range(size)]

    for octave in range(4):
        scale = 2 ** octave
        weight = 1.0 / (scale * 0.7)
        grid_s = max(2, size // (4 * scale))
        values = [[rng.random() for _ in range(grid_s + 2)] for _ in range(grid_s + 2)]
        for y in range(size):
            for x in range(size):
                fx = (x / size) * grid_s
                fy = (y / size) * grid_s
                ix, iy = int(fx) % grid_s, int(fy) % grid_s
                fx_frac = fx - int(fx)
                fy_frac = fy - int(fy)
                v00 = values[iy % len(values)][ix % len(values[0])]
                v10 = values[iy % len(values)][(ix + 1) % len(values[0])]
                v01 = values[(iy + 1) % len(values)][ix % len(values[0])]
                v11 = values[(iy + 1) % len(values)][(ix + 1) % len(values[0])]
                fx_frac = fx_frac * fx_frac * (3 - 2 * fx_frac)
                fy_frac = fy_frac * fy_frac * (3 - 2 * fy_frac)
                v = (v00 * (1 - fx_frac) * (1 - fy_frac) + v10 * fx_frac * (1 - fy_frac) +
                     v01 * (1 - fx_frac) * fy_frac + v11 * fx_frac * fy_frac)
                noise[y][x] += v * weight

    min_v = min(min(row) for row in noise)
    max_v = max(max(row) for row in noise)
    rng_v = max_v - min_v if max_v > min_v else 1.0
    for y in range(size):
        for x in range(size):
            val = int(((noise[y][x] - min_v) / rng_v) * 255)
            img.putpixel((x, y), (val, val, val, 255))

    img.save(os.path.join(OUT_DIR, "lava_noise.png"))
    print(f"  lava noise: {size}x{size}")
    generate_legacy_tiles()


def generate_legacy_tiles():
    """Generate the old standalone floor.png and wall.png."""
    rng = random.Random(42)
    floor_img = generate_floor_center(rng)
    floor_img_32 = floor_img.resize((32, 32), Image.LANCZOS)
    floor_img_32.save(os.path.join(OUT_DIR, "floor.png"))

    wall_rng = random.Random(99)
    wall_img = generate_wall_tile(wall_rng)
    wall_img_32 = wall_img.resize((32, 32), Image.LANCZOS)
    wall_img_32.save(os.path.join(OUT_DIR, "wall.png"))
    print("  legacy floor.png + wall.png (32px downscaled)")


if __name__ == "__main__":
    print("Generating tiles...")
    generate_tileset_atlas()
    generate_lava_noise()
    print("Done!")
