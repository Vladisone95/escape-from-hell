#!/usr/bin/env python3
"""Generate player knight spritesheet from the procedural draw code."""
import json, math
from PIL import Image, ImageDraw

W, H = 40, 50  # frame dimensions
CX, CY = 20, 28  # character center

# Color palette (from PlayerArenaSprite.gd)
HELMET      = (102, 107, 127)
HELMET_DK   = (51, 76, 78)
HELMET_CREST= (122, 127, 147)
VISOR       = (102, 204, 255)
ARMOR       = (38, 89, 216)
ARMOR_DK    = (26, 77, 166)
ARMOR_LT    = (71, 128, 242)
ARMOR_LT2   = (107, 155, 247)
SKIN        = (216, 179, 142)
BLADE       = (204, 220, 230)
BLADE_EDGE  = (235, 235, 248)
HILT        = (128, 70, 32)
GUARD       = (154, 140, 77)
BOOT        = (64, 45, 33)
BOOT_DK     = (54, 38, 28)
BELT        = (128, 70, 18)

def lc(x, y):
    """Convert local coords to canvas coords."""
    return (CX + x, CY + y)

def draw_rect(draw, x, y, w, h, color, oy=0, lo=0):
    """Draw a rectangle in local coords."""
    cx, cy = CX + x, CY + y + oy
    draw.rectangle([cx, cy, cx + w - 1, cy + h - 1], fill=color)

def draw_front(draw, oy=0, lo=0, arm_angle=0):
    """Draw front-facing knight."""
    # Left arm (behind body)
    draw_rect(draw, -14, -3, 5, 12, ARMOR_DK, oy)
    draw_rect(draw, -14, 8, 4, 3, SKIN, oy)

    # Legs
    draw_rect(draw, -7, 10, 6, 8, ARMOR_DK, oy, lo)
    draw_rect(draw, 1, 10, 6, 8, ARMOR_DK, oy, -lo)

    # Boots
    draw_rect(draw, -8, 16, 8, 4, BOOT, oy, lo)
    draw_rect(draw, 0, 16, 8, 4, BOOT, oy, -lo)

    # Torso
    draw_rect(draw, -9, -6, 18, 16, ARMOR, oy)
    draw_rect(draw, -7, -4, 14, 3, ARMOR_LT, oy)

    # V-detail
    p1  = lc(0, -4 + oy)
    p2  = lc(-5, 4 + oy)
    p3  = lc(5, 4 + oy)
    draw.line([p1, p2], fill=ARMOR_LT, width=1)
    draw.line([p1, p3], fill=ARMOR_LT, width=1)

    # Belt
    draw_rect(draw, -10, 7, 20, 3, BELT, oy)
    draw_rect(draw, -2, 7, 4, 3, GUARD, oy)

    # Shoulders
    draw_rect(draw, -13, -6, 6, 7, ARMOR_LT, oy)
    draw_rect(draw, 7, -6, 6, 7, ARMOR_LT, oy)
    draw_rect(draw, -13, -6, 6, 2, ARMOR_LT2, oy)
    draw_rect(draw, 7, -6, 6, 2, ARMOR_LT2, oy)

    # Head
    cx, cy_h = CX, CY - 12 + oy
    # Helmet circle
    for dy in range(-9, 10):
        for dx in range(-9, 10):
            if dx*dx + dy*dy <= 81:
                px, py = cx + dx, cy_h + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=HELMET)
    # Crest
    draw_rect(draw, -1, -21, 2, 5, HELMET_CREST, oy)
    # Visor band
    draw_rect(draw, -7, -14, 14, 5, HELMET_DK, oy)
    # Eyes
    draw_rect(draw, -5, -13, 4, 2, VISOR, oy)
    draw_rect(draw, 1, -13, 4, 2, VISOR, oy)

    # Right arm + sword (at arm_angle)
    if abs(arm_angle) < 0.01:
        # Straight arm - no rotation needed
        sx = CX + 10
        sy_base = CY - 4 + oy
        # Blade
        draw.rectangle([sx - 1, sy_base - 14, sx, sy_base + 5], fill=BLADE)
        draw.rectangle([sx, sy_base - 14, sx, sy_base + 5], fill=BLADE_EDGE)
        # Tip
        draw.point((sx - 1, sy_base - 15), fill=BLADE_EDGE)
        draw.point((sx - 1, sy_base - 16), fill=BLADE_EDGE)
        draw.point((sx - 1, sy_base - 17), fill=BLADE_EDGE)
        # Guard
        draw.rectangle([sx - 4, sy_base + 5, sx + 3, sy_base + 6], fill=GUARD)
        # Hilt
        draw.rectangle([sx - 1, sy_base + 6, sx + 1, sy_base + 11], fill=HILT)
        # Upper arm
        draw.rectangle([sx - 3, sy_base, sx + 2, sy_base + 7], fill=ARMOR_DK)
        # Lower arm
        draw.rectangle([sx - 2, sy_base + 7, sx + 2, sy_base + 12], fill=ARMOR)
        # Hand
        draw.rectangle([sx - 2, sy_base + 12, sx + 1, sy_base + 14], fill=SKIN)
    else:
        # Rotated arm - draw at angle
        _draw_rotated_arm(draw, CX + 10, CY - 4 + oy, arm_angle)


def _draw_rotated_arm(draw, sx, sy, angle):
    """Draw sword arm rotated by angle radians."""
    cos_a = math.cos(angle)
    sin_a = math.sin(angle)

    def rot(lx, ly):
        rx = sx + lx * cos_a - ly * sin_a
        ry = sy + lx * sin_a + ly * cos_a
        return (int(rx), int(ry))

    # Blade (long line)
    for t in range(-17, 6):
        px, py = rot(0, t)
        if 0 <= px < W and 0 <= py < H:
            draw.point((px, py), fill=BLADE)
        px2, py2 = rot(1, t)
        if 0 <= px2 < W and 0 <= py2 < H:
            draw.point((px2, py2), fill=BLADE_EDGE if t < -10 else BLADE)

    # Guard
    for gx in range(-4, 4):
        for gy in range(5, 7):
            px, py = rot(gx, gy)
            if 0 <= px < W and 0 <= py < H:
                draw.point((px, py), fill=GUARD)

    # Hilt
    for gx in range(-1, 2):
        for gy in range(7, 12):
            px, py = rot(gx, gy)
            if 0 <= px < W and 0 <= py < H:
                draw.point((px, py), fill=HILT)

    # Upper arm
    for gx in range(-3, 3):
        for gy in range(0, 8):
            px, py = rot(gx, gy)
            if 0 <= px < W and 0 <= py < H:
                draw.point((px, py), fill=ARMOR_DK)

    # Hand
    for gx in range(-2, 2):
        for gy in range(12, 15):
            px, py = rot(gx, gy)
            if 0 <= px < W and 0 <= py < H:
                draw.point((px, py), fill=SKIN)


def draw_back(draw, oy=0, lo=0, arm_angle=0):
    """Draw back-facing knight."""
    # Sword arm behind (same as front but behind body)
    sx = CX + 10
    sy_base = CY - 4 + oy
    if abs(arm_angle) < 0.01:
        draw.rectangle([sx - 1, sy_base - 12, sx, sy_base + 5], fill=BLADE)
        draw.rectangle([sx, sy_base - 12, sx, sy_base + 5], fill=BLADE_EDGE)
        draw.rectangle([sx - 4, sy_base + 5, sx + 3, sy_base + 6], fill=GUARD)
        draw.rectangle([sx - 1, sy_base + 6, sx + 1, sy_base + 11], fill=HILT)
        draw.rectangle([sx - 3, sy_base, sx + 2, sy_base + 7], fill=ARMOR_DK)
        draw.rectangle([sx - 2, sy_base + 7, sx + 2, sy_base + 12], fill=ARMOR)
        draw.rectangle([sx - 2, sy_base + 12, sx + 1, sy_base + 14], fill=SKIN)
    else:
        _draw_rotated_arm(draw, sx, sy_base, arm_angle)

    # Legs
    draw_rect(draw, -7, 10, 6, 8, ARMOR_DK, oy, lo)
    draw_rect(draw, 1, 10, 6, 8, ARMOR_DK, oy, -lo)
    draw_rect(draw, -8, 16, 8, 4, BOOT, oy, lo)
    draw_rect(draw, 0, 16, 8, 4, BOOT, oy, -lo)

    # Torso back plate
    draw_rect(draw, -9, -6, 18, 16, ARMOR_DK, oy)
    p1  = lc(0, -4 + oy)
    p2  = lc(0, 8 + oy)
    draw.line([p1, p2], fill=(25, 64, 140), width=1)
    draw_rect(draw, -9, -6, 2, 16, ARMOR, oy)
    draw_rect(draw, 7, -6, 2, 16, ARMOR, oy)

    # Belt
    draw_rect(draw, -10, 7, 20, 3, BELT, oy)

    # Shoulders
    draw_rect(draw, -13, -6, 6, 7, ARMOR_LT, oy)
    draw_rect(draw, 7, -6, 6, 7, ARMOR_LT, oy)

    # Arms behind
    draw_rect(draw, -14, -3, 5, 12, ARMOR_DK, oy)
    draw_rect(draw, 9, -3, 5, 12, ARMOR_DK, oy)

    # Shield on back
    draw_rect(draw, -5, -3, 10, 12, ARMOR, oy)
    draw_rect(draw, -4, -2, 8, 10, ARMOR_LT, oy)
    draw_rect(draw, -1, 1, 2, 4, GUARD, oy)

    # Head back
    cx, cy_h = CX, CY - 12 + oy
    for dy in range(-9, 10):
        for dx in range(-9, 10):
            if dx*dx + dy*dy <= 81:
                px, py = cx + dx, cy_h + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=HELMET)
    draw_rect(draw, -1, -21, 2, 5, HELMET_CREST, oy)
    draw_rect(draw, -6, -14, 12, 4, HELMET_DK, oy)


def draw_side(draw, oy=0, lo=0, arm_angle=0):
    """Draw right-facing knight."""
    # Shield on back arm (behind body)
    draw_rect(draw, -10, -1, 5, 10, ARMOR, oy)
    draw_rect(draw, -9, 0, 3, 8, ARMOR_LT, oy)

    # Back leg
    draw_rect(draw, -3, 10, 6, 8, (18, 62, 133), oy, -lo)  # darker
    draw_rect(draw, -4, 16, 8, 4, BOOT_DK, oy, -lo)

    # Front leg
    draw_rect(draw, -3, 10, 6, 8, ARMOR_DK, oy, lo)
    draw_rect(draw, -4, 16, 8, 4, BOOT, oy, lo)

    # Torso (narrower from side)
    draw_rect(draw, -5, -6, 5, 16, ARMOR_DK, oy)
    draw_rect(draw, 0, -6, 6, 16, ARMOR, oy)
    draw_rect(draw, 5, -5, 1, 14, ARMOR_LT, oy)
    # Shoulder pad
    draw_rect(draw, 3, -6, 5, 7, ARMOR_LT, oy)
    draw_rect(draw, 3, -6, 5, 2, ARMOR_LT2, oy)

    # Belt
    draw_rect(draw, -6, 7, 14, 3, BELT, oy)
    draw_rect(draw, 4, 7, 3, 3, GUARD, oy)

    # Head (side profile - overlapping circles)
    cx1 = CX + 1
    cy_h = CY - 12 + oy
    for dy in range(-8, 9):
        for dx in range(-8, 9):
            if dx*dx + dy*dy <= 64:
                px, py = cx1 + dx, cy_h + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=HELMET)
    # Back of head
    cx2 = CX - 2
    blend = tuple((a + b) // 2 for a, b in zip(HELMET_DK, HELMET))
    for dy in range(-6, 7):
        for dx in range(-6, 7):
            if dx*dx + dy*dy <= 36:
                px, py = cx2 + dx, cy_h + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=blend)
    # Front highlight
    cx3 = CX + 3
    hl = tuple(min(255, c + 20) for c in HELMET)
    for dy in range(-6, 7):
        for dx in range(-6, 7):
            if dx*dx + dy*dy <= 36:
                px, py = cx3 + dx, (cy_h - 1) + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=hl)

    # Visor
    draw_rect(draw, 1, -15, 10, 4, HELMET_DK, oy)
    draw_rect(draw, 7, -14, 3, 2, VISOR, oy)
    draw_rect(draw, 4, -10, 5, 2, HELMET_DK, oy)
    # Crest
    draw_rect(draw, 0, -21, 2, 6, HELMET_CREST, oy)

    # Sword arm + sword (drawn facing right)
    sx = CX + 6
    sy_base = CY - 4 + oy
    if abs(arm_angle) < 0.01:
        draw.rectangle([sx - 1, sy_base - 14, sx, sy_base + 5], fill=BLADE)
        draw.rectangle([sx, sy_base - 14, sx, sy_base + 5], fill=BLADE_EDGE)
        draw.point((sx - 1, sy_base - 15), fill=BLADE_EDGE)
        draw.point((sx - 1, sy_base - 16), fill=BLADE_EDGE)
        draw.rectangle([sx - 3, sy_base + 5, sx + 3, sy_base + 6], fill=GUARD)
        draw.rectangle([sx - 1, sy_base + 6, sx + 1, sy_base + 11], fill=HILT)
        draw.rectangle([sx - 2, sy_base, sx + 2, sy_base + 7], fill=ARMOR_DK)
        draw.rectangle([sx - 2, sy_base + 7, sx + 1, sy_base + 12], fill=ARMOR)
        draw.rectangle([sx - 1, sy_base + 12, sx + 1, sy_base + 14], fill=SKIN)
    else:
        _draw_rotated_arm(draw, sx, sy_base, arm_angle)


def make_frame(draw_func, oy=0, lo=0, arm_angle=0):
    """Create a single frame image."""
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(draw, oy=oy, lo=lo, arm_angle=arm_angle)
    return img


# ── Generate all frames ──
frames = []
frame_info = []  # (name, duration_ms)

# Helper to add frame
def add(name, dur, func, **kwargs):
    frames.append(make_frame(func, **kwargs))
    frame_info.append((name, dur))

# === IDLE animations (2 frames each, ping-pong) ===
add("idle_down_1", 425, draw_front, oy=0)
add("idle_down_2", 425, draw_front, oy=-1)

add("idle_up_1", 425, draw_back, oy=0)
add("idle_up_2", 425, draw_back, oy=-1)

add("idle_right_1", 425, draw_side, oy=0)
add("idle_right_2", 425, draw_side, oy=-1)

# === WALK animations (4 frames each, forward loop) ===
walk_offsets = [(-2, 2), (0, 3), (2, -2), (0, -3)]  # (oy, lo) for walk cycle
for i, (wo, wl) in enumerate(walk_offsets):
    add(f"walk_down_{i+1}", 100, draw_front, oy=wo, lo=wl)

for i, (wo, wl) in enumerate(walk_offsets):
    add(f"walk_up_{i+1}", 100, draw_back, oy=wo, lo=wl)

for i, (wo, wl) in enumerate(walk_offsets):
    add(f"walk_right_{i+1}", 100, draw_side, oy=wo, lo=wl)

# === ATTACK animations (4 frames each, forward) ===
# arm_angle progression: -1.6 (windup), -0.5 (mid), 0.7 (swing through), 0.0 (settle)
atk_angles = [-1.6, -0.5, 0.7, 0.0]
atk_durs = [80, 60, 100, 60]
for i, (aa, dur) in enumerate(zip(atk_angles, atk_durs)):
    add(f"attack_down_{i+1}", dur, draw_front, arm_angle=aa)

for i, (aa, dur) in enumerate(zip(atk_angles, atk_durs)):
    add(f"attack_up_{i+1}", dur, draw_back, arm_angle=aa)

for i, (aa, dur) in enumerate(zip(atk_angles, atk_durs)):
    add(f"attack_right_{i+1}", dur, draw_side, arm_angle=aa)

# === HURT animation (2 frames - normal + red tint) ===
def tint_red(img, factor=0.6):
    """Apply red hurt tint to an image."""
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a > 0:
                r = int(r + (255 - r) * factor)
                g = int(g * (1 - factor) + 30 * factor)
                b = int(b * (1 - factor) + 20 * factor)
                pixels[x, y] = (min(255, r), g, b, a)
    return img

hurt_base = make_frame(draw_front)
hurt_flash = tint_red(make_frame(draw_front), 0.7)
frames.append(hurt_base)
frame_info.append(("hurt_down_1", 60))
frames.append(hurt_flash)
frame_info.append(("hurt_down_2", 200))

# === DIE animation (4 frames - increasing fade + red tint) ===
for i, (alpha_mult, tint) in enumerate([(1.0, 0.0), (0.7, 0.3), (0.4, 0.5), (0.1, 0.7)]):
    die_img = make_frame(draw_front)
    pixels = die_img.load()
    for y in range(die_img.height):
        for x in range(die_img.width):
            r, g, b, a = pixels[x, y]
            if a > 0:
                r = int(r + (255 - r) * tint)
                g = int(g * (1 - tint) + 38 * tint)
                b = int(b * (1 - tint) + 25 * tint)
                a = int(a * alpha_mult)
                pixels[x, y] = (min(255, r), g, b, a)
    frames.append(die_img)
    frame_info.append((f"die_down_{i+1}", 160))

# ── Build spritesheet ──
cols = 8
rows = math.ceil(len(frames) / cols)
sheet_w = cols * W
sheet_h = rows * H

sheet = Image.new('RGBA', (sheet_w, sheet_h), (0, 0, 0, 0))
json_frames = {}

for idx, (img, (name, dur)) in enumerate(zip(frames, frame_info)):
    col = idx % cols
    row = idx // cols
    px = col * W
    py = row * H
    sheet.paste(img, (px, py))
    json_frames[name] = {
        "frame": {"x": px, "y": py, "w": W, "h": H},
        "duration": dur
    }

out_dir = "/root/home-projects/escape-from-hell/assets/sprites/player"
sheet.save(f"{out_dir}/player.png")

# Save JSON metadata
meta = {
    "frames": json_frames,
    "meta": {
        "size": {"w": sheet_w, "h": sheet_h},
        "frame_size": {"w": W, "h": H},
        "scale": 1
    },
    "animations": {
        "idle_down":    {"frames": ["idle_down_1", "idle_down_2"], "loop": "pingpong"},
        "idle_up":      {"frames": ["idle_up_1", "idle_up_2"], "loop": "pingpong"},
        "idle_right":   {"frames": ["idle_right_1", "idle_right_2"], "loop": "pingpong"},
        "walk_down":    {"frames": [f"walk_down_{i+1}" for i in range(4)], "loop": "forward"},
        "walk_up":      {"frames": [f"walk_up_{i+1}" for i in range(4)], "loop": "forward"},
        "walk_right":   {"frames": [f"walk_right_{i+1}" for i in range(4)], "loop": "forward"},
        "attack_down":  {"frames": [f"attack_down_{i+1}" for i in range(4)], "loop": "forward"},
        "attack_up":    {"frames": [f"attack_up_{i+1}" for i in range(4)], "loop": "forward"},
        "attack_right": {"frames": [f"attack_right_{i+1}" for i in range(4)], "loop": "forward"},
        "hurt_down":    {"frames": ["hurt_down_1", "hurt_down_2"], "loop": "forward"},
        "die_down":     {"frames": [f"die_down_{i+1}" for i in range(4)], "loop": "forward"},
    }
}

with open(f"{out_dir}/player.json", 'w') as f:
    json.dump(meta, f, indent=2)

print(f"Generated {len(frames)} frames as {cols}x{rows} spritesheet ({sheet_w}x{sheet_h})")
print(f"Saved to {out_dir}/player.png and player.json")
