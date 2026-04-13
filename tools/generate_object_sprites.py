#!/usr/bin/env python3
"""Generate object sprites: obstacle types, projectile, chest, floor details, decorations."""
import json, math
from PIL import Image, ImageDraw

BASE = "/root/home-projects/escape-from-hell/assets/sprites/objects"

def draw_filled_circle(draw, cx, cy, r, color, W, H):
    for dy in range(-r, r+1):
        for dx in range(-r, r+1):
            if dx*dx + dy*dy <= r*r:
                px, py = cx + dx, cy + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=color)

def draw_filled_ellipse(draw, cx, cy, rx, ry, color, W, H):
    for dy in range(-ry, ry+1):
        for dx in range(-rx, rx+1):
            if (dx*dx)/(rx*rx+0.01) + (dy*dy)/(ry*ry+0.01) <= 1.0:
                px, py = cx + dx, cy + dy
                if 0 <= px < W and 0 <= py < H:
                    draw.point((px, py), fill=color)

def save_spritesheet(frames, frame_info, animations, W, H, out_dir, name):
    cols = max(1, min(8, len(frames)))
    rows = math.ceil(len(frames) / cols)
    sheet = Image.new('RGBA', (cols * W, rows * H), (0, 0, 0, 0))
    json_frames = {}
    for idx, (img, (fname, dur)) in enumerate(zip(frames, frame_info)):
        col, row = idx % cols, idx // cols
        sheet.paste(img, (col * W, row * H))
        json_frames[fname] = {"frame": {"x": col*W, "y": row*H, "w": W, "h": H}, "duration": dur}
    sheet.save(f"{out_dir}/{name}.png")
    meta = {
        "frames": json_frames,
        "meta": {"size": {"w": cols*W, "h": rows*H}, "frame_size": {"w": W, "h": H}, "scale": 1},
        "animations": animations
    }
    with open(f"{out_dir}/{name}.json", 'w') as f:
        json.dump(meta, f, indent=2)
    print(f"  {name}: {len(frames)} frames, {cols*W}x{rows*H}")

def save_static(img, W, H, out_dir, name):
    img.save(f"{out_dir}/{name}.png")
    meta = {
        "frames": {f"{name}_1": {"frame": {"x": 0, "y": 0, "w": W, "h": H}, "duration": 1000}},
        "meta": {"size": {"w": W, "h": H}, "frame_size": {"w": W, "h": H}, "scale": 1},
        "animations": {"default": {"frames": [f"{name}_1"], "loop": "forward"}}
    }
    with open(f"{out_dir}/{name}.json", 'w') as f:
        json.dump(meta, f, indent=2)


# ═══════════════════════════════════════════
# OBSTACLES
# ═══════════════════════════════════════════

def generate_boulder():
    """90x90 dark hellish boulder."""
    W, H = 90, 90
    cx, cy = 45, 45
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_filled_circle(draw, cx, cy, 44, (46, 30, 25, 255), W, H)
    draw_filled_circle(draw, cx - 8, cy - 6, 36, (56, 38, 30, 255), W, H)
    draw_filled_circle(draw, cx - 12, cy - 16, 12, (71, 51, 41, 255), W, H)
    # Cracks
    draw.line([(cx - 16, cy + 8), (cx + 20, cy - 4)], fill=(25, 15, 13, 255), width=2)
    draw.line([(cx - 10, cy + 16), (cx + 8, cy + 20)], fill=(35, 22, 18, 255), width=1)
    draw.line([(cx + 5, cy - 20), (cx + 18, cy + 2)], fill=(30, 18, 14, 255), width=1)
    draw_filled_circle(draw, cx + 14, cy - 8, 6, (40, 28, 22, 255), W, H)
    # Lava veins
    draw.line([(cx - 20, cy + 5), (cx - 5, cy + 12)], fill=(120, 30, 5, 180), width=1)
    draw.line([(cx + 10, cy + 15), (cx + 22, cy + 10)], fill=(100, 25, 5, 150), width=1)
    out = f"{BASE}/obstacle"
    save_static(img, W, H, out, "boulder")
    # Also save as obstacle.png for backward compat
    img.save(f"{out}/obstacle.png")
    print(f"  boulder: {W}x{H}")

def generate_pillar():
    """40x90 tall hellish stone/bone pillar."""
    W, H = 40, 90
    cx, cy = 20, 45
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    import random
    rng = random.Random(200)

    # Base shadow
    draw_filled_ellipse(draw, cx, H - 8, 18, 6, (10, 4, 3, 120), W, H)
    # Main pillar body
    draw.rectangle([cx - 12, 8, cx + 11, H - 8], fill=(55, 28, 20, 255))
    # Darker edges
    draw.rectangle([cx - 12, 8, cx - 10, H - 8], fill=(35, 16, 12, 255))
    draw.rectangle([cx + 9, 8, cx + 11, H - 8], fill=(35, 16, 12, 255))
    # Highlight stripe
    draw.rectangle([cx - 4, 8, cx - 2, H - 8], fill=(70, 38, 28, 255))
    # Capital (top)
    draw.rectangle([cx - 15, 5, cx + 14, 14], fill=(65, 32, 22, 255))
    draw.rectangle([cx - 15, 5, cx + 14, 7], fill=(80, 42, 30, 255))
    # Base
    draw.rectangle([cx - 15, H - 12, cx + 14, H - 5], fill=(65, 32, 22, 255))
    draw.rectangle([cx - 15, H - 7, cx + 14, H - 5], fill=(45, 20, 14, 255))
    # Skull emblem on pillar
    draw_filled_circle(draw, cx, cy - 10, 5, (80, 70, 60, 255), W, H)
    draw.point((cx - 2, cy - 11), fill=(20, 10, 8, 255))
    draw.point((cx + 2, cy - 11), fill=(20, 10, 8, 255))
    draw.line([(cx - 2, cy - 7), (cx + 2, cy - 7)], fill=(20, 10, 8, 255))
    # Cracks
    draw.line([(cx - 8, cy + 10), (cx + 3, cy + 25)], fill=(30, 14, 10, 255), width=1)
    draw.line([(cx + 5, cy - 20), (cx - 2, cy - 5)], fill=(30, 14, 10, 255), width=1)
    # Blood drip
    for i in range(3):
        bx = cx + rng.randint(-6, 6)
        by = rng.randint(20, 60)
        draw.line([(bx, by), (bx, by + rng.randint(3, 8))], fill=(100, 10, 5, 180), width=1)

    out = f"{BASE}/obstacle"
    save_static(img, W, H, out, "pillar")
    print(f"  pillar: {W}x{H}")

def generate_bone_pile():
    """70x70 heap of bones."""
    W, H = 70, 70
    cx, cy = 35, 40
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    import random
    rng = random.Random(300)

    # Shadow base
    draw_filled_ellipse(draw, cx, cy + 8, 28, 12, (10, 5, 4, 100), W, H)
    # Pile mound
    draw_filled_ellipse(draw, cx, cy, 26, 18, (65, 55, 45, 255), W, H)
    draw_filled_ellipse(draw, cx - 4, cy - 4, 22, 14, (75, 65, 52, 255), W, H)
    # Individual bones on top
    bone_color = (85, 75, 60, 255)
    bone_dark = (55, 45, 35, 255)
    for _ in range(8):
        bx = cx + rng.randint(-18, 18)
        by = cy + rng.randint(-12, 10)
        angle = rng.uniform(0, math.pi)
        length = rng.randint(6, 14)
        ex = int(bx + math.cos(angle) * length)
        ey = int(by + math.sin(angle) * length)
        draw.line([(bx, by), (ex, ey)], fill=bone_color, width=2)
        # Bone ends (knobs)
        draw_filled_circle(draw, bx, by, 2, bone_color, W, H)
        draw_filled_circle(draw, ex, ey, 2, bone_color, W, H)
    # A skull on top
    draw_filled_circle(draw, cx + 2, cy - 8, 6, (80, 72, 58, 255), W, H)
    draw_filled_circle(draw, cx + 2, cy - 5, 4, (75, 66, 52, 255), W, H)
    draw.point((cx, cy - 9), fill=(25, 15, 12, 255))
    draw.point((cx + 4, cy - 9), fill=(25, 15, 12, 255))
    draw.line([(cx, cy - 5), (cx + 4, cy - 5)], fill=(25, 15, 12, 255))
    # Dark crevices
    for _ in range(4):
        sx = cx + rng.randint(-15, 15)
        sy = cy + rng.randint(-8, 8)
        draw.point((sx, sy), fill=bone_dark)

    out = f"{BASE}/obstacle"
    save_static(img, W, H, out, "bone_pile")
    print(f"  bone_pile: {W}x{H}")

def generate_skull_pile():
    """60x60 stack of skulls."""
    W, H = 60, 60
    cx, cy = 30, 34
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    import random
    rng = random.Random(400)

    # Shadow
    draw_filled_ellipse(draw, cx, cy + 6, 24, 10, (10, 5, 4, 100), W, H)
    # Base mound
    draw_filled_ellipse(draw, cx, cy + 2, 22, 14, (60, 50, 40, 255), W, H)
    # Skulls
    skull_positions = [
        (cx - 10, cy + 4), (cx + 8, cy + 5), (cx, cy + 2),
        (cx - 6, cy - 4), (cx + 5, cy - 3), (cx, cy - 8),
        (cx - 12, cy), (cx + 12, cy + 1),
    ]
    for sx, sy in skull_positions:
        size = rng.randint(4, 6)
        skull_c = (80 + rng.randint(-10, 10), 72 + rng.randint(-8, 8), 58 + rng.randint(-8, 8), 255)
        draw_filled_circle(draw, sx, sy, size, skull_c, W, H)
        # Jaw
        draw_filled_circle(draw, sx, sy + size - 2, size - 2, (skull_c[0] - 10, skull_c[1] - 10, skull_c[2] - 10, 255), W, H)
        # Eye sockets
        if size >= 5:
            draw.point((sx - 2, sy - 1), fill=(20, 10, 8, 255))
            draw.point((sx + 2, sy - 1), fill=(20, 10, 8, 255))
            draw.line([(sx - 1, sy + 2), (sx + 1, sy + 2)], fill=(20, 10, 8, 255))

    out = f"{BASE}/obstacle"
    save_static(img, W, H, out, "skull_pile")
    print(f"  skull_pile: {W}x{H}")


# ═══════════════════════════════════════════
# FLOOR DETAILS (16x16)
# ═══════════════════════════════════════════

def generate_floor_details():
    out = f"{BASE}/floor_details"
    import random
    rng = random.Random(500)

    # Crack variations
    for i in range(3):
        W, H = 16, 16
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        cx, cy = 8, 8
        segments = rng.randint(2, 4)
        px, py = cx + rng.randint(-3, 3), cy + rng.randint(-3, 3)
        for _ in range(segments):
            nx = px + rng.randint(-5, 5)
            ny = py + rng.randint(-5, 5)
            nx, ny = max(0, min(15, nx)), max(0, min(15, ny))
            draw.line([(px, py), (nx, ny)], fill=(10, 3, 2, 180), width=1)
            # Subtle lighter edge
            draw.line([(px + 1, py), (nx + 1, ny)], fill=(25, 10, 8, 80), width=1)
            px, py = nx, ny
        img.save(f"{out}/crack_{i + 1}.png")
    print("  cracks: 3 variants (16x16)")

    # Small skull
    W, H = 16, 16
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_filled_circle(draw, 8, 7, 5, (70, 60, 48, 200), W, H)
    draw_filled_circle(draw, 8, 10, 3, (62, 52, 40, 200), W, H)
    draw.point((6, 6), fill=(15, 8, 5, 220))
    draw.point((10, 6), fill=(15, 8, 5, 220))
    draw.line([(7, 10), (9, 10)], fill=(15, 8, 5, 180))
    img.save(f"{out}/skull_small.png")
    print("  skull_small: 16x16")

    # Blood stains
    for i in range(2):
        W, H = 16, 16
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        cx, cy = 8, 8
        for _ in range(rng.randint(3, 6)):
            bx = cx + rng.randint(-4, 4)
            by = cy + rng.randint(-4, 4)
            br = rng.randint(1, 3)
            alpha = rng.randint(80, 160)
            draw_filled_circle(draw, bx, by, br, (80 + rng.randint(0, 40), 5, 0, alpha), W, H)
        img.save(f"{out}/blood_stain_{i + 1}.png")
    print("  blood stains: 2 variants (16x16)")

    # Small rocks
    W, H = 16, 16
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for _ in range(3):
        rx = rng.randint(3, 12)
        ry = rng.randint(3, 12)
        rr = rng.randint(1, 3)
        shade = rng.randint(25, 45)
        draw_filled_circle(draw, rx, ry, rr, (shade, shade // 2, shade // 3, 180), W, H)
        # Highlight
        draw.point((rx - 1, ry - 1), fill=(shade + 15, shade // 2 + 8, shade // 3 + 5, 160))
    img.save(f"{out}/small_rocks.png")
    print("  small_rocks: 16x16")


# ═══════════════════════════════════════════
# DECORATIONS (32x32, non-interactable)
# ═══════════════════════════════════════════

def generate_decorations():
    out = f"{BASE}/decorations"
    import random
    rng = random.Random(600)

    # Skull pile decoration (smaller, non-obstacle)
    W, H = 32, 32
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for sx, sy in [(12, 20), (20, 19), (16, 14), (10, 16), (22, 16)]:
        s = rng.randint(3, 4)
        c = (75 + rng.randint(-8, 8), 65 + rng.randint(-8, 8), 50 + rng.randint(-8, 8), 200)
        draw_filled_circle(draw, sx, sy, s, c, W, H)
        draw.point((sx - 1, sy - 1), fill=(18, 10, 6, 220))
        draw.point((sx + 1, sy - 1), fill=(18, 10, 6, 220))
    img.save(f"{out}/skull_pile_decor.png")
    print("  skull_pile_decor: 32x32")

    # Bone pile decoration
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    bone_c = (78, 68, 54, 190)
    for _ in range(5):
        bx = 16 + rng.randint(-8, 8)
        by = 18 + rng.randint(-6, 6)
        angle = rng.uniform(0, math.pi)
        length = rng.randint(4, 10)
        ex = int(bx + math.cos(angle) * length)
        ey = int(by + math.sin(angle) * length)
        draw.line([(bx, by), (ex, ey)], fill=bone_c, width=2)
        draw_filled_circle(draw, bx, by, 1, bone_c, W, H)
        draw_filled_circle(draw, ex, ey, 1, bone_c, W, H)
    img.save(f"{out}/bone_pile_decor.png")
    print("  bone_pile_decor: 32x32")

    # Broken weapon (sword)
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Blade (broken)
    draw.line([(10, 24), (22, 8)], fill=(100, 95, 88, 220), width=2)
    draw.line([(22, 8), (24, 6)], fill=(80, 75, 68, 180), width=1)  # jagged break
    # Crossguard
    draw.line([(8, 22), (14, 18)], fill=(70, 40, 20, 220), width=2)
    # Handle
    draw.line([(8, 26), (10, 24)], fill=(50, 30, 15, 220), width=2)
    # Blood on blade
    draw.point((16, 16), fill=(90, 10, 5, 150))
    draw.point((18, 13), fill=(80, 8, 3, 130))
    img.save(f"{out}/broken_weapon.png")
    print("  broken_weapon: 32x32")

    # Fallen shield
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shield body (elliptical, lying on ground perspective)
    draw_filled_ellipse(draw, 16, 18, 10, 7, (55, 30, 18, 220), W, H)
    draw_filled_ellipse(draw, 16, 18, 8, 5, (70, 40, 22, 220), W, H)
    # Metal rim
    for angle_deg in range(0, 360, 15):
        angle = math.radians(angle_deg)
        px = int(16 + math.cos(angle) * 10)
        py = int(18 + math.sin(angle) * 7)
        if 0 <= px < W and 0 <= py < H:
            draw.point((px, py), fill=(90, 50, 28, 200))
    # Emblem (simple cross)
    draw.line([(14, 16), (18, 20)], fill=(40, 18, 10, 200), width=1)
    draw.line([(18, 16), (14, 20)], fill=(40, 18, 10, 200), width=1)
    # Dent/damage
    draw_filled_circle(draw, 19, 16, 2, (45, 24, 14, 200), W, H)
    img.save(f"{out}/fallen_shield.png")
    print("  fallen_shield: 32x32")


# ═══════════════════════════════════════════
# PROJECTILE (16x16, 4-frame glow loop)
# ═══════════════════════════════════════════

def generate_projectile():
    W, H = 16, 16
    cx, cy = 8, 8
    frames = []
    frame_info = []

    for i in range(4):
        phase = i * math.pi / 2
        flicker = math.sin(phase) * 1.0
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        glow_r = int(7 + flicker)
        draw_filled_circle(draw, cx, cy, glow_r, (255, 77, 0, 128), W, H)
        draw_filled_circle(draw, cx, cy, 5, (255, 115, 13, 217), W, H)
        draw_filled_circle(draw, cx, cy, 3, (255, 179, 25, 242), W, H)
        draw_filled_circle(draw, cx, cy, 1, (255, 242, 179, 255), W, H)
        frames.append(img)
        frame_info.append((f"fly_{i+1}", 80))

    animations = {"fly": {"frames": [f"fly_{i+1}" for i in range(4)], "loop": "forward"}}
    save_spritesheet(frames, frame_info, animations, W, H,
                     f"{BASE}/projectile", "projectile")


# ═══════════════════════════════════════════
# CHEST (40x40, 6-frame glow + static chest)
# ═══════════════════════════════════════════

def generate_chest():
    W, H = 40, 40
    cx, cy = 20, 22
    frames = []
    frame_info = []

    for i in range(6):
        phase = i * math.pi / 3
        glow_alpha = int((0.15 + 0.1 * math.sin(phase)) * 255)
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw_filled_circle(draw, cx, cy - 6, 16, (255, 217, 51, max(0, glow_alpha)), W, H)
        draw.rectangle([cx-16, cy-8, cx+15, cy+9], fill=(115, 64, 25, 255))
        draw.line([(cx-14, cy-2), (cx+14, cy-2)], fill=(89, 46, 18, 255), width=1)
        draw.line([(cx-14, cy+4), (cx+14, cy+4)], fill=(89, 46, 18, 255), width=1)
        draw.rectangle([cx-17, cy-2, cx+16, cy+1], fill=(128, 128, 128, 255))
        draw.rectangle([cx-17, cy-2, cx+16, cy+1], outline=(77, 77, 77, 255))
        draw.rectangle([cx-16, cy-18, cx+15, cy-7], fill=(140, 77, 31, 255))
        draw.line([(cx-14, cy-16), (cx+14, cy-16)], fill=(166, 97, 38, 255), width=1)
        draw.rectangle([cx-16, cy-18, cx-12, cy-15], fill=(128, 128, 128, 255))
        draw.rectangle([cx+11, cy-18, cx+15, cy-15], fill=(128, 128, 128, 255))
        draw.rectangle([cx-4, cy-6, cx+3, cy+1], fill=(230, 191, 51, 255))
        draw.rectangle([cx-3, cy-5, cx+2, cy], fill=(255, 217, 77, 255))
        draw_filled_circle(draw, cx, cy-1, 1, (51, 38, 13, 255), W, H)
        frames.append(img)
        frame_info.append((f"idle_{i+1}", 167))

    animations = {"idle": {"frames": [f"idle_{i+1}" for i in range(6)], "loop": "forward"}}
    save_spritesheet(frames, frame_info, animations, W, H,
                     f"{BASE}/chest", "chest")


if __name__ == "__main__":
    print("Generating object sprites...")
    generate_boulder()
    generate_pillar()
    generate_bone_pile()
    generate_skull_pile()
    generate_projectile()
    generate_chest()
    generate_floor_details()
    generate_decorations()
    print("Done!")
