#!/usr/bin/env python3
"""Generate item icon PNGs (64x64 each)."""
import math
from PIL import Image, ImageDraw

S = 64
cx, cy = S // 2, S // 2

def draw_filled_circle(draw, x, y, r, color, W=S, H=S):
    for dy in range(-r, r+1):
        for dx in range(-r, r+1):
            if dx*dx + dy*dy <= r*r:
                px, py = x + dx, y + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=color)


def make_dagger():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Blade
    d.rectangle([cx-2, cy-20, cx+1, cy+5], fill=(204, 211, 230, 255))
    d.rectangle([cx, cy-20, cx, cy+5], fill=(242, 245, 255, 255))
    # Tip
    d.rectangle([cx-1, cy-23, cx, cy-20], fill=(235, 240, 250, 255))
    # Crossguard
    d.rectangle([cx-7, cy+5, cx+6, cy+7], fill=(153, 140, 77, 255))
    # Hilt
    d.rectangle([cx-2, cy+8, cx+1, cy+17], fill=(128, 89, 38, 255))
    # Pommel
    d.rectangle([cx-3, cy+17, cx+2, cy+20], fill=(153, 140, 77, 255))
    return img


def make_slice_and_dice():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blade = (204, 211, 230, 255)
    guard = (153, 140, 77, 255)
    hilt = (128, 89, 38, 255)

    # Two crossed swords (draw at angles using rotation)
    for angle, ox in [(-0.35, -8), (0.35, 8)]:
        cos_a, sin_a = math.cos(angle), math.sin(angle)
        base_x = cx + ox
        base_y = cy
        # Draw blade, guard, hilt as rotated rectangles
        for ly in range(-18, 6):
            for lx in range(-1, 2):
                rx = int(base_x + lx * cos_a - ly * sin_a)
                ry = int(base_y + lx * sin_a + ly * cos_a)
                if 0 <= rx < S and 0 <= ry < S:
                    d.point((rx, ry), fill=blade)
        for ly in range(5, 8):
            for lx in range(-5, 5):
                rx = int(base_x + lx * cos_a - ly * sin_a)
                ry = int(base_y + lx * sin_a + ly * cos_a)
                if 0 <= rx < S and 0 <= ry < S:
                    d.point((rx, ry), fill=guard)
        for ly in range(7, 15):
            for lx in range(-1, 2):
                rx = int(base_x + lx * cos_a - ly * sin_a)
                ry = int(base_y + lx * sin_a + ly * cos_a)
                if 0 <= rx < S and 0 <= ry < S:
                    d.point((rx, ry), fill=hilt)

    # Slash arcs (simplified as curved lines)
    for t in range(12):
        a1 = -2.2 + t * (1.3 / 11)
        px = int(cx + 18 * math.cos(a1))
        py = int(cy - 4 + 18 * math.sin(a1))
        if 0 <= px < S and 0 <= py < S:
            d.point((px, py), fill=(255, 217, 77, 178))
    return img


def make_demon_heart():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hc = (178, 13, 25, 255)
    hl = (217, 38, 38, 255)
    hd = (115, 5, 13, 255)

    # Left lobe
    draw_filled_circle(d, cx - 7, cy - 6, 10, hc)
    # Right lobe
    draw_filled_circle(d, cx + 7, cy - 6, 10, hc)
    # Bottom fill
    d.rectangle([cx-16, cy-6, cx+15, cy+5], fill=hc)
    d.rectangle([cx-12, cy+6, cx+11, cy+11], fill=hc)
    d.rectangle([cx-8, cy+12, cx+7, cy+15], fill=hc)
    d.rectangle([cx-4, cy+16, cx+3, cy+18], fill=hc)
    d.rectangle([cx-1, cy+19, cx, cy+20], fill=hc)
    # Highlight
    draw_filled_circle(d, cx - 9, cy - 9, 4, hl)
    # Veins
    d.line([(cx, cy-4), (cx-5, cy+10)], fill=hd, width=1)
    d.line([(cx, cy-4), (cx+6, cy+8)], fill=hd, width=1)
    d.line([(cx-5, cy+10), (cx-2, cy+16)], fill=hd, width=1)
    # Glow dots
    draw_filled_circle(d, cx - 6, cy - 2, 2, (255, 77, 0, 178))
    draw_filled_circle(d, cx + 5, cy + 2, 1, (255, 77, 0, 128))
    return img


def make_thick_skin():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    sc = (128, 102, 64, 255)
    sl = (166, 140, 89, 255)
    sd = (89, 71, 38, 255)
    green = (51, 166, 51, 255)
    green_lt = (77, 204, 77, 255)

    # Shield body
    d.rectangle([cx-14, cy-16, cx+13, cy+11], fill=sc)
    d.rectangle([cx-12, cy+12, cx+11, cy+15], fill=sc)
    d.rectangle([cx-8, cy+16, cx+7, cy+19], fill=sc)
    d.rectangle([cx-4, cy+20, cx+3, cy+22], fill=sc)
    # Highlights
    d.rectangle([cx-14, cy-16, cx+13, cy-14], fill=sl)
    d.rectangle([cx-14, cy-16, cx-12, cy+11], fill=sl)
    # Cross
    d.rectangle([cx-3, cy-10, cx+2, cy+9], fill=green)
    d.rectangle([cx-9, cy-4, cx+8, cy+1], fill=green)
    d.rectangle([cx-2, cy-9, cx+1, cy+8], fill=green_lt)
    d.rectangle([cx-8, cy-3, cx+7, cy], fill=green_lt)
    # Shadow
    d.rectangle([cx-12, cy+10, cx+11, cy+11], fill=sd)
    return img


if __name__ == "__main__":
    base = "/root/home-projects/escape-from-hell/assets/sprites/items"
    icons = {
        "dagger": make_dagger(),
        "slice_and_dice": make_slice_and_dice(),
        "demon_heart": make_demon_heart(),
        "thick_skin": make_thick_skin(),
    }
    for name, img in icons.items():
        img.save(f"{base}/{name}.png")
        print(f"  {name}: 64x64")
    print("Done!")
