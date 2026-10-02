"""Shows candidate images at real game size for a readability check.
Written by Claude at Kiran's request.
Usage: python3 tools/check_64px.py OUTPUT.png IMAGE1.png IMAGE2.png ...
For each image, finds the character's own bounds (pixels where green clearly exceeds red,
which catches the turquoise body and dark teal outline but not the magenta or purple
background), crops to them, and scales the crop to 64 px tall, keeping its proportions.
Top row: actual game size on the dim table color. Bottom row: the same pixels enlarged 4x
(nearest neighbor), so lost detail is easy to see. Prints each crop box for the log.
"""
import sys
import numpy as np
from PIL import Image, ImageDraw

TARGET_H = 64             # resting jelly height in game px
ZOOM = 4
TABLE = (42, 35, 32)      # placeholder table color #2A2320
out_path, paths = sys.argv[1], sys.argv[2:]

def character_crop(path):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    mask = (a[:, :, 1] - a[:, :, 0]) > 15            # green > red: jelly body and teal outline
    rows = np.where(mask.sum(axis=1) > 3)[0]          # ignore rows/cols with only stray pixels
    cols = np.where(mask.sum(axis=0) > 3)[0]
    top, bottom, left, right = rows[0], rows[-1] + 1, cols[0], cols[-1] + 1
    crop = im.crop((left, top, right, bottom))
    w = max(1, round(crop.width * TARGET_H / crop.height))
    print(f"{path}: character box x {left}-{right}, y {top}-{bottom} "
          f"({right-left} x {bottom-top} px) -> {w} x {TARGET_H} px")
    return crop.resize((w, TARGET_H), Image.LANCZOS)

small = [character_crop(p) for p in paths]
cell = max(im.width for im in small) * ZOOM
gap = 40
sheet = Image.new("RGB", (gap + len(small) * (cell + gap), TARGET_H + TARGET_H * ZOOM + 3 * gap + 20), TABLE)
d = ImageDraw.Draw(sheet)
for i, (im, p) in enumerate(zip(small, paths)):
    x = gap + i * (cell + gap)
    sheet.paste(im, (x, gap))
    sheet.paste(im.resize((im.width * ZOOM, TARGET_H * ZOOM), Image.NEAREST), (x, TARGET_H + 2 * gap))
    d.text((x, TARGET_H + TARGET_H * ZOOM + 2 * gap + 4), p.split("/")[-1], fill=(230, 230, 230))
sheet.save(out_path)
print("wrote", out_path, sheet.size)
