"""Builds the image-to-image guides for the remaining poses, all derived from the accepted CHAR-REF.
Written by Claude at Kiran's request.
Usage: python3 tools/make_pose_guides.py art/reference/CHAR-REF.png gen-inputs/
Shapes and faces follow CHARACTER-SHEET.md; every body pixel comes from CHAR-REF.
  - Squash, stretch, lean, and taper poses: CHAR-REF's body is warped with the same mapping as
    tools/make_pose_guide.py (used for the accepted Scoot B).
  - Faces: neutral poses reuse CHAR-REF's own face, unscaled. Expression poses reuse CHAR-REF's
    own eye pixels where the sheet keeps dot eyes, and draw the sheet's brows, mouths, lids,
    closed eyes, or X eyes in CHAR-REF's measured face color and stroke width (hybrid).
  - Splat and re-form: CHAR-REF's body is reshaped column by column to the sheet's outline,
    keeping its outline thickness at the edges (a "9-slice" warp); droplets are the whole
    CHAR-REF body scaled down. Re-form's drip marks are left out of the guide.
  - Every guide: eyes' center 38% down from the pose's top (sheet rule), the face shifted
    with the lean but never scaled, flat #FF00FF background, 1024 x 1024.
Prints each pose's measured size in game px and a pixel fingerprint.
"""
import sys, os, math, hashlib
import numpy as np
from PIL import Image, ImageDraw

src, out_dir = sys.argv[1], sys.argv[2]
MAGENTA = np.array([255.0, 0.0, 255.0])
SS = 4                                            # supersampling for drawn face strokes

a = np.asarray(Image.open(src).convert("RGB")).astype(float)
ih, iw = a.shape[:2]
jelly = (a[:, :, 1] - a[:, :, 0]) > 15
for r in range(ih):
    c = np.where(jelly[r])[0]
    if len(c) > 3:
        jelly[r, c[0]:c[-1] + 1] = True
rows, cols = np.where(jelly.sum(axis=1) > 3)[0], np.where(jelly.sum(axis=0) > 3)[0]
top, bottom, left, right = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
cx, by = (left + right) / 2.0, float(bottom)
ref_w, ref_h = right - left, bottom - top
kx, ky = ref_w / 64.0, ref_h / 64.0               # image px per game px

# face: same detection as make_pose_guide.py
inner = np.zeros_like(jelly)
m = int(ref_h * 0.12)
inner[top + m:bottom - int(ref_h * 0.30), left + m:right - m] = True
dark = (a.sum(axis=2) < 240) & inner
pad = np.pad(dark, 4)
face = np.zeros_like(dark)
for dy in range(9):
    for dx in range(9):
        face |= pad[dy:dy + ih, dx:dx + iw]
face &= inner
body_fill = np.median(a[inner & ~face], axis=0)
body = a.copy()
body[face] = body_fill
face_color = tuple(int(v) for v in np.median(a[dark], axis=0))
dy_, dx_ = np.where(dark)
rows_d = np.unique(dy_)
split = rows_d[np.diff(rows_d).argmax()]
ref_eye_y = dy_[dy_ <= split].mean()
eye_xs = dx_[dy_ <= split]
mid_x = (eye_xs.min() + eye_xs.max()) / 2.0
eye_l = (dx_[(dy_ <= split) & (dx_ < mid_x)].mean(), ref_eye_y)
eye_r = (dx_[(dy_ <= split) & (dx_ >= mid_x)].mean(), ref_eye_y)
mouth_y = dy_[dy_ > split].mean()
mouth_x = dx_[dy_ > split].mean()
stroke = float(np.median([np.sum(dark[split + 1:, int(c)]) for c in range(int(mouth_x) - 8, int(mouth_x) + 9)]))
def layer(rows_sel):
    """CHAR-REF face pixels (eyes or mouth) as (rgb, mask, top, left)."""
    mask = face & (rows_sel)
    near = np.abs(a - body_fill).sum(axis=2) > 40
    mask &= near
    ys, xs = np.where(mask)
    t, b, l, r = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return a[t:b, l:r].copy(), mask[t:b, l:r], t, l
Yi = np.arange(ih)[:, None] * np.ones((1, iw), bool)
eyes_layer = layer(Yi <= split + 4)
mouth_layer = layer(Yi > split + 4)

def bilinear(img, x, y):
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    x0c, y0c = np.clip(x0, 0, iw - 2), np.clip(y0, 0, ih - 2)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    return (img[y0c, x0c] * (1 - fx) * (1 - fy) + img[y0c, x0c + 1] * fx * (1 - fy) +
            img[y0c + 1, x0c] * (1 - fx) * fy + img[y0c + 1, x0c + 1] * fx * fy)

def composite(out, srcx, srcy, img, mask):
    inside = (srcx >= 0) & (srcx < iw - 1) & (srcy >= 0) & (srcy < ih - 1)
    cov = np.zeros((ih, iw))
    cov[inside] = bilinear(mask.astype(float)[..., None], srcx[inside], srcy[inside])[:, 0]
    col = np.zeros((ih, iw, 3))
    col[inside] = bilinear(img, srcx[inside], srcy[inside])
    return out * (1 - cov[..., None]) + col * cov[..., None]

Y, X = np.mgrid[0:ih, 0:iw].astype(float)

def warp(img, W, H, lean, taper):
    """Same mapping as make_pose_guide.py: scale, taper, and lean with bottom-center fixed."""
    sy = H / 64.0
    up = by - Y
    u = np.clip(up / (ref_h * sy), 0, 1)
    sx = (W + taper * u) / 64.0
    shear = math.tan(math.radians(lean))
    srcx = cx + (X - cx - shear * up) / sx
    srcy = by - up / sy
    return composite(np.tile(MAGENTA, (ih, iw, 1)), srcx, srcy, img, jelly)

def nine_slice(out, img, x0g, x1g, height_fn, base_g=0.0):
    """Reshape CHAR-REF column by column into a shape spanning x0g..x1g game px whose top is
    height_fn(x) game px above base_g, keeping CHAR-REF's edge bands (outline) at full thickness."""
    e = 28.0                                              # edge band in image px (outline + margin)
    xg = (X - cx) / kx
    Hc = np.clip(np.vectorize(height_fn)(np.clip(xg, x0g, x1g)), 0, None) * ky
    base = by - base_g * ky
    Wout = (x1g - x0g) * kx
    ox = X - (cx + x0g * kx)
    ew = min(e, Wout / 2)
    srcx = np.where(ox < ew, left + ox * e / ew,
           np.where(ox > Wout - ew, right - (Wout - ox) * e / ew,
                    left + e + (ox - ew) / max(Wout - 2 * ew, 1) * (ref_w - 2 * e)))
    oy = Y - (base - Hc)
    eh = np.minimum(e, Hc / 2)
    with np.errstate(divide="ignore", invalid="ignore"):
        srcy = np.where(oy < eh, top + oy * e / np.maximum(eh, 1e-6),
               np.where(oy > Hc - eh, bottom - (Hc - oy) * e / np.maximum(eh, 1e-6),
                        top + e + (oy - eh) / np.maximum(Hc - 2 * eh, 1e-6) * (ref_h - 2 * e)))
    valid = (ox >= 0) & (ox <= Wout) & (oy >= 0) & (oy <= Hc) & (Hc > 0)
    srcx = np.where(valid, srcx, -10)
    return composite(out, srcx, srcy, img, jelly)

def paste(out, lay, dx, dy):
    rgb, mask, t, l = lay
    oy, ox = int(round(t + dy)), int(round(l + dx))
    region = out[oy:oy + rgb.shape[0], ox:ox + rgb.shape[1]]
    region[mask] = rgb[mask]

def draw_strokes(out, shapes):
    """Draw sheet face shapes (image px) in CHAR-REF's face color, antialiased."""
    big = Image.new("L", (iw * SS, ih * SS), 0)
    d = ImageDraw.Draw(big)
    w = int(round(stroke * SS))
    for kind, pts in shapes:
        P = [(x * SS, y * SS) for x, y in pts]
        if kind == "line":
            d.line(P, fill=255, width=w, joint="curve")
            for p in (P[0], P[-1]):
                d.ellipse((p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2), fill=255)
        elif kind == "ring":
            (x0, y0), (x1, y1) = P
            d.ellipse((x0, y0, x1, y1), outline=255, width=w)
        elif kind == "fill":
            d.polygon(P, fill=255)
        elif kind == "disc":
            (x0, y0), (x1, y1) = P
            d.ellipse((x0, y0, x1, y1), fill=255)
    alpha = np.asarray(big.resize((iw, ih), Image.LANCZOS)).astype(float)[..., None] / 255.0
    return out * (1 - alpha) + np.array(face_color, float) * alpha

def quad(p0, c, p1, n=24):
    t = np.linspace(0, 1, n)[:, None]
    return [tuple(v) for v in ((1 - t) ** 2 * np.array(p0) + 2 * (1 - t) * t * np.array(c) + t ** 2 * np.array(p1))]

def face_shapes(kind, eye_y, dxl, mouth_c):
    """Sheet faces (CHARACTER-SHEET.md / make_character_svgs.py), in image px around the measured eyes."""
    (lx, _), (rx, _) = eye_l, eye_r
    lx, rx = lx + dxl, rx + dxl
    g = lambda v: v * kx
    mx, my = mouth_c
    S = []
    if kind == "determined":
        S += [("line", [(lx - g(4), eye_y - g(6)), (lx + g(3), eye_y - g(4.5))]),
              ("line", [(rx + g(4), eye_y - g(6)), (rx - g(3), eye_y - g(4.5))]),
              ("line", [(mx - g(3), my), (mx + g(3), my)])]
    elif kind == "worried":
        S += [("line", [(lx - g(4), eye_y - g(6)), (lx + g(3), eye_y - g(8.5))]),
              ("line", [(rx + g(4), eye_y - g(6)), (rx - g(3), eye_y - g(8.5))]),
              ("ring", [(mx - g(2.5), my - g(3)), (mx + g(2.5), my + g(3))])]
    elif kind == "down":
        S += [("ring", [(mx - g(2.5), my - g(2)), (mx + g(2.5), my + g(2))])]
    elif kind == "happy":
        for ex in (lx, rx):
            S += [("line", quad((ex - g(4), eye_y), (ex, eye_y - g(5)), (ex + g(4), eye_y)))]
        S += [("line", quad((mx - g(6), my), (mx, my + g(5)), (mx + g(6), my)))]
    elif kind == "bored":
        for ex in (lx, rx):
            rr = g(4)
            S += [("fill", [(ex + rr * math.cos(t), eye_y + rr * math.sin(t)) for t in np.linspace(0, math.pi, 25)]),
                  ("line", [(ex - g(5), eye_y), (ex + g(5), eye_y)])]
        S += [("line", [(mx - g(4), my), (mx + g(4), my)])]
    return S

def finish(out, name, W, H):
    res = np.clip(out, 0, 255).astype(np.uint8)
    oj = (res[:, :, 1].astype(int) - res[:, :, 0].astype(int)) > 15
    r_ = np.where(oj.sum(axis=1) > 3)[0]
    c_ = np.where(oj.sum(axis=0) > 3)[0]
    fp = hashlib.sha256(res.tobytes()).hexdigest()[:16]
    if name:
        Image.fromarray(res).save(os.path.join(out_dir, f"pose-guide-{name}.png"))
        print(f"{name:15s} target {W:g} x {H:g} game px; measured box {(c_[-1] + 1 - c_[0]) / kx:.1f} x "
              f"{(r_[-1] + 1 - r_[0]) / ky:.1f} game px (includes lean); fingerprint {fp}")
    return fp

def warp_pose(name, W, H, lean, taper, face_kind):
    out = warp(body, W, H, lean, taper)
    pose_top = by - ref_h * H / 64.0
    eye_y = pose_top + 0.38 * ref_h * H / 64.0
    shear = math.tan(math.radians(lean))
    dxl = shear * (by - eye_y)
    eye_dy = {"up": -2, "down": 2, "worried": -1.5}.get(face_kind, 0) * ky
    mouth_frac = {"down": 0.36, "determined": 0.36, "bored": 0.36, "worried": 0.34}.get(face_kind, 0.38)
    mouth_c = (mouth_x + dxl, by - mouth_frac * H * ky)
    if face_kind in ("neutral", "up", "down", "determined", "worried"):
        paste(out, eyes_layer, dxl, eye_y + eye_dy - ref_eye_y)
    if face_kind in ("neutral", "up"):
        paste(out, mouth_layer, dxl, (eye_y - ref_eye_y))
    out = draw_strokes(out, face_shapes(face_kind, eye_y + eye_dy, dxl, mouth_c))
    return finish(out, name, W, H)

print(f"CHAR-REF bounds {ref_w} x {ref_h} px; eyes at x {eye_l[0]:.1f} and {eye_r[0]:.1f}, y {ref_eye_y:.1f}; "
      f"mouth center ({mouth_x:.1f}, {mouth_y:.1f}); stroke {stroke:.0f} px; face color #{face_color[0]:02X}{face_color[1]:02X}{face_color[2]:02X}")

POSES = [  # id, bottom width, height, lean, taper, face  (CHARACTER-SHEET.md)
    ("CHAR-BORED", 84, 48, 0, -20, "bored"),
    ("CHAR-SCOOT-A", 72, 56, 8, 0, "neutral"),
    ("CHAR-ANTIC", 76, 50, 0, 0, "determined"),
    ("CHAR-RISE", 52, 80, 4, 0, "up"),
    ("CHAR-FALL", 70, 60, 0, 0, "down"),
    ("CHAR-LAND", 80, 46, 0, 0, "happy"),
    ("CHAR-WORRY", 62, 66, -6, 0, "worried"),
    ("CHAR-CELEBRATE", 56, 78, 0, 14, "happy"),
]
for p in POSES:
    warp_pose(*p)

# splat: sheet outline "M-50,0 q8,-14 22,-12 q8,-12 26,-6 q16,-10 28,0 q16,-4 24,18 Z"
segs = [((-50, 0), (-42, -14), (-28, -12)), ((-28, -12), (-20, -24), (-2, -18)),
        ((-2, -18), (14, -28), (26, -18)), ((26, -18), (42, -22), (50, 0))]
pts = np.array([p for s in segs for p in quad(*s, n=60)])
splat_h = lambda x: float(np.interp(x, pts[:, 0], -pts[:, 1]))
out = np.tile(MAGENTA, (ih, iw, 1))
out = nine_slice(out, body, -50, 50, splat_h)
ref_crop = Image.fromarray(np.clip(body[top:bottom, left:right], 0, 255).astype(np.uint8))
ref_mask = Image.fromarray((jelly[top:bottom, left:right] * 255).astype(np.uint8))
for (dcx, dcy, rr) in ((-46, -26, 4), (44, -30, 5)):   # droplets: the whole CHAR-REF body scaled down
    dw, dh = int(round(2 * rr * kx)), int(round(2 * rr * ky))
    drop = np.asarray(ref_crop.resize((dw, dh), Image.LANCZOS)).astype(float)
    dm = np.asarray(ref_mask.resize((dw, dh), Image.LANCZOS)).astype(float)[..., None] / 255.0
    x0, y0 = int(round(cx + dcx * kx - dw / 2)), int(round(by + dcy * ky - dh / 2))
    reg = out[y0:y0 + dh, x0:x0 + dw]
    out[y0:y0 + dh, x0:x0 + dw] = reg * (1 - dm) + drop * dm
out = draw_strokes(out, [("line", [(cx + v * kx, by + w_ * ky) for v, w_ in seg]) for seg in
                         (((-12, -11), (-6, -17)), ((-12, -17), (-6, -11)), ((10, -11), (16, -17)), ((10, -17), (16, -11)))])
finish(out, "CHAR-SPLAT", 100, 22)

# re-form: puddle "M-44,0 q10,-8 24,-6 ... L20,-6 q14,-2 24,6" with a 40 x 40 cube rising from it
p1 = np.array(quad((-44, 0), (-34, -8), (-20, -6), n=60))
p2 = np.array(quad((20, -6), (34, -8), (44, 0), n=60))
pud = np.vstack([p1, [[0, -6]], p2])
out = np.tile(MAGENTA, (ih, iw, 1))
out = nine_slice(out, body, -44, 44, lambda x: float(np.interp(x, pud[:, 0], -pud[:, 1])))
cube = nine_slice(np.tile(MAGENTA, (ih, iw, 1)), body, -20, 20, lambda x: 40.0)
keep = (Y < by - 3 * ky)[..., None] & ((np.abs(cube - MAGENTA).sum(axis=2) > 30)[..., None])
out = np.where(keep, cube, out)                          # cube over the puddle, minus its bottom outline
for ex_g in (-6, 12):                                    # sheet eye positions, CHAR-REF eye pixels
    lay_l = eyes_layer
    rgb, mask, t, l = lay_l
    # paste each CHAR-REF eye separately, centered on the sheet position
    for (ecx, ecy) in (eye_l,) if ex_g < 0 else (eye_r,):
        tx, ty = cx + ex_g * kx, by - 24 * ky
        sub = (np.arange(rgb.shape[1])[None, :] + l < mid_x) if ex_g < 0 else (np.arange(rgb.shape[1])[None, :] + l >= mid_x)
        rr_ = rgb.copy(); mm = mask & sub
        region_t, region_l = int(round(t + ty - ecy)), int(round(l + tx - ecx))
        reg = out[region_t:region_t + rgb.shape[0], region_l:region_l + rgb.shape[1]]
        reg[mm] = rr_[mm]
finish(out, "CHAR-RESPAWN", 88, 40)
