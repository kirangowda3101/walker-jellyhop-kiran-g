#!/usr/bin/env python3
"""TEST-REPORT comparison images (reads only; writes two PNGs to evidence/).
  evidence/test-character-vs-sheet.png    each CHARACTER-SHEET pose (design/character/poses.svg) beside the in-engine
                                          pose facing right and left (evidence/test-poses/, from godot/tests/capture_poses.gd),
                                          with the active collision box (magenta) and its size
  evidence/test-storyboard-vs-slice.png   each STORYBOARD panel (design/storyboard/*.svg) beside the in-engine screenshot of
                                          the same moment (evidence/slice-screens/, from godot/tests/capture_slice.gd)
Run in ~/Documents/jellyhop-audio-env (needs cairosvg and Homebrew's cairo):
  DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python tools/test_report_images.py
"""
import io, sys
from pathlib import Path
import cairosvg
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
EV = REPO / "evidence"
POSES = [(2, "IDLE", "standing"), (3, "BORED", "low"), (4, "SCOOT-A", "standing"), (5, "SCOOT-B", "standing"),
         (6, "ANTIC", "low"), (7, "RISE", "standing"), (8, "FALL", "standing"), (9, "LAND", "low"),
         (10, "WORRY", "standing"), (11, "SPLAT", "hits off"), (12, "RESPAWN", "hits off"), (13, "CELEBRATE", "standing")]
PANELS = [("01-establishing-wide", "01-intro-pan"), ("02-core-action-hop", "02-hop"), ("03-warning-closeup-low", "03-warning"),
          ("04-success-landing", "04-safe-landing"), ("05-failure-splat", "05-splat"), ("06-recovery-respawn", "06-respawn"),
          ("07-end-dome-closeup-high", "07-dome")]


def font(size):
    return ImageFont.load_default(size=size)


def svg(path, width=None):
    return Image.open(io.BytesIO(cairosvg.svg2png(url=str(path), output_width=width))).convert("RGB")


def boxes():
    out = {}
    for line in (EV / "test-poses" / "boxes.txt").read_text().splitlines()[1:]:
        pose, facing, flip, box, kind = [x.strip() for x in line.split("|")]
        out[(pose, facing)] = (box, kind, flip)
    return out


def character():
    sheet = svg(REPO / "design" / "character" / "poses.svg")
    if sheet.size != (1400, 1080):
        sys.exit(f"STOPPED: unexpected poses.svg size {sheet.size}")
    b = boxes()
    cell_w, cell_h, eng = 268, 320, 320
    row_h, label_h = cell_h + 70, 30
    W = 2 * (cell_w + 2 * eng + 60) + 40
    H = label_h + 60 + 6 * row_h
    img = Image.new("RGB", (W, H), (250, 250, 250))
    d = ImageDraw.Draw(img)
    d.text((20, 14), "Character vs CHARACTER-SHEET: sheet pose (poses.svg, 2.5x) | in-engine facing right | in-engine facing left "
                     "(4x zoom; magenta = active collision box)", fill=(17, 17, 17), font=font(22))
    for i, (num, pose, sheet_box) in enumerate(POSES):
        col, row = divmod(i, 6)
        x0 = 20 + col * (cell_w + 2 * eng + 60)
        y0 = label_h + 50 + row * row_h
        r, c = divmod(num - 1, 5)
        crop = sheet.crop((6 + 280 * c, 94 + 330 * r, 6 + 280 * c + cell_w, 94 + 330 * r + cell_h))
        img.paste(crop, (x0, y0))
        for k, facing in enumerate(("R", "L")):
            shot = Image.open(EV / "test-poses" / f"{pose}-{facing}.png").convert("RGB").resize((eng, eng), Image.LANCZOS)
            img.paste(shot, (x0 + cell_w + 10 + k * (eng + 10), y0))
        box, kind, _ = b[(pose, "right")]
        flips = f"flip_h right {b[(pose, 'right')][2]}, left {b[(pose, 'left')][2]}"
        note = f"{num}. CHAR-{pose}: sheet box {sheet_box}; in engine {kind} {box.replace('(', '').replace(')', '').replace(', ', ' x ')}; {flips}"
        mismatch = (sheet_box in ("standing", "low") and sheet_box != kind)
        d.text((x0, y0 + cell_h + 8), note, fill=(180, 30, 30) if mismatch else (40, 40, 40), font=font(17))
        if mismatch:
            d.text((x0, y0 + cell_h + 32), "MISMATCH with the sheet (see TEST-REPORT.md)", fill=(180, 30, 30), font=font(17))
    out = EV / "test-character-vs-sheet.png"
    img.save(out, optimize=True)
    return out


def storyboard():
    w, h = 640, 360
    row_h = h + 50
    img = Image.new("RGB", (2 * w + 60, 60 + 7 * row_h), (250, 250, 250))
    d = ImageDraw.Draw(img)
    d.text((20, 14), "Storyboard vs slice: STORYBOARD panel (left) | in-engine screenshot of the same moment, 1280 x 720 scaled (right)",
           fill=(17, 17, 17), font=font(22))
    for i, (panel, shot) in enumerate(PANELS):
        y0 = 60 + i * row_h
        img.paste(svg(REPO / "design" / "storyboard" / f"{panel}.svg", 1280).resize((w, h), Image.LANCZOS), (20, y0))
        img.paste(Image.open(EV / "slice-screens" / f"{shot}.png").convert("RGB").resize((w, h), Image.LANCZOS), (40 + w, y0))
        d.text((20, y0 + h + 8), f"Panel {i + 1}: {panel}.svg  |  slice: evidence/slice-screens/{shot}.png", fill=(40, 40, 40), font=font(18))
    out = EV / "test-storyboard-vs-slice.png"
    img.save(out, optimize=True)
    return out


if __name__ == "__main__":
    for p in (character(), storyboard()):
        im = Image.open(p)
        print(f"wrote {p.relative_to(REPO)} {im.size[0]}x{im.size[1]}, {p.stat().st_size / 1e6:.2f} MB")
