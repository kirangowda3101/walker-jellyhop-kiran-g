#!/usr/bin/env python3
"""Batch 2 processing for Jelly Hop: Fork From Above.

Subcommands (all read inputs without modifying them; numpy + Pillow only):

  cutout IN OUT [--interior] [--crop PAD] [--pink-to R,G,B]
      Magenta background -> transparent.
      1. B = median color of the image's 3 px border (the generated "magenta", e.g. #F424E1).
      2. d = RGB distance of each pixel from B.
      3. Background = pixels with d < T_HI that connect to the image border through such pixels
         (flood fill). With --interior, enclosed regions that contain a pixel with d < T_LO are
         keyed too (used for the dome's clear glass).
      4. Inside the background: d < T_LO -> alpha 0. Pixels between T_LO and T_HI are edge
         pixels. Each is matched to the solid pixel within EDGE_R px whose color F best
         explains it as a mix of F and B; alpha is the projection of (pixel - B) onto (F - B),
         and the color is un-mixed: (pixel - (1 - alpha) * B) / alpha (F itself below 25%).
         The edge also includes a RING px ring just outside the keyed area, because half-mixes
         of the dark outline and magenta can lie farther than T_HI from B.
      5. Despill on edge pixels: where min(R, B) > G, both are pulled down toward G.
      6. Visible islands smaller than MIN_ISLAND px are dropped (stray corner pixels).
      7. --pink-to R,G,B recolors opaque magenta-like pixels (outside the ring) to that color,
         keeping their relative luminance, and blends pinkish pixels within 3 px of them toward
         it by how pink they are (used for the sauce's pink highlight).
      Reports keyed/edge/solid pixel counts, remaining magenta-like pixels (fringe) by alpha,
      enclosed magenta-like pixels that were NOT keyed, the object box, and a pixel
      fingerprint (first 16 hex of sha256 of the RGBA bytes).
      --crop PAD crops to the object box plus PAD px (env sprites); without it the canvas
      size is kept (poses, so every frame keeps the same alignment).

  table IN OUT --bottom ROWS --blend PX --gain G --sat S
      Drops the bottom ROWS rows, darkens (multiply by G) and desaturates (S = saturation
      kept, 0..1), then crossfades the last PX columns into the first PX so the strip repeats
      seamlessly (output width = input width - PX). Reports the seam difference before/after.

  compare GUIDE RAW
      How much the model changed a guide, measured inside the guide's drawn object (pixels not
      within 40 levels of #FF00FF): mean absolute difference per channel (0-255), the share of
      those pixels differing by more than 32 levels in any channel, and both object boxes.

  room IN OUT --size WxH
      Center-crops to the target aspect, then resizes (Lanczos). No color change.

Settings via env: T_LO (default 40), T_HI (default 150), EDGE_R (default 4 px),
RING (default 2 px), MIN_ISLAND (default 20 px).
"""
import hashlib
import os
import sys

import numpy as np
from PIL import Image

T_LO = float(os.environ.get("T_LO", 40))
T_HI = float(os.environ.get("T_HI", 150))
EDGE_R = int(os.environ.get("EDGE_R", 4))
RING = int(os.environ.get("RING", 2))
MIN_ISLAND = int(os.environ.get("MIN_ISLAND", 20))


def fp(arr):
    return hashlib.sha256(np.ascontiguousarray(arr).tobytes()).hexdigest()[:16]


def shift_or(m):
    out = m.copy()
    out[1:] |= m[:-1]
    out[:-1] |= m[1:]
    out[:, 1:] |= m[:, :-1]
    out[:, :-1] |= m[:, 1:]
    return out


def flood(seed, allowed):
    cur = seed & allowed
    while True:
        nxt = cur
        for _ in range(16):
            nxt = shift_or(nxt) & allowed
        if np.array_equal(nxt, cur):
            return cur
        cur = nxt


def label_regions(mask):
    """Simple 4-connected labelling (numpy only). Returns list of boolean masks."""
    remaining = mask.copy()
    regions = []
    while remaining.any():
        ys, xs = np.nonzero(remaining)
        seed = np.zeros_like(mask)
        seed[ys[0], xs[0]] = True
        reg = flood(seed, remaining)
        regions.append(reg)
        remaining &= ~reg
    return regions


def magenta_like(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (r > g + 60) & (b > g + 60) & (np.abs(r - b) < 70)


def cutout(src, dst, interior=False, crop=None, pink_to=None):
    im = Image.open(src).convert("RGB")
    a = np.asarray(im).astype(np.float64)
    h, w, _ = a.shape
    border = np.concatenate([a[:3].reshape(-1, 3), a[-3:].reshape(-1, 3),
                             a[:, :3].reshape(-1, 3), a[:, -3:].reshape(-1, 3)])
    B = np.median(border, axis=0)
    d = np.sqrt(((a - B) ** 2).sum(-1))

    cand = d < T_HI
    seed = np.zeros((h, w), bool)
    seed[0, :] = seed[-1, :] = seed[:, 0] = seed[:, -1] = True
    bg = flood(seed, cand)
    interior_px = 0
    enclosed = cand & ~bg
    regions = []
    if enclosed.any():
        core = (d < T_LO) & enclosed
        # Only regions that contain true background-colored pixels count as enclosed magenta.
        regions = [r for r in label_regions(flood(core, enclosed))] if core.any() else []
    if interior:
        for r in regions:
            bg |= r
            interior_px += int(r.sum())
    unkeyed_enclosed = 0 if interior else int(sum(r.sum() for r in regions))

    alpha = np.ones((h, w))
    rgb = a.copy()
    clear = bg & (d < T_LO)
    # Edge = keyed pixels that are not pure background, plus a RING px ring just outside the
    # keyed area (mixes of outline and magenta can be too far from B to be keyed by T_HI).
    ring = bg.copy()
    for _ in range(RING):
        ring = shift_or(ring)
    ring &= ~bg
    edge = (bg & ~clear) | ring
    alpha[clear] = 0.0

    # Edge pixels: for each one, try the colors of solid pixels within EDGE_R px as the object
    # color F, and keep the F whose B->F line passes closest to the pixel (smallest residual).
    # alpha = projection of (pixel - B) onto (F - B); color = un-mixed pixel, or F when alpha
    # is very small (un-mixing is unstable there).
    solid = ~bg & ~ring
    ey, ex = np.nonzero(edge)
    P = a[ey, ex]
    best_res = np.full(len(ey), np.inf)
    best_F = P.copy()
    best_al = np.clip((d[ey, ex] - T_LO) / (T_HI - T_LO), 0, 1)
    pa = np.pad(a, ((EDGE_R, EDGE_R), (EDGE_R, EDGE_R), (0, 0)))
    ps = np.pad(solid, EDGE_R)
    for dy in range(-EDGE_R, EDGE_R + 1):
        for dx in range(-EDGE_R, EDGE_R + 1):
            ny, nx = ey + dy + EDGE_R, ex + dx + EDGE_R
            ok = ps[ny, nx]
            if not ok.any():
                continue
            Fc = pa[ny, nx]
            fb = Fc - B
            den = np.maximum((fb ** 2).sum(-1), 1e-6)
            t = np.clip(((P - B) * fb).sum(-1) / den, 0, 1)
            res = np.sqrt(((P - (B + t[:, None] * fb)) ** 2).sum(-1)) + 0.5 * np.hypot(dy, dx)
            upd = ok & (res < best_res)
            best_res[upd] = res[upd]
            best_F[upd] = Fc[upd]
            best_al[upd] = t[upd]
    no_ref = int(np.isinf(best_res).sum())
    al = best_al
    un = (P - (1 - al)[:, None] * B) / np.maximum(al, 1e-3)[:, None]
    col = np.where((al < 0.25)[:, None], best_F, np.clip(un, 0, 255))
    alpha[ey, ex] = al
    rgb[ey, ex] = col
    alpha[edge & (alpha < 0.02)] = 0.0

    # Despill edge pixels.
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    spill = np.minimum(r, b) - g
    sp = edge & (spill > 0)
    rgb[..., 0][sp] -= spill[sp]
    rgb[..., 2][sp] -= spill[sp]
    rgb[alpha == 0] = 0

    # Drop tiny visible islands (stray pixels, e.g. at image corners).
    islands = 0
    island_px = 0
    for r in label_regions(alpha > 0):
        if r.sum() < MIN_ISLAND:
            alpha[r] = 0.0
            rgb[r] = 0
            islands += 1
            island_px += int(r.sum())

    recolored = 0
    blended = 0
    if pink_to is not None:
        cur = np.clip(np.round(rgb), 0, 255).astype(np.float64)
        sel = magenta_like(cur.astype(int)) & (alpha >= 1.0) & ~ring
        if sel.any():
            tgt = np.array(pink_to, float)
            lum = cur[sel].mean(-1)
            core_pink = float((np.minimum(cur[sel][:, 0], cur[sel][:, 2]) - cur[sel][:, 1]).mean())
            new = np.clip(tgt[None, :] * (lum / max(lum.mean(), 1e-6))[:, None], 0, 255)
            # Soft transition pixels around the highlight: blend toward the target by pinkness.
            near = sel.copy()
            for _ in range(3):
                near = shift_or(near)
            near &= ~sel & (alpha >= 1.0) & ~ring
            pinkness = np.minimum(cur[..., 0], cur[..., 2]) - cur[..., 1]
            soft = near & (pinkness > 15)
            base_px = near & ~soft
            base = np.median(cur[base_px], axis=0) if base_px.any() else cur[soft].mean(0)
            w_ = np.clip(pinkness[soft] / max(core_pink, 1e-6), 0, 1)[:, None]
            rgb[sel] = new
            rgb[soft] = w_ * tgt[None, :] + (1 - w_) * base[None, :]
            recolored, blended = int(sel.sum()), int(soft.sum())
            ys_, xs_ = np.nonzero(sel | soft)
            pink_box = (int(xs_.min()), int(ys_.min()), int(xs_.max()), int(ys_.max()))

    out = np.dstack([np.clip(np.round(rgb), 0, 255), np.round(alpha * 255)]).astype(np.uint8)
    vis = out[..., 3] > 0
    ys, xs = np.nonzero(vis)
    box = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    if crop is not None:
        x0, y0 = max(0, box[0] - crop), max(0, box[1] - crop)
        x1, y1 = min(w, box[2] + crop + 1), min(h, box[3] + crop + 1)
        out = out[y0:y1, x0:x1]
    Image.fromarray(out, "RGBA").save(dst)

    mrgb = out[..., :3].astype(int)
    mal = out[..., 3]
    mag = magenta_like(mrgb)
    fr_any = int((mag & (mal > 0)).sum())
    fr_half = int((mag & (mal >= 128)).sum())
    print(f"{os.path.basename(src)} -> {dst}")
    print(f"  background median #{int(B[0]):02X}{int(B[1]):02X}{int(B[2]):02X}  T_LO {T_LO:g}  T_HI {T_HI:g}")
    print(f"  keyed clear {int(clear.sum())}  edge {int(edge.sum())} (ring {int(ring.sum())}, no solid ref {no_ref})  solid {int(solid.sum())}"
          + (f"  interior keyed {interior_px}" if interior else ""))
    print(f"  enclosed magenta-like regions NOT keyed: {unkeyed_enclosed} px")
    print(f"  removed {islands} visible islands under {MIN_ISLAND} px ({island_px} px)")
    if pink_to is not None:
        if recolored:
            print(f"  recolored {recolored} opaque magenta-like px to #{pink_to[0]:02X}{pink_to[1]:02X}{pink_to[2]:02X}"
                  f" (luminance kept) and blended {blended} pinkish transition px around them;"
                  f" box x {pink_box[0]}-{pink_box[2]}, y {pink_box[1]}-{pink_box[3]} (before crop)")
        else:
            print("  recolor requested but no opaque magenta-like px found")
    print(f"  fringe (magenta-like, alpha>0): {fr_any}  (alpha>=128): {fr_half}")
    print(f"  object box x {box[0]}-{box[2]}, y {box[1]}-{box[3]} ({box[2]-box[0]+1} x {box[3]-box[1]+1} px)"
          f"  output {out.shape[1]} x {out.shape[0]}  fingerprint {fp(out)}")


def table(src, dst, bottom, blend, gain, sat):
    a = np.asarray(Image.open(src).convert("RGB")).astype(np.float64)
    a = a[: a.shape[0] - bottom]
    lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2])[..., None]
    a = lum + (a - lum) * sat
    a = np.clip(a * gain, 0, 255)
    h, w, _ = a.shape
    before = float(np.abs(a[:, -1] - a[:, 0]).mean())
    t = np.linspace(0, 1, blend)[None, :, None]
    out = a[:, : w - blend].copy()
    out[:, :blend] = a[:, w - blend:] * (1 - t) + a[:, :blend] * t
    after = float(np.abs(out[:, -1] - out[:, 0]).mean())
    inner = float(np.abs(out[:, 1:] - out[:, :-1]).mean())
    out8 = np.clip(np.round(out), 0, 255).astype(np.uint8)
    Image.fromarray(out8, "RGB").save(dst)
    print(f"{os.path.basename(src)} -> {dst}")
    print(f"  dropped bottom {bottom} rows; saturation kept {sat:g}; gain {gain:g}; blend {blend} px")
    print(f"  output {out8.shape[1]} x {out8.shape[0]}  mean RGB {out8.reshape(-1,3).mean(0).round(1).tolist()}")
    print(f"  seam: mean |last col - first col| before {before:.1f}, after {after:.1f};"
          f" typical neighbouring-column difference {inner:.1f}")
    print(f"  fingerprint {fp(out8)}")


def room(src, dst, size):
    tw, th = size
    im = Image.open(src).convert("RGB")
    w, h = im.size
    if w / h > tw / th:
        nw = round(h * tw / th)
        x0 = (w - nw) // 2
        im = im.crop((x0, 0, x0 + nw, h))
    else:
        nh = round(w * th / tw)
        y0 = (h - nh) // 2
        im = im.crop((0, y0, w, y0 + nh))
    crop_size = im.size
    im = im.resize((tw, th), Image.LANCZOS)
    im.save(dst)
    arr = np.asarray(im)
    print(f"{os.path.basename(src)} -> {dst}")
    print(f"  center crop {crop_size[0]} x {crop_size[1]}, resized to {tw} x {th}; no color change")
    print(f"  mean RGB {arr.reshape(-1,3).mean(0).round(1).tolist()}  fingerprint {fp(arr)}")


def compare(guide, raw):
    g = np.asarray(Image.open(guide).convert("RGB")).astype(int)
    r = np.asarray(Image.open(raw).convert("RGB")).astype(int)
    if g.shape != r.shape:
        sys.exit(f"size mismatch: {g.shape} vs {r.shape}")
    obj = np.abs(g - np.array([255, 0, 255])).max(-1) > 40   # the guide's drawn object
    diff = np.abs(g - r)
    md = diff[obj].mean(0)
    big = (diff[obj].max(-1) > 32).mean() * 100
    ys, xs = np.nonzero(obj)
    # Raw object: pixels far from the raw's own border median.
    border = np.concatenate([r[:3].reshape(-1, 3), r[-3:].reshape(-1, 3)])
    Bm = np.median(border, 0)
    robj = np.sqrt(((r - Bm) ** 2).sum(-1)) > 80
    rys, rxs = np.nonzero(robj)
    print(f"{os.path.basename(raw)} vs {os.path.basename(guide)} (inside the guide's object, {int(obj.sum())} px):"
          f" mean |diff| per channel {md.round(1).tolist()}; pixels differing by >32 levels: {big:.1f}%;"
          f" object box guide {xs.max()-xs.min()+1} x {ys.max()-ys.min()+1} px,"
          f" raw {rxs.max()-rxs.min()+1} x {rys.max()-rys.min()+1} px")


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    cmd = args.pop(0)

    def opt(name, conv, default=None):
        if name in args:
            i = args.index(name)
            v = conv(args[i + 1])
            del args[i:i + 2]
            return v
        if default is None:
            sys.exit(f"missing {name}")
        return default

    if cmd == "cutout":
        interior = "--interior" in args
        if interior:
            args.remove("--interior")
        crop = opt("--crop", int, -1)
        pink = opt("--pink-to", lambda v: tuple(int(c) for c in v.split(",")), "none")
        if len(args) != 2:
            sys.exit("usage: cutout IN OUT [--interior] [--crop PAD] [--pink-to R,G,B]")
        cutout(args[0], args[1], interior, None if crop < 0 else crop, None if pink == "none" else pink)
    elif cmd == "table":
        bottom = opt("--bottom", int)
        blend = opt("--blend", int)
        gain = opt("--gain", float)
        sat = opt("--sat", float)
        table(args[0], args[1], bottom, blend, gain, sat)
    elif cmd == "compare":
        compare(args[0], args[1])
    elif cmd == "room":
        size = opt("--size", lambda s: tuple(int(v) for v in s.lower().split("x")))
        room(args[0], args[1], size)
    else:
        sys.exit(f"unknown command {cmd}")


if __name__ == "__main__":
    main()
