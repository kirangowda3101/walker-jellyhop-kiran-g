#!/usr/bin/env python3
"""Draw the Batch 2 environment guides for SDXL image-to-image.

ENV-PLATE-guide.png: edge-on (eye-level side view) white plate on flat #FF00FF, 1344 x 768.
  A thin top ellipse shows the flat landing surface; the body tapers to a foot ring.
ENV-FORK-guide.png: fork pointing straight down on flat #FF00FF, 768 x 1344 (portrait);
  handle runs off the top edge, four pointed tines at the bottom, grey steel, one highlight.
ENV-DOME-guide.png: empty clear glass dome seen from the side on flat #FF00FF, 1024 x 1024;
  thin dark outline, knob on top, flat base rim, white highlights; interior left flat magenta
  so the later difference matte can make the glass see-through.
ENV-SAUCE-guide.png: low flat puddle of red-brown sauce seen from the side at eye level,
  on flat #FF00FF, 1344 x 768; flat bottom, gently bumpy top, one small highlight.
Drawn at 4x and downsampled for smooth edges. Deterministic: same output every run.

Usage: python3 tools/make_env_guides.py OUT_DIR
Prints the output path, size, and pixel fingerprint (first 16 hex of sha256 of RGB bytes).
"""
import hashlib
import math
import os
import sys

from PIL import Image, ImageDraw

W, H = 1344, 768
S = 4  # supersampling factor
MAGENTA = (255, 0, 255)
OUTLINE = (31, 27, 26)
TOP = (243, 240, 233)      # rim / landing surface
WELL = (228, 223, 213)     # shallow center of the plate, slightly darker
BODY_TOP = (226, 220, 208)
BODY_BOTTOM = (188, 180, 166)
FOOT = (206, 199, 187)
HIGHLIGHT = (255, 255, 255)
OUTLINE_W = 9   # game-art outline thickness at 1x (outside the shapes)
INNER_W = 4     # line between top surface and side at 1x

CX = 672
RIM_Y, RIM_RX, RIM_RY = 340, 500, 24
WELL_Y, WELL_RX, WELL_RY = 343, 375, 14
FOOT_X0, FOOT_X1, FOOT_Y0, FOOT_Y1 = 470, 874, 412, 432


def s(pts):
    return [(x * S, y * S) for x, y in pts]


def ellipse_pts(cx, cy, rx, ry, a0=0.0, a1=2 * math.pi, n=360):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n),
             cy + ry * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def bezier(p0, p1, p2, p3, n=120):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def body_pts():
    left = (CX - RIM_RX, RIM_Y)
    right = (CX + RIM_RX, RIM_Y)
    fl = (FOOT_X0 - 20, FOOT_Y0 + 2)
    fr = (FOOT_X1 + 20, FOOT_Y0 + 2)
    pts = bezier(left, (CX - RIM_RX + 30, RIM_Y + 38), (CX - 330, FOOT_Y0), fl)
    pts += bezier(fr, (CX + 330, FOOT_Y0), (CX + RIM_RX - 30, RIM_Y + 38), right)
    return pts


def foot_pts():
    r = 8
    return [(FOOT_X0, FOOT_Y0), (FOOT_X1, FOOT_Y0), (FOOT_X1, FOOT_Y1 - r),
            (FOOT_X1 - r, FOOT_Y1), (FOOT_X0 + r, FOOT_Y1), (FOOT_X0, FOOT_Y1 - r)]


def save(img, out_dir, name):
    w, h = img.width // S, img.height // S
    out = img.resize((w, h), Image.LANCZOS)
    path = os.path.join(out_dir, name)
    out.save(path)
    fp = hashlib.sha256(out.tobytes()).hexdigest()[:16]
    print(f"{path}  {w}x{h}  fingerprint {fp}")


def make_plate(out_dir):
    img = Image.new("RGB", (W * S, H * S), MAGENTA)
    d = ImageDraw.Draw(img)
    rim = ellipse_pts(CX, RIM_Y, RIM_RX, RIM_RY)
    shapes = [body_pts(), foot_pts(), rim]

    # 1. Outline: each silhouette shape filled and stroked in outline color.
    for pts in shapes:
        sp = s(pts)
        d.polygon(sp, fill=OUTLINE)
        d.line(sp + [sp[0]], fill=OUTLINE, width=2 * OUTLINE_W * S, joint="curve")

    # 2. Body with a vertical gradient, then foot.
    grad = Image.new("RGB", (W * S, H * S))
    gd = ImageDraw.Draw(grad)
    y0, y1 = RIM_Y * S, FOOT_Y0 * S
    for y in range(y0, y1 + 1):
        t = (y - y0) / max(1, y1 - y0)
        c = tuple(round(a + (b - a) * t) for a, b in zip(BODY_TOP, BODY_BOTTOM))
        gd.line([(0, y), (W * S, y)], fill=c)
    mask = Image.new("L", (W * S, H * S), 0)
    ImageDraw.Draw(mask).polygon(s(body_pts()), fill=255)
    img.paste(grad, (0, 0), mask)
    d.polygon(s(foot_pts()), fill=FOOT)

    # 3. Top surface (landing surface) and shallow well.
    d.polygon(s(rim), fill=TOP)
    d.polygon(s(ellipse_pts(CX, WELL_Y, WELL_RX, WELL_RY)), fill=WELL)

    # 4. Line where the top surface meets the side (lower half of the rim ellipse).
    d.line(s(ellipse_pts(CX, RIM_Y, RIM_RX, RIM_RY, 0, math.pi)),
           fill=OUTLINE, width=INNER_W * S, joint="curve")

    # 5. One soft highlight on the near side of the body.
    d.line(s(bezier((CX - 300, RIM_Y + 34), (CX - 200, RIM_Y + 48),
                    (CX - 60, RIM_Y + 52), (CX + 40, RIM_Y + 52))),
           fill=HIGHLIGHT, width=6 * S, joint="curve")

    save(img, out_dir, "ENV-PLATE-guide.png")


# Sauce puddle: about 6:1 (game size ~120 x 20 px).
SAUCE_BODY = (180, 71, 42)       # placeholder sauce color #B4472A
SAUCE_SHADE = (122, 42, 24)      # darker toward the bottom
SAUCE_HIGHLIGHT = (244, 184, 160)
SX0, SX1, S_BOTTOM, S_TOP = 222, 1122, 448, 322


def sauce_pts():
    # Flat bottom; gently undulating top (smooth joins), tallest near the middle; rounded ends.
    left, right = (SX0, S_BOTTOM - 6), (SX1, S_BOTTOM - 6)
    p1 = (SX0 + 250, S_TOP + 18)
    p2 = (CX + 20, S_TOP)
    p3 = (SX1 - 240, S_TOP + 22)
    top = bezier(left, (SX0 - 6, S_BOTTOM - 80), (SX0 + 110, S_TOP + 22), p1)
    top += bezier(p1, (SX0 + 330, S_TOP + 15), (CX - 80, S_TOP), p2)[1:]
    top += bezier(p2, (CX + 90, S_TOP), (SX1 - 330, S_TOP + 19), p3)[1:]
    top += bezier(p3, (SX1 - 110, S_TOP + 26), (SX1 + 6, S_BOTTOM - 80), right)[1:]
    bottom = [(SX1 - 8, S_BOTTOM), (SX0 + 8, S_BOTTOM)]
    return top + bottom


def stroke_round(d, pts, width, color):
    """Closed outline with round joins drawn as segments plus a disc at every vertex."""
    r = width / 2
    loop = pts + [pts[0]]
    for a, b in zip(loop, loop[1:]):
        d.line([a, b], fill=color, width=round(width))
    for x, y in pts:
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def make_sauce(out_dir):
    img = Image.new("RGB", (W * S, H * S), MAGENTA)
    d = ImageDraw.Draw(img)
    pts = s(sauce_pts())
    d.polygon(pts, fill=OUTLINE)
    stroke_round(d, pts, 2 * OUTLINE_W * S, OUTLINE)

    grad = Image.new("RGB", (W * S, H * S))
    gd = ImageDraw.Draw(grad)
    y0, y1 = S_TOP * S, S_BOTTOM * S
    for y in range(y0, y1 + 1):
        t = ((y - y0) / max(1, y1 - y0)) ** 1.6
        c = tuple(round(a + (b - a) * t) for a, b in zip(SAUCE_BODY, SAUCE_SHADE))
        gd.line([(0, y), (W * S, y)], fill=c)
    mask = Image.new("L", (W * S, H * S), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    img.paste(grad, (0, 0), mask)

    # One small glossy highlight on the middle bump.
    d.polygon(s(ellipse_pts(CX - 60, S_TOP + 26, 70, 10)), fill=SAUCE_HIGHLIGHT)
    save(img, out_dir, "ENV-SAUCE-guide.png")


# Fork: portrait 768 x 1344, pointing down; head ~300 px wide (game ~70 px).
FW, FH = 768, 1344
FCX = FW // 2
STEEL_DARK = (104, 112, 119)
STEEL_LIGHT = (205, 211, 216)
STEEL_MID = (154, 162, 169)      # placeholder fork color #9AA2A9
HANDLE_HW, HEAD_HW = 45, 150
NECK_Y0, HEAD_Y0, TINE_Y0, TINE_Y1, TIP_Y = 640, 830, 960, 1180, 1250
TINE_W, GAP_W = 48, 36


def fork_pts():
    pts = [(FCX - HANDLE_HW, -40), (FCX - HANDLE_HW, NECK_Y0)]
    pts += bezier((FCX - HANDLE_HW, NECK_Y0), (FCX - HANDLE_HW, NECK_Y0 + 110),
                  (FCX - HEAD_HW, HEAD_Y0 - 90), (FCX - HEAD_HW, HEAD_Y0))[1:]
    x = FCX - HEAD_HW
    for i in range(4):
        left, right = x, x + TINE_W
        pts += [(left, TINE_Y1), ((left + right) / 2, TIP_Y), (right, TINE_Y1)]
        if i < 3:
            r = GAP_W / 2
            cx = right + r
            pts += [(right, TINE_Y0)]
            pts += [(cx - r * math.cos(math.pi * k / 16), TINE_Y0 - r * math.sin(math.pi * k / 16))
                    for k in range(1, 16)]
            pts += [(right + GAP_W, TINE_Y0)]
        x = right + GAP_W
    pts += bezier((FCX + HEAD_HW, HEAD_Y0), (FCX + HEAD_HW, HEAD_Y0 - 90),
                  (FCX + HANDLE_HW, NECK_Y0 + 110), (FCX + HANDLE_HW, NECK_Y0))
    pts += [(FCX + HANDLE_HW, -40)]
    return pts


def make_fork(out_dir):
    img = Image.new("RGB", (FW * S, FH * S), MAGENTA)
    d = ImageDraw.Draw(img)
    pts = s(fork_pts())
    d.polygon(pts, fill=OUTLINE)
    stroke_round(d, pts, 2 * OUTLINE_W * S, OUTLINE)

    # Horizontal steel gradient: dark edges, light band left of center.
    grad = Image.new("RGB", (FW * S, FH * S))
    gd = ImageDraw.Draw(grad)
    x0, x1 = (FCX - HEAD_HW) * S, (FCX + HEAD_HW) * S
    for x in range(x0, x1 + 1):
        t = (x - x0) / max(1, x1 - x0)
        if t < 0.4:
            u = t / 0.4
            c = tuple(round(a + (b - a) * u) for a, b in zip(STEEL_DARK, STEEL_LIGHT))
        else:
            u = (t - 0.4) / 0.6
            c = tuple(round(a + (b - a) * u) for a, b in zip(STEEL_LIGHT, STEEL_DARK))
        gd.line([(x, 0), (x, FH * S)], fill=c)
    mask = Image.new("L", (FW * S, FH * S), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    img.paste(grad, (0, 0), mask)

    # One highlight down the handle.
    d.line(s([(FCX - 14, 30), (FCX - 14, NECK_Y0 - 20)]), fill=HIGHLIGHT, width=8 * S)
    save(img, out_dir, "ENV-FORK-guide.png")


# Dome: 1024 x 1024; body ~680 x 490 px (game ~180 x 140 px). Interior stays flat magenta.
DW = DH = 1024
DCX, D_BASE, D_RX, D_RY = 512, 760, 330, 400
GLASS_EDGE = (226, 240, 246)
GLASS_RIM = (214, 228, 235)
DOME_OUTLINE_W = 6


def stroke_open(d, pts, width, color):
    """Open path with round caps and joins."""
    r = width / 2
    for a, b in zip(pts, pts[1:]):
        d.line([a, b], fill=color, width=round(width))
    for x, y in pts:
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def make_dome(out_dir):
    img = Image.new("RGB", (DW * S, DH * S), MAGENTA)
    d = ImageDraw.Draw(img)
    arc = s(ellipse_pts(DCX, D_BASE, D_RX, D_RY, math.pi, 2 * math.pi))
    top = D_BASE - D_RY

    # Glass wall: dark outline with a thin light glass edge just inside it.
    stroke_open(d, arc, 2 * DOME_OUTLINE_W * S, OUTLINE)
    inner = s(ellipse_pts(DCX, D_BASE, D_RX - 13, D_RY - 13, math.pi + 0.02, 2 * math.pi - 0.02))
    stroke_open(d, inner, 6 * S, GLASS_EDGE)

    # Highlights: one long and one short streak on the left, one small on the right.
    for a0, a1, rr, w in [(math.pi + 0.30, math.pi + 0.80, 60, 16),
                          (math.pi + 0.90, math.pi + 1.05, 60, 12),
                          (2 * math.pi - 0.55, 2 * math.pi - 0.35, 50, 9)]:
        stroke_open(d, s(ellipse_pts(DCX, D_BASE, D_RX - rr, D_RY - rr, a0, a1, n=60)),
                    w * S, HIGHLIGHT)

    # Base rim (flat flange).
    rim = [(DCX - D_RX - 30, D_BASE - 6), (DCX + D_RX + 30, D_BASE - 6),
           (DCX + D_RX + 30, D_BASE + 22), (DCX - D_RX - 30, D_BASE + 22)]
    d.polygon(s(rim), fill=OUTLINE)
    stroke_round(d, s(rim), 2 * DOME_OUTLINE_W * S, OUTLINE)
    d.polygon(s(rim), fill=GLASS_RIM)
    stroke_open(d, s([(DCX - D_RX - 10, D_BASE + 2), (DCX - D_RX + 160, D_BASE + 2)]), 5 * S, HIGHLIGHT)

    # Knob: short neck and a round handle.
    neck = [(DCX - 14, top - 26), (DCX + 14, top - 26), (DCX + 14, top + 4), (DCX - 14, top + 4)]
    knob = ellipse_pts(DCX, top - 54, 32, 30)
    for shape in (neck, knob):
        d.polygon(s(shape), fill=OUTLINE)
        stroke_round(d, s(shape), 2 * DOME_OUTLINE_W * S, OUTLINE)
    d.polygon(s(neck), fill=GLASS_RIM)
    d.polygon(s(knob), fill=GLASS_EDGE)
    d.polygon(s(ellipse_pts(DCX - 11, top - 64, 9, 7)), fill=HIGHLIGHT)
    save(img, out_dir, "ENV-DOME-guide.png")


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: make_env_guides.py OUT_DIR")
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    make_plate(out_dir)
    make_sauce(out_dir)
    make_fork(out_dir)
    make_dome(out_dir)


if __name__ == "__main__":
    main()
