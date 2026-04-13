#!/usr/bin/env python3
"""Generate enemy spritesheets from the procedural draw code in EnemyArenaSprite.gd."""
import json, math
from PIL import Image, ImageDraw

# ── Shared helpers ──

def clamp_color(c):
    return tuple(max(0, min(255, int(v))) for v in c)

def darken(color, amount):
    return clamp_color(tuple(int(c * (1 - amount)) for c in color[:3]) + (color[3] if len(color) > 3 else (),))

def lighten(color, amount):
    return clamp_color(tuple(int(c + (255 - c) * amount) for c in color[:3]) + (color[3] if len(color) > 3 else (),))

def color_f(r, g, b, a=1.0):
    """Convert Godot Color(float) to PIL tuple."""
    return (int(r*255), int(g*255), int(b*255), int(a*255))

def draw_filled_circle(draw, cx, cy, r, color, W, H):
    for dy in range(-r, r+1):
        for dx in range(-r, r+1):
            if dx*dx + dy*dy <= r*r:
                px, py = cx + dx, cy + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=color)


class EnemySprite:
    def __init__(self, name, W, H, cx, cy, palette):
        self.name = name
        self.W = W
        self.H = H
        self.cx = cx
        self.cy = cy
        self.p = palette

    def dr(self, draw, x, y, w, h, color, oy=0, lo_add=0):
        """Draw rect in local coords."""
        px = self.cx + x
        py = self.cy + y + oy + lo_add
        draw.rectangle([px, py, px + w - 1, py + h - 1], fill=color)

    def dc(self, draw, x, y, r, color, oy=0):
        """Draw filled circle in local coords."""
        draw_filled_circle(draw, self.cx + x, self.cy + y + oy, r, color, self.W, self.H)

    def dl(self, draw, x1, y1, x2, y2, color, thickness=1, oy=0):
        """Draw line in local coords."""
        draw.line([(self.cx + x1, self.cy + y1 + oy), (self.cx + x2, self.cy + y2 + oy)],
                  fill=color, width=thickness)

    def make_frame(self, draw_func, oy=0, lo=0, cast=0.0):
        img = Image.new('RGBA', (self.W, self.H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw_func(draw, oy=oy, lo=lo, cast=cast)
        return img

    def tint_red(self, img, factor=0.7):
        pixels = img.load()
        for y in range(img.height):
            for x in range(img.width):
                r, g, b, a = pixels[x, y]
                if a > 0:
                    r = int(r + (255 - r) * factor)
                    g = int(g * (1 - factor))
                    b = int(b * (1 - factor))
                    pixels[x, y] = (min(255, r), g, b, a)
        return img

    def fade(self, img, alpha_mult=0.5, tint=0.3):
        pixels = img.load()
        for y in range(img.height):
            for x in range(img.width):
                r, g, b, a = pixels[x, y]
                if a > 0:
                    r = int(r + (255 - r) * tint)
                    g = int(g * (1 - tint) + 38 * tint)
                    b = int(b * (1 - tint) + 25 * tint)
                    a = int(a * alpha_mult)
                    pixels[x, y] = (min(255, r), g, b, a)
        return img


# ══════════════════════════════════════════════════════════════════
# DEMON
# ══════════════════════════════════════════════════════════════════
DEMON_PAL = {
    "body": color_f(0.55, 0.08, 0.08), "body_dk": color_f(0.38, 0.04, 0.04),
    "body_lt": color_f(0.72, 0.15, 0.10), "skin": color_f(0.70, 0.30, 0.25),
    "horn": color_f(0.25, 0.12, 0.08), "eye": color_f(1.0, 0.85, 0.0),
    "accent": color_f(0.90, 0.30, 0.05),
}

def make_demon():
    s = EnemySprite("demon", 50, 60, 25, 32, DEMON_PAL)
    p = s.p

    def front(draw, oy=0, lo=0, cast=0.0):
        # Arms behind
        s.dr(draw, -15, -3, 5, 14, p["body"], oy)
        s.dr(draw, 10, -3, 5, 14, p["body"], oy)
        s.dr(draw, -16, 10, 3, 4, p["accent"], oy)
        s.dr(draw, -13, 10, 3, 4, p["accent"], oy)
        s.dr(draw, 11, 10, 3, 4, p["accent"], oy)
        s.dr(draw, 14, 10, 3, 4, p["accent"], oy)
        # Legs
        s.dr(draw, -7, 10, 6, 8, p["body_dk"], oy, lo)
        s.dr(draw, 1, 10, 6, 8, p["body_dk"], oy, -lo)
        s.dr(draw, -8, 16, 8, 4, p["horn"], oy, lo)
        s.dr(draw, 0, 16, 8, 4, p["horn"], oy, -lo)
        # Torso
        s.dr(draw, -10, -6, 20, 16, p["body"], oy)
        s.dr(draw, -8, -4, 7, 6, p["body_lt"], oy)
        s.dr(draw, 1, -4, 7, 6, p["body_lt"], oy)
        s.dl(draw, -3, oy, 4, 5+oy, p["skin"], 1, 0)
        # Head
        s.dc(draw, 0, -12, 9, p["body"], oy)
        s.dr(draw, -8, -16, 16, 3, p["body_dk"], oy)
        s.dr(draw, -5, -14, 4, 3, p["eye"], oy)
        s.dr(draw, 1, -14, 4, 3, p["eye"], oy)
        s.dr(draw, -4, -7, 8, 2, p["body_dk"], oy)
        s.dr(draw, -3, -6, 2, 2, (255,255,255,255), oy)
        s.dr(draw, 1, -6, 2, 2, (255,255,255,255), oy)
        # Horns
        s.dr(draw, -11, -20, 4, 8, p["horn"], oy)
        s.dr(draw, -13, -22, 3, 4, p["horn"], oy)
        s.dr(draw, 7, -20, 4, 8, p["horn"], oy)
        s.dr(draw, 10, -22, 3, 4, p["horn"], oy)

    def back(draw, oy=0, lo=0, cast=0.0):
        s.dr(draw, -7, 10, 6, 8, p["body_dk"], oy, lo)
        s.dr(draw, 1, 10, 6, 8, p["body_dk"], oy, -lo)
        s.dr(draw, -8, 16, 8, 4, p["horn"], oy, lo)
        s.dr(draw, 0, 16, 8, 4, p["horn"], oy, -lo)
        s.dr(draw, -10, -6, 20, 16, p["body_dk"], oy)
        s.dl(draw, 0, -4+oy, 0, 8+oy, darken(p["body"], 0.3), 1, 0)
        s.dr(draw, -15, -3, 5, 14, p["body"], oy)
        s.dr(draw, 10, -3, 5, 14, p["body"], oy)
        s.dc(draw, 0, -12, 9, p["body"], oy)
        s.dr(draw, -11, -20, 4, 8, p["horn"], oy)
        s.dr(draw, -13, -22, 3, 4, p["horn"], oy)
        s.dr(draw, 7, -20, 4, 8, p["horn"], oy)
        s.dr(draw, 10, -22, 3, 4, p["horn"], oy)

    def side(draw, oy=0, lo=0, cast=0.0):
        s.dr(draw, -8, -3, 4, 12, p["body_dk"], oy)
        s.dr(draw, -9, 8, 2, 3, darken(p["accent"], 0.2), oy)
        s.dr(draw, -3, 10, 6, 8, darken(p["body_dk"], 0.15), oy, -lo)
        s.dr(draw, -4, 16, 8, 4, darken(p["horn"], 0.1), oy, -lo)
        s.dr(draw, -3, 10, 6, 8, p["body_dk"], oy, lo)
        s.dr(draw, -4, 16, 8, 4, p["horn"], oy, lo)
        s.dr(draw, -5, -6, 5, 16, p["body_dk"], oy)
        s.dr(draw, 0, -6, 6, 16, p["body"], oy)
        s.dr(draw, 1, -4, 4, 6, p["body_lt"], oy)
        s.dr(draw, 5, -3, 5, 14, p["body"], oy)
        s.dr(draw, 7, 10, 2, 3, p["accent"], oy)
        s.dr(draw, 10, 10, 2, 3, p["accent"], oy)
        s.dc(draw, 1, -12, 8, p["body"], oy)
        s.dc(draw, -2, -12, 6, darken(p["body_dk"], 0), oy)
        s.dc(draw, 3, -13, 6, p["body_lt"], oy)
        s.dr(draw, 4, -14, 5, 4, p["eye"], oy)
        s.dr(draw, 1, -16, 8, 3, p["body_dk"], oy)
        s.dr(draw, 5, -8, 5, 2, p["body_dk"], oy)
        s.dr(draw, 7, -7, 2, 3, (255,255,255,255), oy)
        s.dr(draw, 3, -20, 4, 8, p["horn"], oy)
        s.dr(draw, 5, -23, 3, 5, p["horn"], oy)

    return s, front, back, side


# ══════════════════════════════════════════════════════════════════
# IMP
# ══════════════════════════════════════════════════════════════════
IMP_PAL = {
    "body": color_f(0.45, 0.18, 0.50), "body_dk": color_f(0.30, 0.10, 0.35),
    "body_lt": color_f(0.60, 0.28, 0.65), "skin": color_f(0.55, 0.35, 0.55),
    "horn": color_f(0.20, 0.10, 0.15), "eye": color_f(0.0, 1.0, 0.4),
    "accent": color_f(0.80, 0.20, 0.70),
}

def make_imp():
    s = EnemySprite("imp", 48, 55, 24, 30, IMP_PAL)
    p = s.p

    def front(draw, oy=0, lo=0, cast=0.0):
        # Tail
        s.dl(draw, 6, 6+oy, 18, -2+oy, p["body_dk"], 2, 0)
        s.dl(draw, 18, -2+oy, 20, -6+oy, p["accent"], 1, 0)
        # Wings
        wc = p["body_dk"]
        s.dl(draw, -7, -10+oy, -18, -22+oy, wc, 2, 0)
        s.dl(draw, -18, -22+oy, -13, -12+oy, wc, 1, 0)
        s.dl(draw, 7, -10+oy, 18, -22+oy, wc, 2, 0)
        s.dl(draw, 18, -22+oy, 13, -12+oy, wc, 1, 0)
        # Legs
        s.dr(draw, -6, 10, 5, 7, p["body_dk"], oy, lo)
        s.dr(draw, 1, 10, 5, 7, p["body_dk"], oy, -lo)
        s.dr(draw, -7, 15, 7, 3, p["horn"], oy, lo)
        s.dr(draw, 0, 15, 7, 3, p["horn"], oy, -lo)
        # Body
        s.dr(draw, -8, -5, 16, 16, p["body"], oy)
        s.dr(draw, -5, 0, 10, 8, p["body_lt"], oy)
        # Arms
        s.dr(draw, -13, -3, 5, 12, p["body"], oy)
        s.dr(draw, 8, -3, 5, 12, p["body"], oy)
        s.dr(draw, -14, 8, 2, 3, p["accent"], oy)
        s.dr(draw, -12, 8, 2, 3, p["accent"], oy)
        s.dr(draw, 10, 8, 2, 3, p["accent"], oy)
        s.dr(draw, 12, 8, 2, 3, p["accent"], oy)
        # Head
        s.dc(draw, 0, -11, 9, p["body"], oy)
        s.dr(draw, -6, -15, 5, 4, (0,0,0,255), oy)
        s.dr(draw, 1, -15, 5, 4, (0,0,0,255), oy)
        s.dr(draw, -5, -14, 3, 3, p["eye"], oy)
        s.dr(draw, 2, -14, 3, 3, p["eye"], oy)
        s.dr(draw, -4, -6, 8, 1, p["body_dk"], oy)
        s.dr(draw, -3, -6, 2, 2, (255,255,255,255), oy)
        s.dr(draw, 1, -6, 2, 2, (255,255,255,255), oy)
        s.dr(draw, -8, -19, 3, 6, p["horn"], oy)
        s.dr(draw, 5, -19, 3, 6, p["horn"], oy)
        s.dr(draw, -11, -14, 4, 3, p["body_lt"], oy)
        s.dr(draw, 7, -14, 4, 3, p["body_lt"], oy)

    def back(draw, oy=0, lo=0, cast=0.0):
        s.dl(draw, 0, 6+oy, 14, -2+oy, p["body_dk"], 2, 0)
        wc = p["body_dk"]
        s.dl(draw, -6, -10+oy, -18, -24+oy, wc, 2, 0)
        s.dl(draw, -18, -24+oy, -12, -12+oy, wc, 2, 0)
        s.dl(draw, 6, -10+oy, 18, -24+oy, wc, 2, 0)
        s.dl(draw, 18, -24+oy, 12, -12+oy, wc, 2, 0)
        s.dr(draw, -6, 10, 5, 7, p["body_dk"], oy, lo)
        s.dr(draw, 1, 10, 5, 7, p["body_dk"], oy, -lo)
        s.dr(draw, -7, 15, 7, 3, p["horn"], oy, lo)
        s.dr(draw, 0, 15, 7, 3, p["horn"], oy, -lo)
        s.dr(draw, -8, -5, 16, 16, p["body_dk"], oy)
        s.dr(draw, -13, -3, 5, 12, p["body"], oy)
        s.dr(draw, 8, -3, 5, 12, p["body"], oy)
        s.dc(draw, 0, -11, 9, p["body"], oy)
        s.dr(draw, -8, -19, 3, 6, p["horn"], oy)
        s.dr(draw, 5, -19, 3, 6, p["horn"], oy)

    def side(draw, oy=0, lo=0, cast=0.0):
        s.dl(draw, -4, 4+oy, -14, -4+oy, p["body_dk"], 2, 0)
        s.dl(draw, -14, -4+oy, -16, -7+oy, p["accent"], 1, 0)
        wc = p["body_dk"]
        s.dl(draw, -2, -10+oy, -12, -24+oy, wc, 2, 0)
        s.dl(draw, -12, -24+oy, -7, -12+oy, wc, 2, 0)
        s.dr(draw, -3, 10, 5, 7, darken(p["body_dk"], 0.15), oy, -lo)
        s.dr(draw, -4, 15, 7, 3, darken(p["horn"], 0.1), oy, -lo)
        s.dr(draw, -3, 10, 5, 7, p["body_dk"], oy, lo)
        s.dr(draw, -4, 15, 7, 3, p["horn"], oy, lo)
        s.dr(draw, -7, -3, 4, 10, p["body_dk"], oy)
        s.dr(draw, -4, -5, 5, 16, p["body_dk"], oy)
        s.dr(draw, 1, -5, 6, 16, p["body"], oy)
        s.dr(draw, 2, 0, 4, 8, p["body_lt"], oy)
        s.dr(draw, 5, -3, 5, 12, p["body_lt"], oy)
        s.dr(draw, 7, 8, 2, 3, p["accent"], oy)
        s.dr(draw, 9, 8, 2, 3, p["accent"], oy)
        s.dc(draw, 1, -11, 8, p["body"], oy)
        s.dc(draw, -2, -11, 6, p["body_dk"], oy)
        s.dc(draw, 3, -12, 6, p["body_lt"], oy)
        s.dr(draw, 3, -15, 5, 4, (0,0,0,255), oy)
        s.dr(draw, 4, -14, 3, 3, p["eye"], oy)
        s.dr(draw, 5, -7, 4, 1, p["body_dk"], oy)
        s.dr(draw, 6, -7, 2, 2, (255,255,255,255), oy)
        s.dr(draw, 3, -19, 3, 6, p["horn"], oy)
        s.dr(draw, 8, -14, 4, 3, p["body_lt"], oy)

    return s, front, back, side


# ══════════════════════════════════════════════════════════════════
# HELLHOUND
# ══════════════════════════════════════════════════════════════════
HOUND_PAL = {
    "body": color_f(0.20, 0.20, 0.22), "body_dk": color_f(0.10, 0.10, 0.12),
    "body_lt": color_f(0.35, 0.30, 0.28), "skin": color_f(0.30, 0.22, 0.18),
    "horn": color_f(0.12, 0.08, 0.06), "eye": color_f(1.0, 0.25, 0.0),
    "accent": color_f(0.90, 0.45, 0.05),
}

def make_hellhound():
    s = EnemySprite("hellhound", 56, 50, 28, 25, HOUND_PAL)
    p = s.p

    def front(draw, oy=0, lo=0, cast=0.0):
        # 4 legs
        s.dr(draw, -12, 4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, -6, 4, 5, 12, p["body_dk"], oy, -lo)
        s.dr(draw, 1, 4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, 7, 4, 5, 12, p["body_dk"], oy, -lo)
        s.dr(draw, -13, 14, 7, 4, p["horn"], oy, lo)
        s.dr(draw, -7, 14, 7, 4, p["horn"], oy, -lo)
        s.dr(draw, 0, 14, 7, 4, p["horn"], oy, lo)
        s.dr(draw, 6, 14, 7, 4, p["horn"], oy, -lo)
        # Body
        s.dr(draw, -10, -8, 20, 14, p["body"], oy)
        # Mane
        mc = p["accent"]
        s.dr(draw, -7, -14, 3, 6, mc, oy)
        s.dr(draw, -3, -15, 3, 7, mc, oy)
        s.dr(draw, 1, -15, 3, 7, mc, oy)
        s.dr(draw, 5, -14, 3, 6, mc, oy)
        # Head
        s.dr(draw, -8, -10, 16, 10, p["body"], oy)
        s.dr(draw, -4, -3, 8, 5, p["body_lt"], oy)
        s.dr(draw, -2, -3, 4, 2, p["horn"], oy)
        s.dr(draw, -7, -9, 4, 3, p["eye"], oy)
        s.dr(draw, 3, -9, 4, 3, p["eye"], oy)
        s.dr(draw, -3, 0, 6, 2, p["body_dk"], oy)
        s.dr(draw, -2, 1, 2, 2, (255,255,255,255), oy)
        s.dr(draw, 1, 1, 2, 2, (255,255,255,255), oy)
        s.dr(draw, -10, -14, 4, 6, p["body_dk"], oy)
        s.dr(draw, 6, -14, 4, 6, p["body_dk"], oy)

    def back(draw, oy=0, lo=0, cast=0.0):
        s.dl(draw, 0, -6+oy, 0, -16+oy, p["body"], 3, 0)
        s.dl(draw, 0, -16+oy, 0, -20+oy, p["accent"], 2, 0)
        s.dr(draw, -12, 4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, -6, 4, 5, 12, p["body_dk"], oy, -lo)
        s.dr(draw, 1, 4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, 7, 4, 5, 12, p["body_dk"], oy, -lo)
        s.dr(draw, -13, 14, 7, 4, p["horn"], oy, lo)
        s.dr(draw, 6, 14, 7, 4, p["horn"], oy, -lo)
        s.dr(draw, -10, -8, 20, 14, p["body_dk"], oy)
        s.dr(draw, -1, -8, 2, 14, p["body_lt"], oy)
        mc = p["accent"]
        s.dr(draw, -5, -14, 10, 6, mc, oy)
        s.dr(draw, -8, -10, 16, 6, p["body"], oy)
        s.dr(draw, -10, -12, 4, 4, p["body_dk"], oy)
        s.dr(draw, 6, -12, 4, 4, p["body_dk"], oy)

    def side(draw, oy=0, lo=0, cast=0.0):
        # Tail
        s.dl(draw, 14, -6+oy, 22, -14+oy, p["body"], 3, 0)
        s.dl(draw, 22, -14+oy, 24, -18+oy, p["accent"], 2, 0)
        # Back legs
        s.dr(draw, 8, 4, 5, 12, darken(p["body_dk"], 0.2), oy, -lo)
        s.dr(draw, 12, 4, 4, 12, darken(p["body_dk"], 0.15), oy, lo)
        s.dr(draw, 7, 14, 7, 4, darken(p["horn"], 0.1), oy, -lo)
        # Front legs
        s.dr(draw, -14, 4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, -10, 4, 5, 12, darken(p["body_dk"], 0.1), oy, -lo)
        s.dr(draw, -15, 14, 7, 4, p["horn"], oy, lo)
        s.dr(draw, -11, 14, 7, 4, p["horn"], oy, -lo)
        # Body
        s.dr(draw, -12, -8, 28, 7, p["body_lt"], oy)
        s.dr(draw, -12, -1, 28, 7, p["body"], oy)
        s.dr(draw, -10, 4, 24, 2, p["body_dk"], oy)
        s.dr(draw, -10, -10, 24, 3, p["body_lt"], oy)
        # Mane
        mc = p["accent"]
        s.dr(draw, -12, -14, 4, 6, mc, oy)
        s.dr(draw, -8, -15, 3, 7, mc, oy)
        s.dr(draw, -5, -14, 3, 6, mc, oy)
        flame = color_f(1.0, 0.6, 0.0)
        s.dr(draw, -11, -16, 3, 4, flame, oy)
        # Head
        s.dr(draw, -16, -10, 10, 10, p["body"], oy)
        s.dr(draw, -22, -8, 8, 8, p["body_lt"], oy)
        s.dr(draw, -22, -7, 3, 3, p["horn"], oy)
        s.dr(draw, -21, -1, 7, 3, p["body_dk"], oy)
        s.dr(draw, -20, -1, 2, 2, (255,255,255,255), oy)
        s.dr(draw, -17, -1, 2, 2, (255,255,255,255), oy)
        s.dr(draw, -15, -9, 4, 3, p["eye"], oy)
        s.dr(draw, -18, -14, 3, 6, p["body"], oy)
        s.dr(draw, -14, -13, 3, 4, p["body_dk"], oy)

    return s, front, back, side


# ══════════════════════════════════════════════════════════════════
# WARLOCK
# ══════════════════════════════════════════════════════════════════
WARLOCK_PAL = {
    "body": color_f(0.18, 0.08, 0.28), "body_dk": color_f(0.10, 0.04, 0.18),
    "body_lt": color_f(0.30, 0.14, 0.42), "skin": color_f(0.45, 0.32, 0.40),
    "horn": color_f(0.22, 0.10, 0.30), "eye": color_f(0.7, 0.3, 1.0),
    "accent": color_f(0.75, 0.25, 0.95),
}

def make_warlock():
    s = EnemySprite("warlock", 40, 70, 20, 40, WARLOCK_PAL)
    p = s.p

    def _draw_staff(draw, sx, oy, cast):
        """Draw staff with purple fire."""
        thrust = int(cast * 5)
        soy = oy - thrust
        # Staff shaft
        s.dr(draw, sx-1, -22, 2, 28, p["horn"], soy)
        # Forked head
        s.dr(draw, sx-3, -25, 2, 4, p["horn"], soy)
        s.dr(draw, sx+1, -25, 2, 4, p["horn"], soy)
        # Purple fire
        fs = 1.0 + cast * 1.2
        fa = max(60, int((0.5 + cast * 0.5) * 255))
        r_fire = max(2, int(3.5 * fs))
        fire_color = (128, 25, 204, fa)
        fire_inner = (153, 51, 229, min(255, fa + 76))
        fire_core = (191, 102, 255, min(255, fa + 102))
        draw_filled_circle(draw, s.cx + sx, s.cy - 25 + soy, r_fire, fire_color, s.W, s.H)
        draw_filled_circle(draw, s.cx + sx, s.cy - 26 + soy, max(1, int(2.5*fs)), fire_inner, s.W, s.H)
        draw_filled_circle(draw, s.cx + sx, s.cy - 27 + soy, max(1, int(1.5*fs)), fire_core, s.W, s.H)

    def front(draw, oy=0, lo=0, cast=0.0):
        # Robe bottom (simplified as trapezoid-ish rectangle)
        s.dr(draw, -12, 16, 23, 2, p["body_lt"], oy)
        s.dr(draw, -10, 5, 20, 13, p["body"], oy)
        s.dr(draw, 1, 5, 10, 13, p["body_dk"], oy)
        # Robe hem embers
        s.dr(draw, -9, 17, 3, 1, (140, 50, 180, 150), oy)
        s.dr(draw, 3, 17, 3, 1, (140, 50, 180, 120), oy)
        # Torso
        s.dr(draw, -8, -6, 16, 12, p["body"], oy)
        # Arms
        s.dr(draw, -13, -4, 5, 12, p["body_lt"], oy, lo)
        s.dr(draw, 8, -4, 5, 12, p["body"], oy, -lo)
        # Hand glow
        s.dc(draw, -10, 9, 3, (128, 25, 204, 76), oy)
        s.dc(draw, -10, 9, 2, lighten(p["accent"], 0.2), oy)
        s.dc(draw, 11, 9, 3, (128, 25, 204, 76), oy)
        s.dc(draw, 11, 9, 2, lighten(p["accent"], 0.2), oy)
        # Staff
        _draw_staff(draw, 0, oy, cast)
        # Head (hooded)
        s.dc(draw, 0, -12, 8, p["body"], oy)
        # Face shadow
        s.dc(draw, 0, -11, 5, (8, 3, 8, 255), oy)
        # Eyes
        s.dr(draw, -4, -13, 3, 2, p["eye"], oy)
        s.dr(draw, 1, -13, 3, 2, p["eye"], oy)
        s.dc(draw, -2, -12, 2, (128, 38, 204, 89), oy)
        s.dc(draw, 2, -12, 2, (128, 38, 204, 89), oy)

    def back(draw, oy=0, lo=0, cast=0.0):
        s.dr(draw, -10, 5, 20, 13, p["body_dk"], oy)
        s.dr(draw, -11, 16, 23, 2, p["body"], oy)
        s.dr(draw, -8, -6, 16, 12, p["body_dk"], oy)
        s.dr(draw, -13, -4, 5, 12, p["body_dk"], oy, lo)
        s.dr(draw, 8, -4, 5, 12, p["body_dk"], oy, -lo)
        _draw_staff(draw, 0, oy, cast)
        s.dc(draw, 0, -12, 8, p["body_dk"], oy)

    def side(draw, oy=0, lo=0, cast=0.0):
        s.dr(draw, -8, 5, 16, 13, p["body"], oy)
        s.dr(draw, 1, 5, 6, 13, p["body_dk"], oy)
        s.dr(draw, -7, 16, 16, 2, p["body_lt"], oy)
        s.dr(draw, -5, -6, 10, 12, p["body"], oy)
        s.dr(draw, 1, -6, 4, 12, p["body_dk"], oy)
        s.dr(draw, 5, -4, 5, 12, p["body"], oy)
        s.dc(draw, 8, 9, 2, (128, 25, 204, 76), oy)
        s.dc(draw, 8, 9, 1, lighten(p["accent"], 0.2), oy)
        s.dr(draw, -8, -3, 4, 10, p["body_dk"], oy)
        _draw_staff(draw, 7, oy, cast)
        s.dc(draw, 0, -12, 7, p["body"], oy)
        s.dc(draw, 2, -12, 5, p["body_dk"], oy)
        s.dc(draw, -1, -11, 4, (8, 3, 8, 255), oy)
        s.dr(draw, -4, -13, 3, 2, p["eye"], oy)
        s.dc(draw, -2, -12, 2, (128, 38, 204, 89), oy)

    return s, front, back, side


# ══════════════════════════════════════════════════════════════════
# ABOMINATION
# ══════════════════════════════════════════════════════════════════
ABOM_PAL = {
    "body": color_f(0.55, 0.12, 0.12), "body_dk": color_f(0.35, 0.06, 0.06),
    "body_lt": color_f(0.70, 0.20, 0.18), "skin": color_f(0.75, 0.30, 0.28),
    "horn": color_f(0.25, 0.10, 0.08), "eye": color_f(1.0, 0.9, 0.0),
    "accent": color_f(0.90, 0.15, 0.10),
}

def make_abomination():
    s = EnemySprite("abomination", 80, 80, 40, 40, ABOM_PAL)
    p = s.p
    teeth_c = (234, 224, 191, 255)
    guts_c = (115, 20, 31, 255)
    vein_c = (178, 38, 25, 178)

    def front(draw, oy=0, lo=0, cast=0.0):
        ilo = int(lo)
        # Tendrils
        s.dl(draw, -18, 8+oy, -28, 22+oy, guts_c, 2, 0)
        s.dl(draw, 18, 8+oy, 28, 24+oy, guts_c, 2, 0)
        # 8 legs
        s.dr(draw, -22, 16, 6, 12, p["body_dk"], oy, ilo)
        s.dr(draw, -15, 18, 5, 11, p["body"], oy, -ilo)
        s.dr(draw, -9, 20, 5, 9, darken(p["body_dk"],0.15), oy, int(lo*0.7))
        s.dr(draw, -3, 19, 4, 10, p["body"], oy, -int(lo*0.5))
        s.dr(draw, 3, 20, 4, 9, p["body_dk"], oy, int(lo*0.7))
        s.dr(draw, 9, 18, 5, 11, p["body"], oy, -ilo)
        s.dr(draw, 15, 16, 5, 12, p["body_dk"], oy, ilo)
        s.dr(draw, 21, 19, 5, 10, darken(p["body_dk"],0.2), oy, -int(lo*0.5))
        # Feet
        s.dr(draw, -23, 26, 9, 4, p["horn"], oy, ilo)
        s.dr(draw, -16, 27, 7, 4, p["horn"], oy, -ilo)
        s.dr(draw, -10, 27, 7, 4, p["horn"], oy, int(lo*0.7))
        s.dr(draw, 8, 27, 7, 4, p["horn"], oy, -ilo)
        s.dr(draw, 14, 26, 7, 4, p["horn"], oy, ilo)
        s.dr(draw, 20, 27, 8, 4, p["horn"], oy, -int(lo*0.5))
        # Central mass
        s.dc(draw, 0, 6, 24, p["body"], oy)
        s.dc(draw, -10, 0, 16, p["body_dk"], oy)
        s.dc(draw, 10, 0, 16, p["body_dk"], oy)
        s.dc(draw, 0, 12, 18, p["body_lt"], oy)
        # Boils
        s.dc(draw, -14, 8, 5, lighten(p["body_lt"], 0.15), oy)
        s.dc(draw, 16, 4, 4, lighten(p["body_lt"], 0.1), oy)
        # Seams
        s.dl(draw, -6, -14+oy, -12, 18+oy, p["accent"], 2, 0)
        s.dl(draw, 6, -14+oy, 12, 18+oy, p["accent"], 2, 0)
        s.dl(draw, -16, 4+oy, 16, 4+oy, p["accent"], 1, 0)
        # Veins
        s.dl(draw, -8, -4+oy, -18, 10+oy, vein_c, 1, 0)
        s.dl(draw, 8, -4+oy, 20, 8+oy, vein_c, 1, 0)
        # Belly mouth
        s.dr(draw, -8, 8, 16, 6, guts_c, oy)
        for tx in range(-7, 8, 3):
            s.dr(draw, tx, 7, 2, 3, teeth_c, oy)
            s.dr(draw, tx, 12, 2, 3, teeth_c, oy)
        # 6 arms
        s.dr(draw, -28, -10, 8, 6, p["skin"], oy)
        s.dr(draw, -34, -12, 7, 5, p["skin"], oy)
        s.dr(draw, -36, -14, 2, 3, p["accent"], oy)
        s.dr(draw, -26, 2, 7, 5, darken(p["skin"], 0.1), oy)
        s.dr(draw, -30, 6, 5, 8, darken(p["skin"], 0.1), oy)
        s.dr(draw, 20, -12, 8, 6, p["skin"], oy)
        s.dr(draw, 26, -16, 6, 7, p["skin"], oy)
        s.dr(draw, 22, 0, 10, 5, darken(p["skin"], 0.15), oy)
        s.dr(draw, -5, -22, 6, 10, p["skin"], oy)
        s.dr(draw, -6, -30, 5, 9, p["skin"], oy)
        # Main head
        s.dc(draw, 0, -14, 12, p["body"], oy)
        s.dr(draw, -9, -19, 18, 4, p["body_dk"], oy)
        s.dr(draw, -7, -17, 4, 4, p["eye"], oy)
        s.dr(draw, 3, -17, 4, 4, p["eye"], oy)
        s.dr(draw, -2, -20, 3, 3, lighten(p["eye"], 0.2), oy)
        s.dr(draw, -6, -7, 12, 4, p["body_dk"], oy)
        for tx in range(-5, 6, 2):
            s.dr(draw, tx, -8, 2, 3, teeth_c, oy)
            s.dr(draw, tx, -5, 2, 3, teeth_c, oy)
        # Second head
        s.dc(draw, -18, -10, 8, p["body_lt"], oy)
        s.dr(draw, -22, -13, 3, 3, p["eye"], oy)
        s.dr(draw, -17, -13, 3, 3, p["eye"], oy)
        # Third head
        s.dc(draw, 16, 0, 7, p["body"], oy)
        s.dr(draw, 13, -1, 3, 2, p["eye"], oy)
        s.dr(draw, 17, -1, 3, 2, p["eye"], oy)
        # Fourth head
        s.dc(draw, 10, -18, 5, p["body_dk"], oy)
        s.dr(draw, 8, -20, 2, 2, p["eye"], oy)
        s.dr(draw, 11, -20, 2, 2, p["eye"], oy)
        # Horns
        s.dr(draw, -12, -24, 4, 8, p["horn"], oy)
        s.dr(draw, -13, -28, 3, 5, lighten(p["horn"], 0.1), oy)
        s.dr(draw, 8, -24, 4, 8, p["horn"], oy)
        s.dr(draw, 10, -28, 3, 5, lighten(p["horn"], 0.1), oy)

    def back(draw, oy=0, lo=0, cast=0.0):
        ilo = int(lo)
        s.dr(draw, -22, 16, 6, 12, p["body_dk"], oy, ilo)
        s.dr(draw, -15, 18, 5, 11, p["body_dk"], oy, -ilo)
        s.dr(draw, 9, 18, 5, 11, p["body_dk"], oy, -ilo)
        s.dr(draw, 15, 16, 5, 12, p["body_dk"], oy, ilo)
        s.dr(draw, -23, 26, 9, 4, p["horn"], oy, ilo)
        s.dr(draw, 14, 26, 7, 4, p["horn"], oy, ilo)
        s.dc(draw, 0, 6, 24, p["body_dk"], oy)
        s.dc(draw, -10, 0, 16, darken(p["body_dk"], 0.1), oy)
        s.dc(draw, 10, 0, 16, darken(p["body_dk"], 0.1), oy)
        s.dl(draw, 0, -14+oy, 0, 20+oy, p["accent"], 3, 0)
        s.dl(draw, -4, -10+oy, -4, 16+oy, p["accent"], 1, 0)
        s.dl(draw, 4, -10+oy, 4, 16+oy, p["accent"], 1, 0)
        s.dc(draw, -8, 4, 4, guts_c, oy)
        s.dc(draw, 10, 12, 3, guts_c, oy)
        s.dr(draw, -28, -10, 8, 6, p["skin"], oy)
        s.dr(draw, 20, -12, 8, 6, p["skin"], oy)
        s.dr(draw, -5, -22, 6, 10, p["skin"], oy)
        s.dc(draw, 0, -14, 12, p["body_dk"], oy)
        s.dc(draw, -18, -10, 8, p["body_dk"], oy)
        s.dc(draw, 16, 0, 7, p["body_dk"], oy)
        s.dc(draw, 10, -18, 5, darken(p["body_dk"], 0.1), oy)
        s.dr(draw, -12, -24, 4, 8, p["horn"], oy)
        s.dr(draw, -13, -28, 3, 5, p["horn"], oy)
        s.dr(draw, 8, -24, 4, 8, p["horn"], oy)
        s.dr(draw, 10, -28, 3, 5, p["horn"], oy)

    def side(draw, oy=0, lo=0, cast=0.0):
        ilo = int(lo)
        s.dr(draw, 8, 16, 6, 12, darken(p["body_dk"],0.2), oy, -ilo)
        s.dr(draw, 14, 18, 5, 11, darken(p["body_dk"],0.15), oy, ilo)
        s.dr(draw, -20, 16, 6, 12, p["body_dk"], oy, ilo)
        s.dr(draw, -13, 18, 5, 11, p["body"], oy, -ilo)
        s.dr(draw, -7, 20, 5, 9, p["body_dk"], oy, int(lo*0.7))
        s.dr(draw, -21, 26, 9, 4, p["horn"], oy, ilo)
        s.dr(draw, -14, 27, 7, 4, p["horn"], oy, -ilo)
        s.dl(draw, -8, 14+oy, -14, 28+oy, guts_c, 2, 0)
        s.dc(draw, 0, 6, 22, p["body"], oy)
        s.dc(draw, -8, 0, 14, p["body_dk"], oy)
        s.dc(draw, 8, 8, 14, p["body_lt"], oy)
        s.dc(draw, 12, 2, 4, lighten(p["body_lt"], 0.1), oy)
        s.dl(draw, -4, -14+oy, -4, 20+oy, p["accent"], 2, 0)
        s.dl(draw, -6, oy, -16, 10+oy, vein_c, 1, 0)
        s.dr(draw, -6, 8, 10, 5, guts_c, oy)
        for tx in range(-5, 4, 2):
            s.dr(draw, tx, 7, 2, 2, teeth_c, oy)
            s.dr(draw, tx, 12, 2, 2, teeth_c, oy)
        s.dr(draw, -24, -6, 8, 6, p["skin"], oy)
        s.dr(draw, -30, -8, 7, 5, p["skin"], oy)
        s.dr(draw, -22, 4, 6, 5, darken(p["skin"],0.1), oy)
        s.dr(draw, -4, -20, 6, 10, p["skin"], oy)
        s.dr(draw, -5, -28, 5, 9, p["skin"], oy)
        # Main head side
        s.dc(draw, -4, -14, 10, p["body"], oy)
        s.dc(draw, -8, -14, 8, p["body_dk"], oy)
        s.dc(draw, 0, -15, 7, p["body_lt"], oy)
        s.dr(draw, -10, -17, 5, 4, p["eye"], oy)
        s.dr(draw, -4, -20, 3, 3, lighten(p["eye"], 0.2), oy)
        s.dr(draw, -10, -8, 8, 3, p["body_dk"], oy)
        for tx in range(-9, -2, 2):
            s.dr(draw, tx, -9, 2, 2, teeth_c, oy)
            s.dr(draw, tx, -7, 2, 2, teeth_c, oy)
        s.dr(draw, -8, -24, 4, 8, p["horn"], oy)
        s.dr(draw, -9, -28, 3, 5, lighten(p["horn"], 0.1), oy)
        # Second head
        s.dc(draw, 6, -12, 7, p["body_lt"], oy)
        s.dr(draw, 4, -14, 3, 3, p["eye"], oy)
        s.dr(draw, 4, -18, 2, 5, p["horn"], oy)
        # Third head
        s.dc(draw, 16, 4, 6, p["body"], oy)
        s.dr(draw, 14, 3, 2, 2, p["eye"], oy)
        s.dr(draw, 17, 3, 2, 2, p["eye"], oy)

    return s, front, back, side


# ══════════════════════════════════════════════════════════════════
# GENERATE ALL SPRITESHEETS
# ══════════════════════════════════════════════════════════════════

def generate_spritesheet(enemy_maker, out_dir, has_cast=False):
    s, front, back, side = enemy_maker()
    frames = []
    frame_info = []

    def add(name, dur, func, **kw):
        frames.append(s.make_frame(func, **kw))
        frame_info.append((name, dur))

    # Idle (2 frames per direction, ping-pong)
    add("idle_down_1", 350, front, oy=0)
    add("idle_down_2", 350, front, oy=-1)
    add("idle_up_1", 350, back, oy=0)
    add("idle_up_2", 350, back, oy=-1)
    add("idle_right_1", 350, side, oy=0)
    add("idle_right_2", 350, side, oy=-1)

    # Walk (4 frames per direction)
    walk_params = [(-1, 2), (0, 3), (1, -2), (0, -3)]
    for i, (wo, wl) in enumerate(walk_params):
        add(f"walk_down_{i+1}", 100, front, oy=wo, lo=wl)
    for i, (wo, wl) in enumerate(walk_params):
        add(f"walk_up_{i+1}", 100, back, oy=wo, lo=wl)
    for i, (wo, wl) in enumerate(walk_params):
        add(f"walk_right_{i+1}", 100, side, oy=wo, lo=wl)

    # Cast (warlock only)
    if has_cast:
        cast_vals = [0.0, 0.3, 0.7, 1.0, 0.6, 0.2]
        cast_durs = [30, 30, 30, 30, 100, 100]
        for i, (cv, cd) in enumerate(zip(cast_vals, cast_durs)):
            add(f"cast_down_{i+1}", cd, front, cast=cv)
        for i, (cv, cd) in enumerate(zip(cast_vals, cast_durs)):
            add(f"cast_up_{i+1}", cd, back, cast=cv)
        for i, (cv, cd) in enumerate(zip(cast_vals, cast_durs)):
            add(f"cast_right_{i+1}", cd, side, cast=cv)

    # Hurt (2 frames)
    hurt_base = s.make_frame(front)
    hurt_flash = s.tint_red(s.make_frame(front), 0.7)
    frames.extend([hurt_base, hurt_flash])
    frame_info.extend([("hurt_down_1", 60), ("hurt_down_2", 200)])

    # Die (4 frames)
    for i, (am, t) in enumerate([(1.0, 0.0), (0.7, 0.3), (0.4, 0.5), (0.1, 0.8)]):
        die_img = s.make_frame(front)
        s.fade(die_img, am, t)
        frames.append(die_img)
        frame_info.append((f"die_down_{i+1}", 125))

    # Build spritesheet
    cols = 8
    rows = math.ceil(len(frames) / cols)
    sheet = Image.new('RGBA', (cols * s.W, rows * s.H), (0, 0, 0, 0))
    json_frames = {}

    for idx, (img, (name, dur)) in enumerate(zip(frames, frame_info)):
        col, row = idx % cols, idx // cols
        sheet.paste(img, (col * s.W, row * s.H))
        json_frames[name] = {"frame": {"x": col*s.W, "y": row*s.H, "w": s.W, "h": s.H}, "duration": dur}

    sheet.save(f"{out_dir}/{s.name}.png")

    # Build animation dict
    animations = {}
    for dir_name in ["down", "up", "right"]:
        for anim in ["idle", "walk"]:
            key = f"{anim}_{dir_name}"
            anim_frames = [n for n, _ in frame_info if n.startswith(key + "_")]
            if anim_frames:
                loop = "pingpong" if anim == "idle" else "forward"
                animations[key] = {"frames": anim_frames, "loop": loop}
        if has_cast:
            key = f"cast_{dir_name}"
            cast_frames = [n for n, _ in frame_info if n.startswith(key + "_")]
            if cast_frames:
                animations[key] = {"frames": cast_frames, "loop": "forward"}

    animations["hurt_down"] = {"frames": ["hurt_down_1", "hurt_down_2"], "loop": "forward"}
    animations["die_down"] = {"frames": [f"die_down_{i+1}" for i in range(4)], "loop": "forward"}

    meta = {
        "frames": json_frames,
        "meta": {"size": {"w": cols*s.W, "h": rows*s.H}, "frame_size": {"w": s.W, "h": s.H}, "scale": 1},
        "animations": animations
    }

    with open(f"{out_dir}/{s.name}.json", 'w') as f:
        json.dump(meta, f, indent=2)

    print(f"  {s.name}: {len(frames)} frames, {cols*s.W}x{rows*s.H} sheet")


if __name__ == "__main__":
    base = "/root/home-projects/escape-from-hell/assets/sprites/enemies"
    print("Generating enemy spritesheets...")
    generate_spritesheet(make_demon, f"{base}/demon")
    generate_spritesheet(make_imp, f"{base}/imp")
    generate_spritesheet(make_hellhound, f"{base}/hellhound")
    generate_spritesheet(make_warlock, f"{base}/warlock", has_cast=True)
    generate_spritesheet(make_abomination, f"{base}/abomination", has_cast=True)
    print("Done!")
