#!/usr/bin/env python3
"""Generate player 'condemned' spritesheet — 64×80 resolution.
Character: tortured human dragged into hell. Black trident or arcane staff.
"""
import argparse, json, math, os
from PIL import Image, ImageDraw

W, H = 64, 80
CX, CY = 32, 52   # pivot: 52px from top, 28px from bottom

# ── Palette ──────────────────────────────────────────────────────────────────
SKIN      = (178, 140, 104)
SKIN_DK   = (138, 102,  68)
SKIN_SHD  = (105,  72,  42)
SKIN_LT   = (205, 168, 130)
SCAR_C    = (148,  86,  66)
SCAR_LT   = (178, 112,  88)
HAIR      = ( 20,  13,   8)
HAIR_HL   = ( 45,  30,  14)
CLOTH     = ( 42,  32,  20)
CLOTH_DK  = ( 26,  18,  11)
CLOTH_LT  = ( 65,  50,  33)
LEATHER   = ( 74,  52,  28)
LEATH_LT  = (108,  74,  42)
BELT_C    = ( 54,  38,  18)
WRAP      = (128, 102,  74)
WRAP_DK   = ( 92,  70,  46)
BOOT_C    = ( 40,  27,  14)
BOOT_DK   = ( 22,  14,   7)
BOOT_LT   = ( 60,  44,  26)
TRID_B    = ( 13,  13,  19)
TRID_MID  = ( 28,  28,  45)
TRID_HL   = ( 52,  52,  80)
TRID_BLD  = ( 50,  13,   9)
EYE_FIRE  = (232, 118,  36)
EYE_NRM   = (150, 124,  96)
EYE_PUP   = ( 10,   7,   4)
BLOOD     = ( 62,  15,  11)
CHAIN     = ( 52,  52,  60)
CHAIN_DK  = ( 32,  32,  40)
BRUISE    = ( 66,  50,  82)

# Staff colors
STAFF_B   = ( 18,  14,  24)    # dark shaft base
STAFF_MID = ( 36,  30,  52)    # shaft mid-tone
STAFF_HL  = ( 58,  48,  78)    # shaft highlight
STAFF_KNOT= ( 28,  22,  38)    # wood knots
ORB_CORE  = (217, 242, 255)    # bright white-blue center
ORB_MID   = (128, 204, 255)    # mid blue glow
ORB_OUTER = ( 77, 153, 255)    # outer blue
ORB_GLOW  = ( 51, 128, 255)    # glow fringe
ORB_DIM   = ( 38,  90, 180)    # dim edge

# ── Primitives ────────────────────────────────────────────────────────────────
def p(draw, x, y, col):
    cx, cy = CX + x, CY + y
    if 0 <= cx < W and 0 <= cy < H:
        draw.point((cx, cy), fill=col)

def r(draw, x, y, w, h, col):
    x1 = max(0, CX + x);   y1 = max(0, CY + y)
    x2 = min(W-1, CX+x+w-1); y2 = min(H-1, CY+y+h-1)
    if x1 <= x2 and y1 <= y2:
        draw.rectangle([x1, y1, x2, y2], fill=col)

def ln(draw, x1, y1, x2, y2, col, width=1):
    draw.line([(CX+x1, CY+y1), (CX+x2, CY+y2)], fill=col, width=width)

def ap(draw, x, y, col):
    """Absolute pixel."""
    if 0 <= x < W and 0 <= y < H:
        draw.point((x, y), fill=col)

# ── Trident ───────────────────────────────────────────────────────────────────
def _trident_upright(draw, sx, sy):
    """Black trident pointing up. sx,sy = grip start (absolute coords)."""
    tip_y = sy - 32
    # Shaft
    for y in range(tip_y, sy + 16):
        ap(draw, sx,   y, TRID_B)
        ap(draw, sx+1, y, TRID_MID)
    for y in range(tip_y + 3, sy + 14, 4):
        ap(draw, sx+1, y, TRID_HL)
    # Crosspiece at tip_y
    for dx in range(-7, 9):
        ap(draw, sx + dx, tip_y,     TRID_B)
        ap(draw, sx + dx, tip_y + 1, TRID_MID)
    ap(draw, sx - 8, tip_y - 1, TRID_B)
    ap(draw, sx + 9, tip_y - 1, TRID_B)
    # Left prong — angled up-left
    for t in range(10):
        lx = sx - 6 + (1 if t > 5 else 0)
        ly = tip_y - 1 - t
        ap(draw, lx,   ly, TRID_B)
        ap(draw, lx+1, ly, TRID_MID)
    for t in range(3):
        ap(draw, sx - 6, tip_y - 8 + t, TRID_BLD)
    # Center prong — straight up
    for t in range(14):
        ly = tip_y - 1 - t
        ap(draw, sx,   ly, TRID_B)
        ap(draw, sx+1, ly, TRID_HL if t > 8 else TRID_MID)
    for t in range(4):
        ap(draw, sx+1, tip_y - 1 - t, TRID_BLD)
    # Right prong — angled up-right
    for t in range(10):
        lx = sx + 7 - (1 if t > 5 else 0)
        ly = tip_y - 1 - t
        ap(draw, lx,   ly, TRID_B)
        ap(draw, lx-1, ly, TRID_MID)
    # Grip wrapping
    for t in range(12):
        col = WRAP if t % 2 == 0 else WRAP_DK
        y = sy + t
        ap(draw, sx-1, y, col)
        ap(draw, sx,   y, col)
        ap(draw, sx+1, y, WRAP_DK if col == WRAP else WRAP)
    for dx in range(-2, 4):
        ap(draw, sx + dx, sy,      LEATHER)
        ap(draw, sx + dx, sy,      LEATH_LT)
        ap(draw, sx + dx, sy + 12, LEATHER)
    # Pommel
    for dx in range(-2, 4):
        for dy in range(16, 19):
            ap(draw, sx + dx, sy + dy, LEATHER)
    ap(draw, sx,   sy + 17, LEATH_LT)
    ap(draw, sx+1, sy + 17, LEATH_LT)


def _trident_rotated(draw, sx, sy, angle):
    """Rotated trident. sx,sy = grip center (absolute). angle in radians, 0=up."""
    ca, sa = math.cos(angle), math.sin(angle)

    def rot(lx, ly):
        return (int(sx + lx * ca - ly * sa), int(sy + lx * sa + ly * ca))

    def rp(lx, ly, col):
        x, y = rot(lx, ly)
        ap(draw, x, y, col)

    # Shaft (ly negative = toward tip)
    for t in range(-32, 16):
        rp(0, t, TRID_B)
        rp(1, t, TRID_MID)
    for t in range(-30, 14, 4):
        rp(1, t, TRID_HL)
    # Crosspiece
    for dx in range(-7, 9):
        rp(dx, -32, TRID_B)
        rp(dx, -31, TRID_MID)
    rp(-8, -33, TRID_B)
    rp(9,  -33, TRID_B)
    # Left prong
    for t in range(10):
        lx = -6 + (1 if t > 5 else 0)
        rp(lx,   -33 - t, TRID_B)
        rp(lx+1, -33 - t, TRID_MID)
    for t in range(3):
        rp(-6, -40 + t, TRID_BLD)
    # Center prong
    for t in range(14):
        rp(0,  -33 - t, TRID_B)
        rp(1,  -33 - t, TRID_HL if t > 8 else TRID_MID)
    for t in range(4):
        rp(1, -33 - t, TRID_BLD)
    # Right prong
    for t in range(10):
        lx = 7 - (1 if t > 5 else 0)
        rp(lx,   -33 - t, TRID_B)
        rp(lx-1, -33 - t, TRID_MID)
    # Grip
    for t in range(12):
        col = WRAP if t % 2 == 0 else WRAP_DK
        rp(-1, t, col)
        rp(0,  t, col)
        rp(1,  t, WRAP_DK if col == WRAP else WRAP)
    for dx in range(-2, 4):
        rp(dx, 0,  LEATH_LT)
        rp(dx, 12, LEATHER)
    for dx in range(-2, 4):
        for dy in range(16, 19):
            rp(dx, dy, LEATHER)

# ── Staff ─────────────────────────────────────────────────────────────────────
def _staff_upright(draw, sx, sy):
    """Arcane staff pointing up. sx,sy = grip start (absolute coords)."""
    tip_y = sy - 32
    # Shaft — twisted dark wood, thinner than trident
    for y in range(tip_y + 6, sy + 16):
        ap(draw, sx,   y, STAFF_B)
        ap(draw, sx+1, y, STAFF_MID)
    # Shaft highlights — spiral pattern
    for y in range(tip_y + 8, sy + 14, 3):
        ap(draw, sx+1, y, STAFF_HL)
    # Wood knots
    for y in [tip_y + 12, tip_y + 22]:
        ap(draw, sx-1, y, STAFF_KNOT)
        ap(draw, sx,   y, STAFF_KNOT)
    # Twisted bark detail
    for y in range(tip_y + 8, sy + 10, 5):
        ap(draw, sx-1, y,   STAFF_MID)
        ap(draw, sx+2, y+2, STAFF_MID)

    # Crown — forked prongs cradling the orb
    for t in range(6):
        # Left prong curving inward
        lx = sx - 3 + (1 if t > 3 else 0)
        ly = tip_y + 5 - t
        ap(draw, lx,   ly, STAFF_B)
        ap(draw, lx+1, ly, STAFF_MID)
    for t in range(6):
        # Right prong curving inward
        lx = sx + 4 - (1 if t > 3 else 0)
        ly = tip_y + 5 - t
        ap(draw, lx,   ly, STAFF_B)
        ap(draw, lx-1, ly, STAFF_MID)

    # Orb — glowing blue-white crystal
    orb_cx, orb_cy = sx, tip_y
    # Glow fringe (5px radius)
    for dy in range(-5, 6):
        for dx in range(-5, 6):
            dist = (dx*dx + dy*dy) ** 0.5
            if 3.5 < dist <= 5.0:
                ap(draw, orb_cx + dx, orb_cy + dy, ORB_GLOW)
    # Outer ring (3px radius)
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            dist = (dx*dx + dy*dy) ** 0.5
            if 2.5 < dist <= 3.8:
                ap(draw, orb_cx + dx, orb_cy + dy, ORB_OUTER)
    # Mid ring
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            dist = (dx*dx + dy*dy) ** 0.5
            if 1.5 < dist <= 2.8:
                ap(draw, orb_cx + dx, orb_cy + dy, ORB_MID)
    # Core (bright center)
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            ap(draw, orb_cx + dx, orb_cy + dy, ORB_CORE)
    # Sparkle highlights
    ap(draw, orb_cx - 2, orb_cy - 2, ORB_CORE)
    ap(draw, orb_cx + 2, orb_cy + 1, ORB_CORE)

    # Grip wrapping (same as trident)
    for t in range(12):
        col = WRAP if t % 2 == 0 else WRAP_DK
        y = sy + t
        ap(draw, sx-1, y, col)
        ap(draw, sx,   y, col)
        ap(draw, sx+1, y, WRAP_DK if col == WRAP else WRAP)
    for dx in range(-2, 4):
        ap(draw, sx + dx, sy,      LEATH_LT)
        ap(draw, sx + dx, sy + 12, LEATHER)
    # Pommel — small metal cap
    for dx in range(-1, 3):
        for dy in range(16, 18):
            ap(draw, sx + dx, sy + dy, CHAIN)
    ap(draw, sx, sy + 17, CHAIN_DK)


def _staff_rotated(draw, sx, sy, angle):
    """Rotated staff. sx,sy = grip center (absolute). angle in radians, 0=up."""
    ca, sa = math.cos(angle), math.sin(angle)

    def rot(lx, ly):
        return (int(sx + lx * ca - ly * sa), int(sy + lx * sa + ly * ca))

    def rp(lx, ly, col):
        x, y = rot(lx, ly)
        ap(draw, x, y, col)

    # Shaft (ly negative = toward tip)
    for t in range(-26, 16):
        rp(0, t, STAFF_B)
        rp(1, t, STAFF_MID)
    for t in range(-24, 14, 3):
        rp(1, t, STAFF_HL)
    # Wood knots
    for t in [-20, -10]:
        rp(-1, t, STAFF_KNOT)
        rp(0, t, STAFF_KNOT)

    # Crown prongs
    for t in range(6):
        lx = -3 + (1 if t > 3 else 0)
        rp(lx,   -27 - t, STAFF_B)
        rp(lx+1, -27 - t, STAFF_MID)
    for t in range(6):
        lx = 4 - (1 if t > 3 else 0)
        rp(lx,   -27 - t, STAFF_B)
        rp(lx-1, -27 - t, STAFF_MID)

    # Orb (simplified for rotation)
    orb_ly = -32
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            dist = (dx*dx + dy*dy) ** 0.5
            if dist <= 1.5:
                rp(dx, orb_ly + dy, ORB_CORE)
            elif dist <= 2.8:
                rp(dx, orb_ly + dy, ORB_MID)
            elif dist <= 3.8:
                rp(dx, orb_ly + dy, ORB_OUTER)
            elif dist <= 4.5:
                rp(dx, orb_ly + dy, ORB_GLOW)

    # Grip
    for t in range(12):
        col = WRAP if t % 2 == 0 else WRAP_DK
        rp(-1, t, col)
        rp(0,  t, col)
        rp(1,  t, WRAP_DK if col == WRAP else WRAP)
    for dx in range(-2, 4):
        rp(dx, 0,  LEATH_LT)
        rp(dx, 12, LEATHER)
    for dx in range(-1, 3):
        for dy in range(16, 18):
            rp(dx, dy, CHAIN)


# ── Head — Front ──────────────────────────────────────────────────────────────
def _head_front(draw, oy):
    # Wild dark hair — longer, more disheveled
    hair_rows = {
        -37: range(-2, 4),
        -36: range(-5, 6),
        -35: range(-7, 8),
        -34: range(-8, 9),
        -33: range(-9, 10),
        -32: range(-9, 10),
        -31: range(-9, 10),
        -30: range(-9, 10),
        -29: range(-8, 9),
        -28: range(-8, 9),
    }
    for dy, rng in hair_rows.items():
        for dx in rng:
            p(draw, dx, dy+oy, HAIR)
    for dx in [-5, -2, 1, 4]:  p(draw, dx, -34+oy, HAIR_HL)
    for dx in [-3,  0, 3]:     p(draw, dx, -32+oy, HAIR_HL)
    p(draw, -10, -31+oy, HAIR); p(draw, 9, -30+oy, HAIR)
    p(draw,  -1, -37+oy, HAIR); p(draw, 2, -36+oy, HAIR)
    # Stray hair strands
    p(draw, -8, -29+oy, HAIR); p(draw, -9, -28+oy, HAIR)
    p(draw,  7, -29+oy, HAIR); p(draw,  8, -27+oy, HAIR)

    # Gaunt face
    face = {
        -28: range(-6,  7),
        -27: range(-7,  8),
        -26: range(-7,  8),
        -25: range(-7,  8),
        -24: range(-7,  8),
        -23: range(-7,  8),
        -22: range(-7,  8),
        -21: range(-6,  7),
        -20: range(-6,  7),
        -19: range(-5,  6),
        -18: range(-5,  6),
        -17: range(-5,  6),
        -16: range(-4,  5),
        -15: range(-4,  5),
        -14: range(-3,  4),
        -13: range(-2,  3),
    }
    for dy, rng in face.items():
        for dx in rng:
            p(draw, dx, dy+oy, SKIN)
    # Gaunt shadows — sunken cheeks
    for dy in [-23,-22,-21,-20,-19,-18]:
        p(draw, -6, dy+oy, SKIN_DK)
        p(draw, -5, dy+oy, SKIN_DK)
        p(draw,  4, dy+oy, SKIN_DK)
        p(draw,  5, dy+oy, SKIN_DK)
    # Deep-set eye sockets
    for dx in [-4,-3,-2]: p(draw, dx, -23+oy, SKIN_DK)
    for dx in [ 2, 3, 4]: p(draw, dx, -23+oy, SKIN_DK)
    for dx in [-4,-3,-2]: p(draw, dx, -24+oy, SKIN_DK)
    for dx in [ 2, 3, 4]: p(draw, dx, -24+oy, SKIN_DK)

    # Hairline
    for dx in range(-7, 8): p(draw, dx, -27+oy, HAIR)
    for dx in [-6,-5, 6, 7]: p(draw, dx, -26+oy, HAIR)
    for dx in [-5,-4, 5, 6]: p(draw, dx, -25+oy, HAIR)

    # Diagonal scar — left forehead across cheek
    scar = [(-6,-27),(-5,-26),(-4,-25),(-3,-24),(-2,-23),(-1,-22),(0,-21),(1,-20),(2,-19),(3,-18),(4,-17)]
    for sx2, sy2 in scar:
        p(draw, sx2,   sy2+oy, SCAR_C)
        p(draw, sx2+1, sy2+oy, SCAR_C)
    # Scar highlight edge
    for sx2, sy2 in scar[::2]:
        p(draw, sx2, sy2-1+oy, SCAR_LT)

    # Second scar — horizontal across chin
    for dx in range(-3, 3):
        p(draw, dx, -15+oy, SCAR_C)

    # Left eye — hell-branded (fiery orange glow)
    p(draw, -4, -22+oy, (255, 160, 50))
    p(draw, -3, -22+oy, EYE_FIRE)
    p(draw, -4, -21+oy, EYE_FIRE)
    p(draw, -3, -21+oy, (200, 80, 20))
    p(draw, -4, -20+oy, (180,  60, 10))
    p(draw, -3, -20+oy, (200,  80, 20))
    p(draw, -5, -23+oy, SKIN_SHD)
    p(draw, -2, -23+oy, SKIN_SHD)

    # Right eye — hollow, tired
    p(draw,  2, -22+oy, EYE_NRM)
    p(draw,  3, -22+oy, EYE_PUP)
    p(draw,  2, -21+oy, EYE_PUP)
    p(draw,  3, -21+oy, EYE_NRM)
    p(draw,  2, -20+oy, EYE_PUP)
    p(draw,  3, -20+oy, EYE_NRM)
    p(draw,  1, -23+oy, SKIN_SHD)
    p(draw,  4, -23+oy, SKIN_SHD)

    # Nose — bony, prominent
    p(draw, -1, -19+oy, SKIN_DK)
    p(draw,  0, -19+oy, SKIN_SHD)
    p(draw,  0, -18+oy, SKIN_DK)
    p(draw, -1, -18+oy, SKIN_LT)

    # Grim set mouth
    for dx in range(-3, 4): p(draw, dx, -15+oy, SKIN_DK)
    p(draw, -3, -15+oy, SKIN_SHD)
    p(draw,  3, -15+oy, SKIN_SHD)
    for dx in range(-2, 3): p(draw, dx, -14+oy, SKIN_DK)

    # Stubble / grime
    for dx, dy in [(-6,-19),(-5,-19),(-6,-18),(-5,-18),(4,-19),(5,-19),(4,-18),(5,-18)]:
        p(draw, dx, dy+oy, SKIN_DK)
    for dx in [-4,-3, 3, 4]: p(draw, dx, -16+oy, SKIN_DK)

    # Neck — scarred, with vein
    for dy in range(-12, -7):
        for dx in range(-3, 4):
            p(draw, dx, dy+oy, SKIN_DK)
    p(draw, 0, -11+oy, SKIN); p(draw, 0, -9+oy, SKIN)
    # Neck scar / brand mark
    p(draw, -2, -10+oy, SCAR_C); p(draw, -1, -10+oy, SCAR_C)
    p(draw,  1, -10+oy, SCAR_C); p(draw,  2, -10+oy, SCAR_C)

# ── Head — Back ───────────────────────────────────────────────────────────────
def _head_back(draw, oy):
    hair = {
        -37: range(-3, 5),
        -36: range(-6, 7),
        -35: range(-8, 9),
        -34: range(-9,10),
        -33: range(-9,10),
        -32: range(-9,10),
        -31: range(-9,10),
        -30: range(-9,10),
        -29: range(-8, 9),
        -28: range(-8, 9),
        -27: range(-8, 9),
        -26: range(-8, 9),
        -25: range(-7, 8),
        -24: range(-7, 8),
        -23: range(-7, 8),
        -22: range(-7, 8),
        -21: range(-7, 8),
        -20: range(-6, 7),
    }
    for dy, rng in hair.items():
        for dx in rng:
            p(draw, dx, dy+oy, HAIR)
    for dx in range(-7, 8, 2): p(draw, dx, -34+oy, HAIR_HL)
    for dx in [-4, 0, 4]:      p(draw, dx, -30+oy, HAIR_HL)
    p(draw, -10, -29+oy, HAIR); p(draw, 9, -28+oy, HAIR)
    # Neck back — visible binding marks
    for dy in range(-18, -12):
        for dx in range(-3, 4):
            p(draw, dx, dy+oy, SKIN_DK)
    p(draw, 0, -16+oy, SKIN); p(draw, 0, -14+oy, SKIN)
    # Chain mark on neck
    for dx in range(-3, 4):
        p(draw, dx, -12+oy, CHAIN)
    for dx in [-3, 0, 3]:
        p(draw, dx, -13+oy, CHAIN_DK)

# ── Head — Side ───────────────────────────────────────────────────────────────
def _head_side(draw, oy):
    # Hair (right profile)
    for dy in range(-37, -20):
        half = max(0, 8 - abs(dy + 28) // 2)
        for dx in range(-half, half + 2):
            p(draw, dx, dy+oy, HAIR)
    for t in [(-1,-29),(1,-27),(3,-25)]:
        p(draw, t[0], t[1]+oy, HAIR_HL)
    # Stray strands forward
    p(draw, 5, -28+oy, HAIR); p(draw, 6, -27+oy, HAIR)
    p(draw, 5, -26+oy, HAIR); p(draw, 6, -25+oy, HAIR)

    # Face profile
    profile = {
        -28: range(0, 7), -27: range(-1, 7),
        -26: range(-1, 7), -25: range(-1, 7),
        -24: range(-1, 7), -23: range(-1, 7),
        -22: range(-1, 8), -21: range(-1, 8),
        -20: range(-1, 7), -19: range(-1, 7),
        -18: range(-1, 7), -17: range(-1, 6),
        -16: range(-1, 6), -15: range(-1, 5),
        -14: range(-1, 5), -13: range(-1, 4),
        -12: range(0, 4),
    }
    for dy, rng in profile.items():
        for dx in rng:
            p(draw, dx, dy+oy, SKIN)
    # Profile shadow (back of face)
    for dy in range(-28, -12): p(draw, -1, dy+oy, SKIN_DK)
    # Cheek hollow
    for dy in [-21,-20,-19,-18]: p(draw, 5, dy+oy, SKIN_DK)

    # Scar from profile
    for t in range(6):
        p(draw, 1+t, -24+t+oy, SCAR_C)
        p(draw, 2+t, -24+t+oy, SCAR_C)

    # Glowing eye
    p(draw, 4, -22+oy, EYE_FIRE)
    p(draw, 5, -22+oy, EYE_FIRE)
    p(draw, 4, -21+oy, (200, 80, 20))
    p(draw, 3, -23+oy, SKIN_SHD)
    p(draw, 6, -23+oy, SKIN_SHD)

    # Nose/jaw profile
    p(draw, 7, -19+oy, SKIN_SHD)
    p(draw, 7, -18+oy, SKIN_DK)
    p(draw, 7, -17+oy, SKIN_SHD)
    p(draw, 6, -16+oy, SKIN_DK)
    p(draw, 5, -15+oy, SKIN_DK)
    p(draw, 5, -14+oy, SKIN)
    p(draw, 4, -13+oy, SKIN)

    # Neck
    for dy in range(-12, -7):
        for dx in range(-1, 3):
            p(draw, dx, dy+oy, SKIN_DK)
    p(draw, 1, -10+oy, SKIN)

    # Hairline
    p(draw, 4, -27+oy, HAIR); p(draw, 5, -27+oy, HAIR)
    p(draw, 6, -26+oy, HAIR); p(draw, 6, -25+oy, HAIR)

# ── Weapon helpers ────────────────────────────────────────────────────────────
def _weapon_front(draw, oy, arm_angle):
    sx = CX + 15;  sy = CY - 15 + oy
    if abs(arm_angle) < 0.02:
        _trident_upright(draw, sx, sy)
        # Arm holding trident
        r(draw, 10, -17+oy,  6, 10, CLOTH_DK)
        r(draw, 10,  -7+oy,  6,  9, WRAP_DK)
        r(draw, 11,  -7+oy,  5,  8, WRAP)
        r(draw, 10,   2+oy,  5,  3, SKIN_DK)
        # Chain mark on wrist
        for dy in range(2, 4):
            p(draw, 10, dy+oy, CHAIN)
            p(draw, 13, dy+oy, CHAIN)
    else:
        _trident_rotated(draw, sx, sy, arm_angle)
        # Rotating arm
        r(draw, 10, -17+oy,  6, 10, CLOTH_DK)
        r(draw, 10,  -7+oy,  6,  9, WRAP_DK)
        r(draw, 10,   2+oy,  5,  3, SKIN_DK)


def _weapon_back(draw, oy, arm_angle):
    sx = CX + 13;  sy = CY - 13 + oy
    if abs(arm_angle) < 0.02:
        _trident_upright(draw, sx, sy)
        r(draw, 8, -15+oy, 6, 10, CLOTH_DK)
        r(draw, 8,  -5+oy, 6,  9, WRAP_DK)
    else:
        _trident_rotated(draw, sx, sy, arm_angle)
        r(draw, 8, -15+oy, 6, 10, CLOTH_DK)
        r(draw, 8,  -5+oy, 6,  9, WRAP_DK)


def _weapon_side(draw, oy, arm_angle):
    sx = CX + 10;  sy = CY - 14 + oy
    if abs(arm_angle) < 0.02:
        _trident_upright(draw, sx, sy)
        r(draw,  6, -15+oy, 5, 10, CLOTH_DK)
        r(draw,  6,  -5+oy, 5,  9, WRAP_DK)
        r(draw,  6,   4+oy, 4,  3, SKIN_DK)
    else:
        _trident_rotated(draw, sx, sy, arm_angle)
        r(draw,  6, -15+oy, 5, 10, CLOTH_DK)
        r(draw,  6,  -5+oy, 5,  9, WRAP_DK)
        r(draw,  6,   4+oy, 4,  3, SKIN_DK)

# ── Staff weapon helpers ─────────────────────────────────────────────────────
def _staff_weapon_front(draw, oy, arm_angle):
    sx = CX + 15;  sy = CY - 15 + oy
    if abs(arm_angle) < 0.02:
        _staff_upright(draw, sx, sy)
        r(draw, 10, -17+oy,  6, 10, CLOTH_DK)
        r(draw, 10,  -7+oy,  6,  9, WRAP_DK)
        r(draw, 11,  -7+oy,  5,  8, WRAP)
        r(draw, 10,   2+oy,  5,  3, SKIN_DK)
        for dy in range(2, 4):
            p(draw, 10, dy+oy, CHAIN)
            p(draw, 13, dy+oy, CHAIN)
    else:
        _staff_rotated(draw, sx, sy, arm_angle)
        r(draw, 10, -17+oy,  6, 10, CLOTH_DK)
        r(draw, 10,  -7+oy,  6,  9, WRAP_DK)
        r(draw, 10,   2+oy,  5,  3, SKIN_DK)


def _staff_weapon_back(draw, oy, arm_angle):
    sx = CX + 13;  sy = CY - 13 + oy
    if abs(arm_angle) < 0.02:
        _staff_upright(draw, sx, sy)
        r(draw, 8, -15+oy, 6, 10, CLOTH_DK)
        r(draw, 8,  -5+oy, 6,  9, WRAP_DK)
    else:
        _staff_rotated(draw, sx, sy, arm_angle)
        r(draw, 8, -15+oy, 6, 10, CLOTH_DK)
        r(draw, 8,  -5+oy, 6,  9, WRAP_DK)


def _staff_weapon_side(draw, oy, arm_angle):
    sx = CX + 10;  sy = CY - 14 + oy
    if abs(arm_angle) < 0.02:
        _staff_upright(draw, sx, sy)
        r(draw,  6, -15+oy, 5, 10, CLOTH_DK)
        r(draw,  6,  -5+oy, 5,  9, WRAP_DK)
        r(draw,  6,   4+oy, 4,  3, SKIN_DK)
    else:
        _staff_rotated(draw, sx, sy, arm_angle)
        r(draw,  6, -15+oy, 5, 10, CLOTH_DK)
        r(draw,  6,  -5+oy, 5,  9, WRAP_DK)
        r(draw,  6,   4+oy, 4,  3, SKIN_DK)


# ── Body draw functions ───────────────────────────────────────────────────────
def draw_front(draw, oy=0, llo=0, rlo=0, arm_angle=0.0, left_arm_fwd=0.0, weapon="trident"):
    # Left arm (behind body, free arm — swings with walk)
    la_y = int(left_arm_fwd * 4)
    r(draw, -18, -18+oy+la_y,  6, 11, CLOTH_DK)
    r(draw, -18,  -7+oy+la_y,  6,  9, WRAP_DK)
    r(draw, -17,  -7+oy+la_y,  4,  8, WRAP)
    r(draw, -18,   2+oy+la_y,  5,  3, SKIN_DK)
    # Scars on left arm
    for dy in range(-14, -9): p(draw, -15, dy+oy+la_y, SCAR_C)
    p(draw, -14, -12+oy+la_y, SCAR_C)
    p(draw, -14, -10+oy+la_y, SCAR_C)
    # Chain mark on left wrist
    p(draw, -18,  2+oy+la_y, CHAIN)
    p(draw, -14,  2+oy+la_y, CHAIN)

    # Left leg
    r(draw, -11,  10+oy+llo, 8, 6, CLOTH_DK)
    r(draw, -11,  16+oy+llo, 8, 6, CLOTH)
    r(draw, -12,  22+oy+llo, 9, 4, BOOT_C)
    r(draw, -12,  22+oy+llo, 9, 2, BOOT_DK)
    r(draw, -11,  24+oy+llo, 7, 1, BOOT_LT)
    p(draw, -8,  11+oy+llo, CLOTH_LT); p(draw, -8, 14+oy+llo, CLOTH_LT)
    # Torn cloth edge
    for dx in [-11, -10]: p(draw, dx, 16+oy+llo, CLOTH_DK)

    # Right leg
    r(draw,  3,  10+oy+rlo, 8, 6, CLOTH)
    r(draw,  3,  16+oy+rlo, 8, 6, CLOTH_DK)
    r(draw,  3,  22+oy+rlo, 9, 4, BOOT_C)
    r(draw,  3,  22+oy+rlo, 9, 2, BOOT_DK)
    r(draw,  4,  24+oy+rlo, 7, 1, BOOT_LT)
    p(draw,  7,  11+oy+rlo, CLOTH_LT); p(draw, 7, 14+oy+rlo, CLOTH_LT)

    # Torso
    r(draw, -12, -20+oy, 24, 26, CLOTH)
    r(draw, -12, -18+oy,  3, 24, CLOTH_DK)
    r(draw,   9, -18+oy,  3, 24, CLOTH_DK)
    r(draw,  -9, -18+oy, 18,  6, CLOTH_LT)
    # Cloth tears / battle damage
    ln(draw, -9, -5+oy, -9,  1+oy, CLOTH_DK)
    ln(draw,  7, -8+oy,  8, -2+oy, CLOTH_LT)
    for dx, dy in [(-10,-3),(-11,-2),(-10,-1)]:
        p(draw, dx, dy+oy, CLOTH_DK)
    # Blood stains on torso
    for dx, dy in [(-4,-10),(-3,-9),(-4,-9),(-5,-10),(-3,-11),(-5,-11)]:
        p(draw, dx, dy+oy, BLOOD)
    # Belly scars (horizontal)
    for dx in range(-5, 4): p(draw, dx, -2+oy, SCAR_C)
    for dx in range(-3, 2): p(draw, dx,  1+oy, SCAR_C)

    # Shoulder pads (leather)
    r(draw, -18, -20+oy,  7,  9, LEATHER)
    r(draw,  11, -20+oy,  7,  9, LEATHER)
    r(draw, -18, -20+oy,  7,  2, LEATH_LT)
    r(draw,  11, -20+oy,  7,  2, LEATH_LT)
    p(draw, -15, -16+oy, LEATH_LT); p(draw, -13, -16+oy, LEATH_LT)
    p(draw,  12, -16+oy, LEATH_LT); p(draw,  14, -16+oy, LEATH_LT)
    # Rivet detail
    p(draw, -16, -18+oy, LEATH_LT); p(draw, 14, -18+oy, LEATH_LT)

    # Diagonal baldric
    for t in range(22):
        lsx = -9 + t;  lsy = -16 + int(t * 1.0)
        p(draw, lsx,   lsy+oy, LEATHER)
        p(draw, lsx, lsy+1+oy, LEATHER)
        if t % 5 == 0: p(draw, lsx, lsy+oy, LEATH_LT)

    # Belt
    r(draw, -12,  6+oy, 24, 5, BELT_C)
    r(draw,  -3,  6+oy,  6, 5, LEATH_LT)
    p(draw,   0,  8+oy, LEATHER)
    p(draw,   1,  8+oy, LEATHER)

    _head_front(draw, oy)
    if weapon == "staff":
        _staff_weapon_front(draw, oy, arm_angle)
    else:
        _weapon_front(draw, oy, arm_angle)


def draw_back(draw, oy=0, llo=0, rlo=0, arm_angle=0.0, left_arm_fwd=0.0, weapon="trident"):
    if weapon == "staff":
        _staff_weapon_back(draw, oy, arm_angle)
    else:
        _weapon_back(draw, oy, arm_angle)

    # Legs
    r(draw, -11,  10+oy+llo, 8, 6, CLOTH_DK)
    r(draw, -11,  16+oy+llo, 8, 6, CLOTH)
    r(draw, -12,  22+oy+llo, 9, 4, BOOT_C)
    r(draw, -12,  22+oy+llo, 9, 2, BOOT_DK)
    r(draw, -11,  24+oy+llo, 7, 1, BOOT_LT)
    r(draw,   3,  10+oy+rlo, 8, 6, CLOTH)
    r(draw,   3,  16+oy+rlo, 8, 6, CLOTH_DK)
    r(draw,   3,  22+oy+rlo, 9, 4, BOOT_C)
    r(draw,   3,  22+oy+rlo, 9, 2, BOOT_DK)
    r(draw,   4,  24+oy+rlo, 7, 1, BOOT_LT)

    # Torso back
    r(draw, -12, -20+oy, 24, 26, CLOTH_DK)
    r(draw, -12, -18+oy,  3, 24, CLOTH)
    r(draw,   9, -18+oy,  3, 24, CLOTH)
    ln(draw, 0, -18+oy, 0, 6+oy, (18, 12, 8))
    # Back scars — horizontal whip marks
    for i, dy in enumerate([-12, -8, -4, 0]):
        w2 = 8 - i
        for dx in range(-w2, w2+1):
            p(draw, dx, dy+oy, SCAR_C)
        for dx in range(-w2+1, w2, 2):
            p(draw, dx, dy-1+oy, SCAR_LT)
    # Shoulder pads
    r(draw, -18, -20+oy,  7,  9, LEATHER)
    r(draw,  11, -20+oy,  7,  9, LEATHER)
    r(draw, -18, -20+oy,  7,  2, LEATH_LT)
    r(draw,  11, -20+oy,  7,  2, LEATH_LT)

    # Left arm back (free)
    la_y = int(left_arm_fwd * 4)
    r(draw, -18, -18+oy+la_y,  6, 11, CLOTH_DK)
    r(draw, -18,  -7+oy+la_y,  6,  9, WRAP_DK)
    for dy in range(-14, -9): p(draw, -16, dy+oy+la_y, SCAR_C)

    # Belt
    r(draw, -12, 6+oy, 24, 5, BELT_C)
    # Chain on wrists visible from back
    for dy in range(2, 4):
        p(draw, -18, dy+oy+la_y, CHAIN)
        p(draw, -14, dy+oy+la_y, CHAIN)

    _head_back(draw, oy)


def draw_side(draw, oy=0, llo=0, rlo=0, arm_angle=0.0, left_arm_fwd=0.0, weapon="trident"):
    # Back arm (behind body — left arm, swings with walk)
    la_y = int(left_arm_fwd * 3)
    r(draw, -12, -16+oy+la_y, 5, 11, CLOTH_DK)
    r(draw, -12,  -5+oy+la_y, 5,  9, WRAP_DK)
    r(draw, -12,   4+oy+la_y, 4,  3, SKIN_DK)

    # Back leg
    r(draw, -5,  10+oy+rlo, 7, 6, CLOTH_DK)
    r(draw, -5,  16+oy+rlo, 7, 6, CLOTH)
    r(draw, -6,  22+oy+rlo, 8, 4, BOOT_DK)
    r(draw, -6,  22+oy+rlo, 8, 2, BOOT_C)

    # Front leg
    r(draw, -4,  10+oy+llo, 7, 6, CLOTH)
    r(draw, -4,  16+oy+llo, 7, 6, CLOTH_DK)
    r(draw, -5,  22+oy+llo, 8, 4, BOOT_C)
    r(draw, -5,  22+oy+llo, 8, 2, BOOT_DK)
    r(draw, -4,  24+oy+llo, 6, 1, BOOT_LT)

    # Torso side (thinner, slight lean)
    r(draw, -7, -20+oy,  8, 26, CLOTH_DK)
    r(draw,  1, -20+oy,  9, 26, CLOTH)
    r(draw,  9, -18+oy,  1, 22, CLOTH_LT)
    # Side shoulder
    r(draw,  3, -20+oy,  8,  9, LEATHER)
    r(draw,  3, -20+oy,  8,  2, LEATH_LT)
    # Belt
    r(draw, -9,  6+oy, 18, 5, BELT_C)
    p(draw, 4,  8+oy, LEATH_LT)
    # Baldric from side
    for t in range(13):
        p(draw, 0+t, -14+int(t*1.1)+oy, LEATHER)
        p(draw, 0+t, -13+int(t*1.1)+oy, LEATHER)
    # Side torso blood
    for dx, dy in [(-3,-8),(-2,-7),(-3,-7)]:
        p(draw, dx, dy+oy, BLOOD)

    _head_side(draw, oy)
    if weapon == "staff":
        _staff_weapon_side(draw, oy, arm_angle)
    else:
        _weapon_side(draw, oy, arm_angle)

# ── Frame building ────────────────────────────────────────────────────────────
def make_frame(draw_func, **kwargs):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw_func(ImageDraw.Draw(img), **kwargs)
    return img

def tint_red(img, factor=0.6):
    pix = img.load()
    for y in range(img.height):
        for x in range(img.width):
            rr, g, b, a = pix[x, y]
            if a > 0:
                rr = int(rr + (255 - rr) * factor)
                g  = int(g  * (1 - factor) + 30 * factor)
                b  = int(b  * (1 - factor) + 20 * factor)
                pix[x, y] = (min(255, rr), g, b, a)
    return img

def generate_spritesheet(weapon="trident"):
    frames = []
    frame_info = []

    def add(name, dur, func, **kwargs):
        frames.append(make_frame(func, weapon=weapon, **kwargs))
        frame_info.append((name, dur))

    # ── IDLE — 4 frames, pingpong (natural breathing) ────────────────────
    idle_params = [
        dict(oy=0),
        dict(oy=-1),
        dict(oy=-2),
        dict(oy=-1),
    ]
    idle_durs = [600, 300, 600, 300]
    for dir_name, fn in [("down", draw_front), ("up", draw_back), ("right", draw_side)]:
        for i, (ip, dur) in enumerate(zip(idle_params, idle_durs)):
            add(f"idle_{dir_name}_{i+1}", dur, fn, **ip)

    # ── WALK — 8 frames, smooth stride with arm counter-swing ────────────
    walk_params = [
        dict(oy= 0, llo= 0, rlo= 0, left_arm_fwd= 0.0),
        dict(oy=-1, llo=-2, rlo= 2, left_arm_fwd= 0.4),
        dict(oy=-2, llo=-4, rlo= 4, left_arm_fwd= 0.8),
        dict(oy=-1, llo=-2, rlo= 2, left_arm_fwd= 0.4),
        dict(oy= 0, llo= 0, rlo= 0, left_arm_fwd= 0.0),
        dict(oy=-1, llo= 2, rlo=-2, left_arm_fwd=-0.4),
        dict(oy=-2, llo= 4, rlo=-4, left_arm_fwd=-0.8),
        dict(oy=-1, llo= 2, rlo=-2, left_arm_fwd=-0.4),
    ]
    for dir_name, fn in [("down", draw_front), ("up", draw_back), ("right", draw_side)]:
        for i, wp in enumerate(walk_params):
            add(f"walk_{dir_name}_{i+1}", 80, fn, **wp)

    # ── ATTACK — 8 frames ────────────────────────────────────────────────
    if weapon == "staff":
        # Staff cast: raise up → channel → thrust forward → recover
        atk_params = [
            dict(oy= 0, arm_angle=-0.8),   # 1 raise staff
            dict(oy=-1, arm_angle=-1.4),   # 2 channel up
            dict(oy=-2, arm_angle=-1.8),   # 3 peak channel (orb glows)
            dict(oy=-2, arm_angle=-1.4),   # 4 hold
            dict(oy=-1, arm_angle=-0.6),   # 5 thrust forward
            dict(oy= 0, arm_angle= 0.0),   # 6 release (projectile fires)
            dict(oy= 0, arm_angle= 0.3),   # 7 follow-through
            dict(oy=-1, arm_angle= 0.0),   # 8 recover
        ]
        atk_durs = [70, 80, 90, 60, 50, 40, 70, 100]
    else:
        # Trident melee: windup → coil → burst → strike → recover
        atk_params = [
            dict(oy= 0, arm_angle=-1.4),
            dict(oy=-2, arm_angle=-2.0),
            dict(oy=-3, arm_angle=-2.6),
            dict(oy= 0, arm_angle=-1.6),
            dict(oy= 1, arm_angle=-0.8),
            dict(oy= 2, arm_angle= 0.0),
            dict(oy= 1, arm_angle= 0.6),
            dict(oy=-1, arm_angle= 0.0),
        ]
        atk_durs = [60, 70, 80, 45, 40, 40, 80, 100]
    for dir_name, fn in [("down", draw_front), ("up", draw_back), ("right", draw_side)]:
        for i, (ap2, dur) in enumerate(zip(atk_params, atk_durs)):
            add(f"attack_{dir_name}_{i+1}", dur, fn, **ap2)

    # ── HURT — 3 frames ──────────────────────────────────────────────────
    hurt_base  = make_frame(draw_front, oy=0, weapon=weapon)
    hurt_flash = tint_red(make_frame(draw_front, oy=0, weapon=weapon), 0.8)
    hurt_back  = make_frame(draw_front, oy=1, weapon=weapon)
    frames += [hurt_base, hurt_flash, hurt_back]
    frame_info += [("hurt_down_1", 50), ("hurt_down_2", 80), ("hurt_down_3", 120)]

    # ── DIE — 5 frames ───────────────────────────────────────────────────
    for i, (alpha_mult, tint) in enumerate([(1.0,0.0),(0.85,0.2),(0.65,0.4),(0.35,0.6),(0.1,0.8)]):
        die_img = make_frame(draw_front, oy=0, weapon=weapon)
        pix = die_img.load()
        for y in range(die_img.height):
            for x in range(die_img.width):
                rr, g, b, a = pix[x, y]
                if a > 0:
                    rr = int(rr + (255 - rr) * tint)
                    g  = int(g  * (1 - tint) + 38 * tint)
                    b  = int(b  * (1 - tint) + 25 * tint)
                    a  = int(a  * alpha_mult)
                    pix[x, y] = (min(255, rr), g, b, a)
        frames.append(die_img)
        frame_info.append((f"die_down_{i+1}", 150))

    # ── Spritesheet assembly ──────────────────────────────────────────────
    cols = 8
    rows = math.ceil(len(frames) / cols)
    sheet = Image.new('RGBA', (cols * W, rows * H), (0, 0, 0, 0))
    json_frames = {}

    for idx, (img, (name, dur)) in enumerate(zip(frames, frame_info)):
        col = idx % cols;  row = idx // cols
        px_x = col * W;    px_y = row * H
        sheet.paste(img, (px_x, px_y))
        json_frames[name] = {"frame": {"x": px_x, "y": px_y, "w": W, "h": H}, "duration": dur}

    suffix = "" if weapon == "trident" else f"_{weapon}"
    out_dir = "assets/sprites/player"
    os.makedirs(out_dir, exist_ok=True)
    sheet.save(f"{out_dir}/player{suffix}.png")

    meta = {
        "frames": json_frames,
        "meta": {
            "size": {"w": cols * W, "h": rows * H},
            "frame_size": {"w": W, "h": H},
            "scale": 1
        },
        "animations": {
            "idle_down":    {"frames": [f"idle_down_{i+1}"    for i in range(4)], "loop": "pingpong"},
            "idle_up":      {"frames": [f"idle_up_{i+1}"      for i in range(4)], "loop": "pingpong"},
            "idle_right":   {"frames": [f"idle_right_{i+1}"   for i in range(4)], "loop": "pingpong"},
            "walk_down":    {"frames": [f"walk_down_{i+1}"    for i in range(8)], "loop": "forward"},
            "walk_up":      {"frames": [f"walk_up_{i+1}"      for i in range(8)], "loop": "forward"},
            "walk_right":   {"frames": [f"walk_right_{i+1}"   for i in range(8)], "loop": "forward"},
            "attack_down":  {"frames": [f"attack_down_{i+1}"  for i in range(8)], "loop": "forward"},
            "attack_up":    {"frames": [f"attack_up_{i+1}"    for i in range(8)], "loop": "forward"},
            "attack_right": {"frames": [f"attack_right_{i+1}" for i in range(8)], "loop": "forward"},
            "hurt_down":    {"frames": [f"hurt_down_{i+1}"    for i in range(3)], "loop": "forward"},
            "die_down":     {"frames": [f"die_down_{i+1}"     for i in range(5)], "loop": "forward"},
        }
    }

    with open(f"{out_dir}/player{suffix}.json", "w") as f:
        json.dump(meta, f, indent=2)

    print(f"Player ({weapon}) spritesheet: {cols*W}x{rows*H}, {len(frames)} frames, {W}x{H} per frame")

# ── CLI ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--weapon", choices=["trident", "staff", "all"], default="all")
    args = parser.parse_args()

    if args.weapon == "all":
        generate_spritesheet("trident")
        generate_spritesheet("staff")
    else:
        generate_spritesheet(args.weapon)
