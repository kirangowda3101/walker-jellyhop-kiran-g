"""Removes stray specks inside small boxes by painting them with each box's typical color.
Written by Claude at Kiran's request; used as a logged edit.
Usage: python3 tools/remove_specks.py INPUT.png OUTPUT.png L T R B [L T R B ...]
Each box (left, top, right, bottom, in pixels) is handled on its own: pixels that differ
clearly from that box's median color, plus a 3 px margin, are replaced with the median of
the untouched pixels around them.
Nothing outside the boxes changes, and the input file is never modified. Prints, per box,
the color used and the pixels changed, plus a fingerprint of the output's pixels so the
same edit can be checked on another machine.
"""
import sys, hashlib
import numpy as np
from PIL import Image

src, dst, nums = sys.argv[1], sys.argv[2], list(map(int, sys.argv[3:]))
im = np.asarray(Image.open(src).convert("RGB")).copy()
total = 0
for k in range(0, len(nums), 4):
    left, top, right, bottom = nums[k:k + 4]
    box = im[top:bottom, left:right].astype(int)
    median = np.median(box.reshape(-1, 3), axis=0).astype(int)
    mask = np.abs(box - median).sum(axis=2) > 40   # clearly different from the box color
    pad = np.pad(mask, 3)                          # grow by 3 px to cover soft edges
    grown = np.zeros_like(mask)
    for dy in range(7):
        for dx in range(7):
            grown |= pad[dy:dy + mask.shape[0], dx:dx + mask.shape[1]]
    fill = np.median(box[~grown], axis=0).astype(int)   # color from the untouched ring around the speck
    box[grown] = fill
    median = fill
    im[top:bottom, left:right] = box.astype(np.uint8)
    total += int(grown.sum())
    print(f"box x {left}-{right}, y {top}-{bottom}: color #{median[0]:02X}{median[1]:02X}{median[2]:02X}, "
          f"{int(grown.sum())} of {box.shape[0] * box.shape[1]} pixels changed")
Image.fromarray(im).save(dst)
print(f"total pixels changed: {total}")
print("output pixel fingerprint (sha256):", hashlib.sha256(im.tobytes()).hexdigest()[:16])
print("wrote", dst)
