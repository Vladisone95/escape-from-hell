#!/usr/bin/env python3
"""Fix character and sword spritesheets: clean artifacts, reduce red effects, add slash_up/slash_down."""
import math
from PIL import Image


PYTHON = r"C:\Users\Vladi\AppData\Local\Programs\Python\Python312\python.exe"


def is_red_effect(r, g, b):
    """Detect red/orange/fire effect pixels (not metallic or skin tones)."""
    if r < 70:
        return False
    # Deep/dark red
    if r > 80 and g < 45 and b < 45:
        return True
    # Standard red
    if r > 120 and g < 100 and b < 80 and r > g * 1.6:
        return True
    # Bright red
    if r > 150 and g < 100 and b < 80:
        return True
    # Strong red dominance
    if r > 100 and r > g * 1.8 and r > b * 2:
        return True
    # Orange/fire glow
    if r > 160 and g > 50 and g < 150 and b < 60 and r > g * 1.4:
        return True
    # Warm brown-red (dark smear edges)
    if r > 90 and g > 30 and g < 70 and b < 45 and r > g * 1.5:
        return True
    return False


def fix_character():
    """Clean alpha artifacts in character spritesheet."""
    img = Image.open("assets/sprites/player/main_character.png").convert("RGBA")
    pix = img.load()
    w, h = img.size
    fh = 184  # frame height

    for y in range(h):
        row_idx = y // fh
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue
            # Die row (row 5, y=920+): preserve intentional semi-transparency
            if row_idx == 5:
                if a < 10:
                    pix[x, y] = (0, 0, 0, 0)
                continue
            # All other rows: threshold alpha to clean edges
            if a < 25:
                pix[x, y] = (0, 0, 0, 0)
            elif a < 210:
                pix[x, y] = (r, g, b, 255)

    img.save("assets/sprites/player/main_character.png")
    print(f"Character spritesheet cleaned: {w}x{h}")


def process_sword_frame(frame, row, col):
    """Reduce red slash/explosion effects in a single sword frame."""
    pix = frame.load()
    w, h = frame.size
    # Sword center is in upper portion of frame
    cx, cy = w // 2, int(h * 0.38)

    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if a == 0:
                continue

            # Clean alpha noise
            if a < 12:
                pix[x, y] = (0, 0, 0, 0)
                continue

            if not is_red_effect(r, g, b):
                continue

            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)

            if row == 2:
                # Idle row: barely visible warm glow
                if dist > 25:
                    pix[x, y] = (0, 0, 0, 0)
                elif dist > 15:
                    pix[x, y] = (r, g, b, int(a * 0.1))
                else:
                    pix[x, y] = (r, g, b, int(a * 0.2))
            elif col < 2:
                # Early slash frames: very minimal
                if dist > 30:
                    pix[x, y] = (0, 0, 0, 0)
                elif dist > 18:
                    pix[x, y] = (r, g, b, int(a * 0.15))
                else:
                    pix[x, y] = (r, g, b, int(a * 0.35))
            elif col < 6:
                # Mid slash: small tight trail
                if dist > 40:
                    pix[x, y] = (0, 0, 0, 0)
                elif dist > 25:
                    pix[x, y] = (r, g, b, int(a * 0.15))
                else:
                    pix[x, y] = (r, g, b, int(a * 0.4))
            else:
                # Late frames (explosion): very aggressive
                if dist > 30:
                    pix[x, y] = (0, 0, 0, 0)
                elif dist > 18:
                    pix[x, y] = (r, g, b, int(a * 0.1))
                else:
                    pix[x, y] = (r, g, b, int(a * 0.25))

    return frame


def rotate_frame_in_place(frame, angle):
    """Rotate frame content by angle degrees within padded square, crop back to original size."""
    fw, fh = frame.size
    sq = max(fw, fh)
    canvas = Image.new("RGBA", (sq, sq), (0, 0, 0, 0))
    ox = (sq - fw) // 2
    oy = (sq - fh) // 2
    canvas.paste(frame, (ox, oy))
    rotated = canvas.rotate(angle, resample=Image.BICUBIC, expand=False)
    # Crop back to original size, centered
    cx2, cy2 = sq // 2, sq // 2
    left = cx2 - fw // 2
    top = cy2 - fh // 2
    return rotated.crop((left, top, left + fw, top + fh))


def fix_sword():
    """Reduce red effects in sword spritesheet and add slash_up/slash_down rows."""
    img = Image.open("assets/sprites/player/main_character_sword.png").convert("RGBA")
    fw, fh = 196, 324
    cols = img.width // fw  # 10
    rows = img.height // fh  # 3

    # Process existing frames to reduce red
    for row in range(rows):
        for col in range(cols):
            x0, y0 = col * fw, row * fh
            frame = img.crop((x0, y0, x0 + fw, y0 + fh))
            frame = process_sword_frame(frame, row, col)
            img.paste(frame, (x0, y0))

    # Generate slash_up (rotate slash_right 90 CCW) and slash_down (rotate 90 CW)
    slash_up_frames = []
    slash_down_frames = []

    for col in range(cols):
        x0 = col * fw
        frame = img.crop((x0, 0, x0 + fw, fh))  # slash_right row

        up_frame = rotate_frame_in_place(frame, 90)   # 90 CCW → arc goes up
        slash_up_frames.append(up_frame)

        down_frame = rotate_frame_in_place(frame, -90)  # 90 CW → arc goes down
        slash_down_frames.append(down_frame)

    # Build new image: 5 rows (original 3 + slash_up + slash_down)
    new_h = 5 * fh
    new_img = Image.new("RGBA", (cols * fw, new_h), (0, 0, 0, 0))
    new_img.paste(img, (0, 0))

    for col, frame in enumerate(slash_up_frames):
        new_img.paste(frame, (col * fw, 3 * fh))

    for col, frame in enumerate(slash_down_frames):
        new_img.paste(frame, (col * fw, 4 * fh))

    new_img.save("assets/sprites/player/main_character_sword.png")
    print(f"Sword spritesheet: {new_img.width}x{new_img.height} ({cols}x5 frames)")


if __name__ == "__main__":
    fix_character()
    fix_sword()
