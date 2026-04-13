#!/usr/bin/env python3
"""Generate upgrade icon PNGs (64x64 each)."""
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


def make_vitality():
    """Red heart with plus sign."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hc = (204, 26, 38, 255)
    hl = (242, 64, 51, 255)
    # Left lobe
    draw_filled_circle(d, cx - 6, cy - 5, 8, hc)
    # Right lobe
    draw_filled_circle(d, cx + 6, cy - 5, 8, hc)
    # Bottom
    d.rectangle([cx-13, cy-5, cx+12, cy+4], fill=hc)
    d.rectangle([cx-10, cy+5, cx+9, cy+9], fill=hc)
    d.rectangle([cx-6, cy+10, cx+5, cy+13], fill=hc)
    d.rectangle([cx-2, cy+14, cx+1, cy+16], fill=hc)
    # Highlight
    draw_filled_circle(d, cx - 7, cy - 8, 3, hl)
    # Plus sign
    d.rectangle([cx-1, cy-8, cx+1, cy+1], fill=(255, 255, 255, 255))
    d.rectangle([cx-5, cy-5, cx+4, cy-3], fill=(255, 255, 255, 255))
    return img


def make_fury():
    """Flaming sword."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blade = (217, 102, 25, 255)
    blade_lt = (255, 179, 77, 255)
    guard = (140, 51, 25, 255)
    hilt = (102, 38, 20, 255)
    # Blade
    d.rectangle([cx-2, cy-18, cx+1, cy+3], fill=blade)
    d.rectangle([cx, cy-18, cx, cy+3], fill=blade_lt)
    # Tip
    d.rectangle([cx-1, cy-21, cx, cy-18], fill=(255, 153, 38, 255))
    # Crossguard
    d.rectangle([cx-7, cy+4, cx+6, cy+6], fill=guard)
    # Hilt
    d.rectangle([cx-2, cy+7, cx+1, cy+15], fill=hilt)
    # Pommel
    d.rectangle([cx-3, cy+15, cx+2, cy+18], fill=guard)
    # Flame wisps
    draw_filled_circle(d, cx - 4, cy - 14, 3, (255, 128, 0, 128))
    draw_filled_circle(d, cx + 3, cy - 10, 2, (255, 153, 25, 102))
    draw_filled_circle(d, cx - 2, cy - 19, 2, (255, 204, 51, 153))
    return img


def make_iron_skin():
    """Shield with iron cross and rivets."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    sc = (115, 115, 128, 255)
    sl = (153, 153, 173, 255)
    sd = (77, 77, 89, 255)
    # Shield body
    d.rectangle([cx-14, cy-14, cx+13, cy+11], fill=sc)
    d.rectangle([cx-12, cy+12, cx+11, cy+15], fill=sc)
    d.rectangle([cx-8, cy+16, cx+7, cy+18], fill=sc)
    d.rectangle([cx-4, cy+19, cx+3, cy+20], fill=sc)
    # Highlight
    d.rectangle([cx-14, cy-14, cx+13, cy-12], fill=sl)
    d.rectangle([cx-14, cy-14, cx-12, cy+11], fill=sl)
    # Iron cross
    d.rectangle([cx-2, cy-8, cx+1, cy+9], fill=sd)
    d.rectangle([cx-8, cy-2, cx+7, cy+1], fill=sd)
    # Rivets
    for rx, ry in [(cx-10, cy-10), (cx+10, cy-10), (cx-10, cy+8), (cx+10, cy+8)]:
        draw_filled_circle(d, rx, ry, 2, sl)
    return img


def make_blood_pact():
    """Green drop with veins."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    dc = (38, 179, 64, 255)
    dl = (64, 217, 89, 255)
    dv = (20, 115, 31, 255)
    # Drop body
    draw_filled_circle(d, cx, cy + 4, 12, dc)
    d.rectangle([cx-8, cy-4, cx+7, cy+5], fill=dc)
    d.rectangle([cx-5, cy-10, cx+4, cy-3], fill=dc)
    d.rectangle([cx-2, cy-16, cx+1, cy-9], fill=dc)
    d.rectangle([cx, cy-19, cx, cy-15], fill=dc)
    # Highlight
    draw_filled_circle(d, cx - 4, cy + 1, 4, dl)
    # Veins
    d.line([(cx, cy-6), (cx-5, cy+8)], fill=dv, width=1)
    d.line([(cx, cy-6), (cx+4, cy+6)], fill=dv, width=1)
    return img


def make_haste():
    """Winged boot."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    boot = (128, 89, 46, 255)
    sole = (77, 51, 25, 255)
    wing = (204, 204, 230, 255)
    # Boot sole
    d.rectangle([cx-10, cy+10, cx+9, cy+13], fill=sole)
    # Boot body
    d.rectangle([cx-8, cy-4, cx+5, cy+9], fill=boot)
    # Boot top
    d.rectangle([cx-6, cy-14, cx+3, cy-3], fill=boot)
    # Boot toe
    d.rectangle([cx+4, cy+6, cx+11, cy+9], fill=boot)
    # Wing feathers
    for i in range(3):
        fy = cy - 2 + i * 5
        fw = 12 - i * 2
        for t in range(fw):
            px = cx - 8 - t
            py = fy - 4 + i * 2 + int(t * (4 - i * 2) / fw)
            if 0 <= px < S and 0 <= py < S:
                d.point((px, py), fill=wing)
                if py + 1 < S:
                    d.point((px, py + 1), fill=wing)
    # Speed lines
    for i in range(3):
        ly = cy - 8 + i * 8
        d.line([(cx+14, ly), (cx+22, ly)], fill=(255, 230, 77, 128), width=1)
    return img


def make_shadow_step():
    """Dash trail with ghost silhouettes."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Ghost silhouettes (3 fading copies)
    for i in range(3):
        alpha = int((0.15 + i * 0.15) * 255)
        ox = -14 + i * 8
        col = (128, 51, 179, alpha)
        draw_filled_circle(d, cx + ox, cy - 8, 6, col)
        d.rectangle([cx+ox-4, cy-2, cx+ox+3, cy+11], fill=col)
    # Final solid figure
    draw_filled_circle(d, cx + 10, cy - 8, 6, (184, 77, 235, 255))
    d.rectangle([cx+6, cy-2, cx+13, cy+11], fill=(184, 77, 235, 255))
    # Trail swoosh
    d.line([(cx-18, cy+6), (cx+6, cy+6)], fill=(153, 51, 204, 102), width=2)
    d.line([(cx-14, cy+10), (cx+4, cy+10)], fill=(153, 51, 204, 64), width=1)
    return img


def make_frenzy():
    """Crossed swords with speed marks."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    blade = (217, 102, 25, 255)
    guard = (140, 51, 25, 255)

    for angle, ox in [(-0.4, -6), (0.4, 6)]:
        cos_a, sin_a = math.cos(angle), math.sin(angle)
        base_x = cx + ox
        base_y = cy
        # Blade
        for ly in range(-16, 4):
            for lx in range(-1, 2):
                rx = int(base_x + lx * cos_a - ly * sin_a)
                ry = int(base_y + lx * sin_a + ly * cos_a)
                if 0 <= rx < S and 0 <= ry < S:
                    d.point((rx, ry), fill=blade)
        # Guard
        for ly in range(3, 5):
            for lx in range(-4, 4):
                rx = int(base_x + lx * cos_a - ly * sin_a)
                ry = int(base_y + lx * sin_a + ly * cos_a)
                if 0 <= rx < S and 0 <= ry < S:
                    d.point((rx, ry), fill=guard)

    # Speed arcs
    for t in range(10):
        a1 = -2.0 + t * (1.0 / 9)
        px = int(cx + 16 * math.cos(a1))
        py = int(cy - 6 + 16 * math.sin(a1))
        if 0 <= px < S and 0 <= py < S:
            d.point((px, py), fill=(255, 179, 51, 153))
    # Impact spark
    draw_filled_circle(d, cx, cy - 12, 2, (255, 230, 77, 179))
    return img


def make_soul_shield():
    """Glowing spirit orb with shield ring."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Outer glow
    draw_filled_circle(d, cx, cy, 18, (255, 191, 25, 31))
    draw_filled_circle(d, cx, cy, 14, (255, 191, 25, 51))
    # Main orb
    draw_filled_circle(d, cx, cy, 10, (255, 191, 25, 153))
    # Inner bright core
    draw_filled_circle(d, cx, cy, 5, (255, 230, 128, 217))
    draw_filled_circle(d, cx, cy, 2, (255, 255, 230, 255))
    # Spirit wisps
    for i in range(4):
        angle = i * math.pi / 2.0 + 0.3
        wx = int(cx + 14 * math.cos(angle))
        wy = int(cy + 14 * math.sin(angle))
        draw_filled_circle(d, wx, wy, 2, (255, 217, 77, 102))
    # Shield ring
    for t in range(32):
        angle = t * math.pi * 2 / 32
        rx = int(cx + 16 * math.cos(angle))
        ry = int(cy + 16 * math.sin(angle))
        if 0 <= rx < S and 0 <= ry < S:
            d.point((rx, ry), fill=(255, 204, 51, 89))
    return img


if __name__ == "__main__":
    base = "/root/home-projects/escape-from-hell/assets/sprites/upgrades"
    icons = {
        "max_health": make_vitality(),
        "attack_up": make_fury(),
        "armor_up": make_iron_skin(),
        "regen_up": make_blood_pact(),
        "speed_up": make_haste(),
        "dash_up": make_shadow_step(),
        "attack_speed": make_frenzy(),
        "iframes_up": make_soul_shield(),
    }
    for name, img in icons.items():
        img.save(f"{base}/{name}.png")
        print(f"  {name}: 64x64")
    print("Done!")
