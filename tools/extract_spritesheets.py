#!/usr/bin/env python3
"""Extract clean spritesheets from reference JPG images.
Uses fixed grid detection, removes background, outputs transparent PNGs.
"""
import os
import numpy as np
from PIL import Image, ImageFilter

ASSETS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      "assets", "sprites", "player")

# Grid column boundaries (shared by both images, 10 cells)
GRID_X = [8, 206, 411, 616, 820, 1023, 1226, 1430, 1635, 1840, 2038]

# Background colors (dark separator, grid line, cell fill)
DARK_BG = np.array([37, 38, 43], dtype=float)
MID_BG = np.array([56, 61, 62], dtype=float)
LIGHT_BG = np.array([74, 78, 77], dtype=float)


def load(name: str) -> np.ndarray:
    return np.array(Image.open(os.path.join(ASSETS, name)))


def bg_distance(arr: np.ndarray) -> np.ndarray:
    """Distance from all background colors (higher = more likely content)."""
    farr = arr.astype(float)
    d1 = np.sqrt(np.sum((farr - DARK_BG) ** 2, axis=2))
    d2 = np.sqrt(np.sum((farr - MID_BG) ** 2, axis=2))
    d3 = np.sqrt(np.sum((farr - LIGHT_BG) ** 2, axis=2))
    return np.minimum(np.minimum(d1, d2), d3)


def has_content(arr: np.ndarray, threshold: float = 35.0, min_pixels: int = 100) -> bool:
    """Check if a cell has meaningful sprite content."""
    dist = bg_distance(arr)
    return int(np.sum(dist > threshold)) > min_pixels


def tight_crop(arr: np.ndarray, mask: np.ndarray, pad: int = 2):
    """Get tight bounding box of content and return cropped arrays."""
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    if not np.any(rows):
        return arr, mask
    y0, y1 = int(np.where(rows)[0][0]), int(np.where(rows)[0][-1]) + 1
    x0, x1 = int(np.where(cols)[0][0]), int(np.where(cols)[0][-1]) + 1
    y0 = max(0, y0 - pad)
    y1 = min(arr.shape[0], y1 + pad)
    x0 = max(0, x0 - pad)
    x1 = min(arr.shape[1], x1 + pad)
    return arr[y0:y1, x0:x1], mask[y0:y1, x0:x1]


def make_rgba(arr: np.ndarray, threshold: float = 32.0) -> Image.Image:
    """Convert RGB array to RGBA with background removed."""
    farr = arr.astype(float)
    dist = bg_distance(arr)

    # Remove near-white text pixels
    brightness = np.mean(farr, axis=2)
    is_text = brightness > 190

    # Also use saturation to help: background is very desaturated
    r, g, b = farr[:,:,0], farr[:,:,1], farr[:,:,2]
    max_c = np.maximum(np.maximum(r, g), b)
    min_c = np.minimum(np.minimum(r, g), b)
    sat = np.where(max_c > 0, (max_c - min_c) / (max_c + 1e-10), 0)

    # Content is either: far from bg colors OR has significant saturation
    content_score = np.maximum(dist, sat * 120)

    # Alpha ramp: 0 below threshold, 255 above threshold+12
    alpha = np.clip((content_score - threshold) * (255.0 / 12.0), 0, 255).astype(np.uint8)
    alpha[is_text] = 0

    rgba = np.zeros((*arr.shape[:2], 4), dtype=np.uint8)
    rgba[:, :, :3] = arr
    rgba[:, :, 3] = alpha

    img = Image.fromarray(rgba, 'RGBA')
    a = img.split()[3]
    a = a.filter(ImageFilter.MedianFilter(3))
    img.putalpha(a)
    return img


def extract_grid_cell(arr: np.ndarray, col: int, y_start: int, y_end: int) -> np.ndarray:
    """Extract a single grid cell."""
    x0 = GRID_X[col]
    x1 = GRID_X[col + 1]
    # Inset by 3px to skip grid lines
    return arr[y_start:y_end, x0 + 5:x1 - 5]


def extract_row_frames(arr: np.ndarray, y_start: int, y_end: int,
                        expected_frames: int = None) -> list:
    """Extract all non-empty frames from a row of grid cells."""
    frames_rgba = []
    for col in range(10):
        cell = extract_grid_cell(arr, col, y_start, y_end)
        if has_content(cell, threshold=35, min_pixels=80):
            dist = bg_distance(cell)
            mask = dist > 30
            cropped, cmask = tight_crop(cell, mask, pad=3)
            if cropped.shape[0] > 15 and cropped.shape[1] > 15:
                frames_rgba.append(make_rgba(cropped, threshold=28))

    if expected_frames and len(frames_rgba) > expected_frames:
        frames_rgba = frames_rgba[:expected_frames]
    return frames_rgba


def normalize_and_sheet(frames_dict: dict, bottom_align: bool = True) -> Image.Image:
    """Normalize all frames and build a spritesheet (one row per animation)."""
    all_frames = [f for fs in frames_dict.values() for f in fs]
    if not all_frames:
        return Image.new('RGBA', (1, 1))

    max_w = max(f.width for f in all_frames)
    max_h = max(f.height for f in all_frames)
    # Round to multiples of 4
    fw = ((max_w + 3) // 4) * 4
    fh = ((max_h + 3) // 4) * 4

    max_cols = max(len(fs) for fs in frames_dict.values())
    n_rows = len(frames_dict)
    sheet = Image.new('RGBA', (fw * max_cols, fh * n_rows), (0, 0, 0, 0))

    for row_idx, (name, frames) in enumerate(frames_dict.items()):
        for col_idx, f in enumerate(frames):
            ox = (fw - f.width) // 2
            if bottom_align:
                oy = fh - f.height  # bottom-align for characters
            else:
                oy = (fh - f.height) // 2  # center for weapons
            canvas = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
            canvas.paste(f, (ox, oy))
            sheet.paste(canvas, (col_idx * fw, row_idx * fh))

    return sheet, fw, fh


def process_character():
    """Process main-character.jpg."""
    print("Processing main-character.jpg...")
    arr = load("main-character.jpg")

    # Row boundaries (from grid analysis):
    # Text labels sit in dark separator bands, content is between them
    rows_config = [
        ("walk_right", 30, 210, 8),
        ("walk_left",  255, 430, 8),
        ("dash",       470, 650, 8),
        ("idle",       690, 875, 4),   # left half of row 4
        ("hurt",       690, 875, 4),   # right half of row 4
        ("die",        915, 1100, 7),
    ]

    frames_dict = {}
    for name, ys, ye, expected in rows_config:
        if name == "hurt":
            # HURT is in columns 5-9 of the idle_hurt row
            frames = []
            for col in range(5, 10):
                cell = extract_grid_cell(arr, col, ys, ye)
                if has_content(cell, threshold=35, min_pixels=80):
                    dist = bg_distance(cell)
                    mask = dist > 30
                    cropped, cmask = tight_crop(cell, mask, pad=3)
                    if cropped.shape[0] > 15 and cropped.shape[1] > 15:
                        frames.append(make_rgba(cropped, threshold=28))
            frames_dict[name] = frames[:expected]
        elif name == "idle":
            # IDLE is in columns 0-4 of the idle_hurt row
            frames = []
            for col in range(5):
                cell = extract_grid_cell(arr, col, ys, ye)
                if has_content(cell, threshold=35, min_pixels=80):
                    dist = bg_distance(cell)
                    mask = dist > 30
                    cropped, cmask = tight_crop(cell, mask, pad=3)
                    if cropped.shape[0] > 15 and cropped.shape[1] > 15:
                        frames.append(make_rgba(cropped, threshold=28))
            frames_dict[name] = frames[:expected]
        else:
            frames_dict[name] = extract_row_frames(arr, ys, ye, expected)

        print(f"  {name}: {len(frames_dict[name])} frames")

    sheet, fw, fh = normalize_and_sheet(frames_dict, bottom_align=True)
    out_path = os.path.join(ASSETS, "main_character.png")
    sheet.save(out_path)
    print(f"  Saved: {out_path} ({sheet.size[0]}x{sheet.size[1]}, frame: {fw}x{fh})")


def process_sword():
    """Process main-character-sword.jpg."""
    print("\nProcessing main-character-sword.jpg...")
    arr = load("main-character-sword.jpg")

    # Sword rows: slash rows span 2 grid cells vertically
    # Row 1: SLASH RIGHT - y=44 to 435 (2 cells)
    # Row 2: SLASH LEFT  - y=476 to 875 (2 cells)
    # Row 3: IDLE        - y=913 to 1103 (1 cell)
    rows_config = [
        ("slash_right", 44, 435, 10),
        ("slash_left",  476, 875, 10),
        ("idle",        913, 1103, 10),
    ]

    frames_dict = {}
    for name, ys, ye, expected in rows_config:
        frames_dict[name] = extract_row_frames(arr, ys, ye, expected)
        print(f"  {name}: {len(frames_dict[name])} frames")

    sheet, fw, fh = normalize_and_sheet(frames_dict, bottom_align=False)
    out_path = os.path.join(ASSETS, "main_character_sword.png")
    sheet.save(out_path)
    print(f"  Saved: {out_path} ({sheet.size[0]}x{sheet.size[1]}, frame: {fw}x{fh})")


if __name__ == "__main__":
    process_character()
    process_sword()
    print("\nDone!")
