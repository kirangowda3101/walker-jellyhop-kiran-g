"""Removes stray specks inside small boxes by painting them with each box's typical color.
Written by Claude at Kiran's request; used as a logged edit.
Usage: python3 tools/remove_specks.py INPUT.png OUTPUT.png L T R B [L T R B ...]
       THRESH=15 GROW=6 FILL=smooth python3 tools/remove_specks.py ...
       (THRESH: fainter specks, default 40; GROW: margin, default 3; FILL=smooth blends the
       area in from its surroundings instead of one flat color; SELECT=pink picks only pinkish
       pixels, for marks next to dark face lines. Defaults reproduce the CHAR-REF edit exactly.)
Each box (left, top, right, bottom, in pixels) is handled on its own: pixels that differ
clearly from that box's median color, plus a GROW px margin, are replaced with the median of
the untouched pixels around them (flat), or blended in from those pixels (smooth).
Nothing outside the boxes changes, and the input file is never modified. Prints, per box,
the color used and the pixels changed, plus a fingerprint of the output's pixels so the
same edit can be checked on another machine.
"""
import os, sys, hashlib
import numpy as np
from PIL import Image

src, dst, nums = sys.argv[1], sys.argv[2], list(map(int, sys.argv[3:]))
THRESH = int(os.environ.get("THRESH", "40"))       # how different a pixel must be to count as a speck
GROW = int(os.environ.get("GROW", "3"))            # margin added around each speck, in px
FILL = os.environ.get("FILL", "flat")              # "flat" = ring color (default), "smooth" = blend in
SELECT = os.environ.get("SELECT", "diff")          # "diff" (default) or "pink": only pixels redder than green
im = np.asarray(Image.open(src).convert("RGB")).copy()
total = 0
for k in range(0, len(nums), 4):
    left, top, right, bottom = nums[k:k + 4]
    box = im[top:bottom, left:right].astype(int)
    median = np.median(box.reshape(-1, 3), axis=0).astype(int)
    mask = np.abs(box - median).sum(axis=2) > THRESH   # clearly different from the box color
    if SELECT == "pink":                           # only pinkish pixels (red clearly above green)
        mask = (box[:, :, 0] > box[:, :, 1] + 10) & (box[:, :, 0] > 90)
    pad = np.pad(mask, GROW)                       # grow by GROW px to cover soft edges
    grown = np.zeros_like(mask)
    for dy in range(2 * GROW + 1):
        for dx in range(2 * GROW + 1):
            grown |= pad[dy:dy + mask.shape[0], dx:dx + mask.shape[1]]
    if not (~grown).any():
        sys.exit(f"box x {left}-{right}, y {top}-{bottom}: no untouched pixels left around the speck; use a larger box")
    fill = np.median(box[~grown], axis=0).astype(int)   # color from the untouched ring around the speck
    if FILL == "smooth":
        # blend the speck area in from its surroundings: start from the ring color, then repeatedly
        # set each speck pixel to the average of its 4 neighbors (keeps gentle shading gradients)
        work = box.astype(float)
        work[grown] = fill
        for _ in range(600):
            p = np.pad(work, ((1, 1), (1, 1), (0, 0)), mode="edge")
            avg = (p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]) / 4.0
            work[grown] = avg[grown]
        box = np.rint(work).astype(int)
    else:
        box[grown] = fill
    median = fill
    im[top:bottom, left:right] = box.astype(np.uint8)
    total += int(grown.sum())
    print(f"box x {left}-{right}, y {top}-{bottom}: color #{median[0]:02X}{median[1]:02X}{median[2]:02X}, "
          f"{int(grown.sum())} of {box.shape[0] * box.shape[1]} pixels changed")
Image.fromarray(im).save(dst)
print(f"threshold {THRESH}, grow {GROW}, fill {FILL}, select {SELECT}; total pixels changed: {total}")
print("output pixel fingerprint (sha256):", hashlib.sha256(im.tobytes()).hexdigest()[:16])
print("wrote", dst)
