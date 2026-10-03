#!/usr/bin/env python3
"""Build the Batch 2 review images and contrast numbers.

Usage: python3 tools/batch2_review.py GAME_DIR EVIDENCE_DIR

GAME_DIR holds the processed files (ENV-ROOM.png, ENV-TABLE.png, ENV-PLATE.png, ENV-SAUCE.png,
ENV-FORK.png, ENV-DOME.png and the CHAR-*.png cut-outs). Writes:
  batch2-mock-scene.png   1280 x 720 mock of the slice at the proposed game sizes (layout only;
                          the fork shadow is a placeholder ellipse, as the real one is code-drawn)
  batch2-table-seam.png   the table strip tiled 3x at game height, seams marked above the strip
  batch2-sprites.png      plate, sauce, fork, dome over the jelly, at game size and 3x, on the
                          table color and on the room's mean color
  batch2-poses.png        all 12 pose cut-outs at 64 px cube scale on the table color and room
  batch2-review.png       all of the above stacked
Prints the scale used for each asset and luminance contrast ratios (WCAG formula).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

TABLE_H = 200          # table strip height in game px
TABLE_TOP = 720 - TABLE_H
PLATE_W = 200
SAUCE_W = 120
FORK_HEAD_W = 70
DOME_W = 180
CUBE = 64              # jelly cube in game px
REF_W = 604            # CHAR-REF measured width in source px (= 64 game px)
JELLY = (60, 207, 196)
JELLY_OUTLINE = (15, 52, 64)
TABLE_PLACEHOLDER = (42, 35, 32)


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def label(img, text, xy, size=18, fill=(255, 255, 255)):
    d = ImageDraw.Draw(img)
    x, y = xy
    d.text((x + 1, y + 1), text, font=font(size), fill=(0, 0, 0))
    d.text((x, y), text, font=font(size), fill=fill)


def scaled(im, factor):
    w, h = max(1, round(im.width * factor)), max(1, round(im.height * factor))
    return im.resize((w, h), Image.LANCZOS)


def obj_box(im):
    return im.getchannel("A").getbbox()


def trim(im):
    return im.crop(obj_box(im))


def rel_lum(rgb):
    c = np.array(rgb, float) / 255
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def contrast(a, b):
    la, lb = sorted([rel_lum(a), rel_lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def mean_rgb(im):
    a = np.asarray(im.convert("RGBA")).astype(float)
    m = a[..., 3] > 200
    return tuple(a[..., :3][m].mean(0).round().astype(int).tolist())


def fork_long(fork, factor, total_h):
    """Fork at game scale with the uniform handle stretched so it reaches total_h px."""
    f = scaled(trim(fork), factor)
    if f.height >= total_h:
        return f
    cut = int(f.height * 0.35)              # top 35% is the straight handle
    handle = f.crop((0, 0, f.width, cut)).resize((f.width, cut + total_h - f.height), Image.LANCZOS)
    out = Image.new("RGBA", (f.width, total_h), (0, 0, 0, 0))
    out.alpha_composite(handle, (0, 0))
    out.alpha_composite(f.crop((0, cut, f.width, f.height)), (0, handle.height))
    return out


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    gd, ev = sys.argv[1], sys.argv[2]
    os.makedirs(ev, exist_ok=True)
    ld = lambda n: Image.open(os.path.join(gd, n)).convert("RGBA")
    room, table = ld("ENV-ROOM.png"), ld("ENV-TABLE.png")
    plate, sauce, fork, dome = ld("ENV-PLATE.png"), ld("ENV-SAUCE.png"), ld("ENV-FORK.png"), ld("ENV-DOME.png")
    poses = sorted(n for n in os.listdir(gd) if n.startswith("CHAR-") and n.endswith(".png"))
    idle = ld("CHAR-IDLE.png")

    s_table = TABLE_H / table.height
    s_plate = PLATE_W / trim(plate).width
    s_sauce = SAUCE_W / trim(sauce).width
    s_fork = FORK_HEAD_W / trim(fork).width
    s_dome = DOME_W / trim(dome).width
    s_jelly = CUBE / REF_W
    t_strip = scaled(table, s_table)
    g_plate, g_sauce, g_dome = scaled(trim(plate), s_plate), scaled(trim(sauce), s_sauce), scaled(trim(dome), s_dome)
    g_idle = scaled(trim(idle), s_jelly)

    # ---- mock scene ----
    scene = room.copy()
    x = 0
    while x < 1280:
        scene.alpha_composite(t_strip, (x, TABLE_TOP))
        x += t_strip.width
    plate_xs = [150, 430, 760, 1030]
    top_surface = None
    for cx in plate_xs:
        scene.alpha_composite(g_plate, (cx - g_plate.width // 2, TABLE_TOP + 2 - g_plate.height))
    # plate top surface: first row where the plate is at least half its width wide
    pa = np.asarray(g_plate.getchannel("A")) > 128
    rows = np.nonzero(pa.sum(1) > g_plate.width * 0.5)[0]
    top_surface = TABLE_TOP + 2 - g_plate.height + int(rows[0]) + 4
    scene.alpha_composite(g_sauce, (595 - g_sauce.width // 2, TABLE_TOP + 3 - g_sauce.height))
    # placeholder shadow on plate 4, fork above it
    sh = Image.new("RGBA", scene.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([1030 - 55, top_surface - 6, 1030 + 55, top_surface + 6], fill=(0, 0, 0, 110))
    scene.alpha_composite(sh)
    g_fork = fork_long(fork, s_fork, 380)
    scene.alpha_composite(g_fork, (1030 - g_fork.width // 2, top_surface - 90 - g_fork.height))
    scene.alpha_composite(g_idle, (760 - g_idle.width // 2, top_surface - g_idle.height))
    scene.alpha_composite(g_dome, (1210 - g_dome.width // 2, TABLE_TOP + 2 - g_dome.height))
    label(scene, "mock layout at game size (1280 x 720); fork handle stretched, shadow is a placeholder", (10, 8))
    scene.convert("RGB").save(os.path.join(ev, "batch2-mock-scene.png"))

    # ---- table seam ----
    seam = Image.new("RGBA", (t_strip.width * 3 + 20, TABLE_H + 40), (30, 30, 30, 255))
    for i in range(3):
        seam.alpha_composite(t_strip, (10 + i * t_strip.width, 30))
    d = ImageDraw.Draw(seam)
    for i in range(1, 3):
        xx = 10 + i * t_strip.width
        d.polygon([(xx - 8, 6), (xx + 8, 6), (xx, 24)], fill=(255, 220, 0))
    label(seam, "table strip x3 (yellow = seams)", (10 + 3 * t_strip.width - 300, 4), 16)
    seam.convert("RGB").save(os.path.join(ev, "batch2-table-seam.png"))

    # ---- sprite checks ----
    room_mean = mean_rgb(room)
    items = [("plate", g_plate), ("sauce", g_sauce), ("fork head", scaled(trim(fork), s_fork).crop(
        (0, scaled(trim(fork), s_fork).height - 110, scaled(trim(fork), s_fork).width, scaled(trim(fork), s_fork).height)))]
    dome_check = Image.new("RGBA", (g_dome.width + 20, g_dome.height + 10), (0, 0, 0, 0))
    dome_check.alpha_composite(g_idle, ((dome_check.width - g_idle.width) // 2, dome_check.height - 14 - g_idle.height))
    dome_check.alpha_composite(g_dome, (10, dome_check.height - g_dome.height))
    items.append(("dome over jelly", dome_check))
    cols = []
    for bgc in (TABLE_PLACEHOLDER, room_mean):
        panel_w = sum(it.width for _, it in items) + 40 * len(items)
        p1 = Image.new("RGBA", (panel_w, 200), bgc + (255,))
        xx = 20
        for name, it in items:
            p1.alpha_composite(it, (xx, 180 - it.height))
            label(p1, name, (xx, 4), 14)
            xx += it.width + 40
        cols.append(p1)
    zoom_row = []
    for name, it in items:
        z = it.resize((it.width * 3, it.height * 3), Image.NEAREST)
        t = Image.new("RGBA", z.size, TABLE_PLACEHOLDER + (255,))
        t.alpha_composite(z)
        zoom_row.append(t)
    zw = sum(z.width for z in zoom_row) + 20 * len(zoom_row)
    zh = max(z.height for z in zoom_row)
    sprites = Image.new("RGBA", (max(zw, cols[0].width * 2 + 10), 200 + 10 + zh + 30), (30, 30, 30, 255))
    sprites.alpha_composite(cols[0], (0, 0))
    sprites.alpha_composite(cols[1], (cols[0].width + 10, 0))
    xx = 0
    for z in zoom_row:
        sprites.alpha_composite(z, (xx, 240))
        xx += z.width + 20
    label(sprites, "left: on table color #2A2320 · right: on the room's mean color · below: 3x on table color",
          (10, 212), 16)
    sprites.convert("RGB").save(os.path.join(ev, "batch2-sprites.png"))

    # ---- poses ----
    tiles = []
    for n in poses:
        im = scaled(ld(n), s_jelly)
        tiles.append((n[5:-4], im.crop(obj_box(im))))
    tw = sum(t.width for _, t in tiles) + 16 * len(tiles) + 16
    pz = Image.new("RGBA", (tw, 2 * 130), (0, 0, 0, 255))
    for row, bgc in enumerate((TABLE_PLACEHOLDER, room_mean)):
        band = Image.new("RGBA", (tw, 130), bgc + (255,))
        xx = 16
        for name, t in tiles:
            band.alpha_composite(t, (xx, 110 - t.height))
            if row == 0:
                label(band, name, (xx, 4), 11)
            xx += t.width + 16
        pz.alpha_composite(band, (0, row * 130))
    pz.convert("RGB").save(os.path.join(ev, "batch2-poses.png"))

    # ---- stacked review ----
    parts = [Image.open(os.path.join(ev, f)) for f in
             ("batch2-mock-scene.png", "batch2-table-seam.png", "batch2-sprites.png", "batch2-poses.png")]
    W = max(p.width for p in parts)
    H = sum(p.height for p in parts) + 10 * len(parts)
    rv = Image.new("RGB", (W, H), (20, 20, 20))
    y = 0
    for p in parts:
        rv.paste(p, (0, y))
        y += p.height + 10
    rv.save(os.path.join(ev, "batch2-review.png"))

    # ---- numbers ----
    print("scales (source px -> game px):")
    print(f"  table x{s_table:.4f} -> strip {t_strip.width} x {t_strip.height} (repeat period {t_strip.width} px)")
    print(f"  plate x{s_plate:.4f} -> {g_plate.width} x {g_plate.height}; top surface {top_surface - (TABLE_TOP + 2 - g_plate.height)} px below its top")
    print(f"  sauce x{s_sauce:.4f} -> {g_sauce.width} x {g_sauce.height}")
    print(f"  fork  x{s_fork:.4f} -> {scaled(trim(fork), s_fork).width} x {scaled(trim(fork), s_fork).height} (head {FORK_HEAD_W} wide)")
    print(f"  dome  x{s_dome:.4f} -> {g_dome.width} x {g_dome.height}")
    print(f"  jelly x{s_jelly:.4f} -> idle {g_idle.width} x {g_idle.height}")
    tbl = mean_rgb(table)
    print("luminance contrast ratios (1 = none, 21 = black/white):")
    pairs = [("jelly body vs room mean", JELLY, room_mean), ("jelly body vs table mean", JELLY, tbl),
             ("jelly outline vs table mean", JELLY_OUTLINE, tbl),
             ("jelly body vs plate mean", JELLY, mean_rgb(plate)),
             ("plate mean vs table mean", mean_rgb(plate), tbl), ("plate mean vs room mean", mean_rgb(plate), room_mean),
             ("sauce mean vs table mean", mean_rgb(sauce), tbl), ("fork mean vs room mean", mean_rgb(fork), room_mean),
             ("room mean vs table mean", room_mean, tbl)]
    for name, a, b in pairs:
        print(f"  {name}: {contrast(a, b):.2f}   ({'#%02X%02X%02X' % a} vs {'#%02X%02X%02X' % b})")
    # brightest part of the room the fork passes in front of (upper-left glow)
    ra = np.asarray(room.convert("RGB")).astype(float)
    lum = 0.299 * ra[..., 0] + 0.587 * ra[..., 1] + 0.114 * ra[..., 2]
    print(f"  room luminance: mean {lum.mean():.0f}, 95th percentile {np.percentile(lum, 95):.0f} (0-255)")
    print("wrote", ", ".join(["batch2-mock-scene.png", "batch2-table-seam.png", "batch2-sprites.png",
                             "batch2-poses.png", "batch2-review.png"]))


if __name__ == "__main__":
    main()
