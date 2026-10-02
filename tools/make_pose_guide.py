"""Builds an image-to-image guide for one pose by warping the accepted CHAR-REF.
Written by Claude at Kiran's request.
Usage: python3 tools/make_pose_guide.py CHAR-REF.png OUTPUT.png WIDTH HEIGHT LEAN [TAPER]
WIDTH, HEIGHT: the pose's bottom width and height in game px, from CHARACTER-SHEET.md.
LEAN: degrees, positive leans the top toward the facing side (right). TAPER: top width
minus bottom width in game px (default 0).
Scale: CHAR-REF's own measured jelly bounds count as the 64 x 64 resting cube, so a pose of
WIDTH x HEIGHT is drawn at (WIDTH/64 x bounds width) by (HEIGHT/64 x bounds height).
Steps: (1) cut the jelly out of CHAR-REF (pixels where green clearly exceeds red, with each
row filled across so the highlight is included) and measure its bounds;
(2) lift the face (dark eye and mouth pixels inside the body) onto its own layer and fill
the body where it was; (3) warp the body: scale to the pose's size, taper, and lean,
keeping the bottom-center fixed; (4) paste the face back unscaled, placing the eyes'
center 38% down from the pose's top, shifted sideways with the lean; (5) place the result
on flat #FF00FF at 1024 x 1024. Every jelly pixel comes from CHAR-REF. Prints what it did,
including the measured pose size in game px.
"""
import sys, math, hashlib
import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
W, H, LEAN = float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5])
TAPER = float(sys.argv[6]) if len(sys.argv) > 6 else 0.0
MAGENTA = np.array([255, 0, 255])

a = np.asarray(Image.open(src).convert("RGB")).astype(float)
ih, iw = a.shape[:2]
jelly = (a[:, :, 1] - a[:, :, 0]) > 15
for r in range(ih):                       # fill each row between its first and last jelly pixel,
    c = np.where(jelly[r])[0]             # so the near-white highlight counts as jelly too
    if len(c) > 3:
        jelly[r, c[0]:c[-1] + 1] = True
rows, cols = np.where(jelly.sum(axis=1) > 3)[0], np.where(jelly.sum(axis=0) > 3)[0]
top, bottom, left, right = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
cx, by = (left + right) / 2.0, float(bottom)          # bottom-center of the reference jelly
ref_w, ref_h = right - left, bottom - top             # measured bounds = the 64 x 64 resting cube

# (2) face: dark pixels well inside the body (not the outline), grown by 4 px
inner = np.zeros_like(jelly)
m = int(ref_h * 0.12)
inner[top + m:bottom - int(ref_h * 0.30), left + m:right - m] = True   # excludes outline and band
dark = (a.sum(axis=2) < 240) & inner
pad = np.pad(dark, 4)
face = np.zeros_like(dark)
for dy in range(9):
    for dx in range(9):
        face |= pad[dy:dy + ih, dx:dx + iw]
face &= inner
ys, xs = np.where(face)
f_top, f_bottom, f_left, f_right = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
face_rgb = a[f_top:f_bottom, f_left:f_right].copy()
face_mask = face[f_top:f_bottom, f_left:f_right] & dark[f_top:f_bottom, f_left:f_right] | \
            (face[f_top:f_bottom, f_left:f_right] & (np.abs(a[f_top:f_bottom, f_left:f_right] -
             np.median(a[inner & ~face], axis=0)).sum(axis=2) > 40))
body = a.copy()
body[face] = np.median(a[inner & ~face], axis=0)      # fill where the face was
# eyes only: split the face's dark rows at the largest vertical gap (eyes above, mouth below)
dy_, dx_ = np.where(dark)
rows_d = np.unique(dy_)
split = rows_d[np.diff(rows_d).argmax()]
ref_eye_y = dy_[dy_ <= split].mean()                   # eyes' center row in CHAR-REF

# (3) warp the body by inverse mapping, bottom-center fixed
sy = H / 64.0
out = np.tile(MAGENTA, (ih, iw, 1)).astype(float)
Y, X = np.mgrid[0:ih, 0:iw].astype(float)
up = by - Y                                            # height above the bottom, output px
u = np.clip(up / (ref_h * sy), 0, 1)                   # 0 at bottom, 1 at top of the pose
sx = (W + TAPER * u) / 64.0
shear = math.tan(math.radians(LEAN))
srcx = cx + (X - cx - shear * up) / sx
srcy = by - up / sy
def bilinear(img, x, y):
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    x0c, y0c = np.clip(x0, 0, iw - 2), np.clip(y0, 0, ih - 2)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    return (img[y0c, x0c] * (1 - fx) * (1 - fy) + img[y0c, x0c + 1] * fx * (1 - fy) +
            img[y0c + 1, x0c] * (1 - fx) * fy + img[y0c + 1, x0c + 1] * fx * fy)
inside = (srcx >= 0) & (srcx < iw - 1) & (srcy >= 0) & (srcy < ih - 1)
cov = np.zeros((ih, iw))
cov[inside] = bilinear(jelly.astype(float)[..., None], srcx[inside], srcy[inside])[:, 0]
col = np.zeros((ih, iw, 3))
col[inside] = bilinear(body, srcx[inside], srcy[inside])
out = out * (1 - cov[..., None]) + col * cov[..., None]

# (4) paste the face unscaled: eyes' center 38% down from the pose's top, shifted with the lean
pose_top = by - ref_h * sy
target_eye_y = pose_top + 0.38 * ref_h * sy
dy_face = target_eye_y - ref_eye_y
dx_face = shear * (by - target_eye_y)                   # the body's lean shift at that height
ox, oy = int(round(f_left + dx_face)), int(round(f_top + dy_face))
region = out[oy:oy + face_rgb.shape[0], ox:ox + face_rgb.shape[1]]
region[face_mask] = face_rgb[face_mask]
result = np.clip(out, 0, 255).astype(np.uint8)
Image.fromarray(result).save(dst)
print(f"reference jelly box x {left}-{right}, y {top}-{bottom}; face box x {f_left}-{f_right}, y {f_top}-{f_bottom}")
oj = (result[:, :, 1].astype(int) - result[:, :, 0].astype(int)) > 15
orows = np.where(oj.sum(axis=1) > 3)[0]
mid = (orows[0] + orows[-1]) // 2
mcols = np.where(oj[mid])[0]
print(f"reference bounds {ref_w} x {ref_h} px = 64 x 64 game px; eyes' center at y {ref_eye_y:.1f}")
print(f"pose {W:g} x {H:g} game px, lean {LEAN:g} deg, taper {TAPER:g}")
print(f"measured result: height {(orows[-1] + 1 - orows[0]) * 64 / ref_h:.1f} game px, "
      f"width at mid-height {(mcols[-1] + 1 - mcols[0]) * 64 / ref_w:.1f} game px (target {W:g} x {H:g}"
      f"{'' if TAPER == 0 else ' at the bottom'})")
print(f"face moved by ({dx_face:+.0f}, {dy_face:+.0f}) px, not scaled; eyes' center now "
      f"{(target_eye_y - pose_top) / (ref_h * sy) * 100:.0f}% down from the pose's top")
print("output pixel fingerprint (sha256):", hashlib.sha256(result.tobytes()).hexdigest()[:16])
print("wrote", dst)

