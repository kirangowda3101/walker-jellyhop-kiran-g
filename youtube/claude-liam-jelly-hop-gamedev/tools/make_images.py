"""Builds the jelly asset-trace figures for beats B03 and B04 from the project's real files.

    python3 tools/make_images.py CAPTURE_WORK_DIR      (run from the reel folder)

Every input is checked against its recorded SHA-256 first (ASSET-LOG.md, captures.sha256); a
mismatch stops the script. The raw SDXL output is read from ~/Documents/jellyhop-generations/
(read only). Output: images/B02-intro-held-frame.png, images/B03-design-prompt-raw.png,
images/B04-edits-to-engine.png, images/B08-scrape-on-descent.png, and images/images.sha256.
Frames from the capture are located by tick in capture/run-01-inputs.jsonl (movie frame = tick - 1). Annotations (boxes, labels) are drawn on separate panels or clearly
outlined; the raw output panel itself is shown unmodified apart from scaling.
"""
import hashlib
import json
import subprocess
import sys
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
REPO = REEL.parent.parent
GEN = Path.home() / 'Documents' / 'jellyhop-generations'
INPUTS = {   # path -> SHA-256 recorded in the project's logs
    GEN / 'CHAR-REF-B-seed7270-s60.png': '2c0f71a7f4eba5a56c116b8ca648b2ed15c3fe6ada8887eab7e5ddb6d410a763',  # ASSET-LOG.md CHAR-REF-B
    REPO / 'gen-inputs/char-ref-guide.png': '89c7a49fe7eb4273077e5830c5904c00d7fe777a17e1ea23fc5a5942be709d1b',  # ASSET-LOG.md shared setup
}
PROMPT = ('cute cartoon jelly cube character, rounded cube shape, glossy turquoise gelatin body, two small round '
          'dark eyes, small simple smile, thick dark teal outline, one soft white highlight on the top center, '
          'slightly darker band near the bottom, smooth clean cartoon shapes, soft shading, front view, centered, '
          'single character, game sprite, flat solid magenta background')
# ASSET-LOG.md CHAR-REF cleanup: two boxes (x0, y0, x1, y1) in the 1024 x 1024 raw image.
SPECK_BOXES = [(660, 334, 696, 373), (559, 345, 603, 390)]

W, H = 3200, 1180   # about the GodotDesignFigure image box's aspect, so the figure fills it
CREAM, INK, ACCENT, MUTED = (250, 249, 245), (61, 57, 41), (217, 119, 87), (110, 100, 86)
SERIF = str(Path.home() / 'Library/Fonts/EBGaramond-Medium.ttf')
SANS = '/System/Library/Fonts/SFNS.ttf'
MONO = '/System/Library/Fonts/SFNSMono.ttf'


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def need(p: Path, digest: str):
    if not p.is_file():
        sys.exit(f'STOPPED: missing input {p}')
    if sha(p) != digest:
        sys.exit(f'STOPPED: checksum mismatch for {p}')


def font(path, size):
    return ImageFont.truetype(path, size)


def checker(size, cell=32):
    im = Image.new('RGB', size, (236, 233, 226))
    d = ImageDraw.Draw(im)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=(214, 209, 199))
    return im


def panel(canvas, box, title, sub, image=None, bg=None):
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle(box, 18, fill=(255, 253, 248), outline=(207, 198, 181), width=4)
    d.text((x0 + 30, y0 + 22), title, font=font(SANS, 54), fill=INK)
    d.text((x0 + 30, y0 + 90), sub, font=font(SANS, 38), fill=MUTED)
    if image is not None:
        area = (x1 - x0 - 60, y1 - y0 - 170)
        im = image.copy()
        im.thumbnail(area, Image.LANCZOS)
        if bg == 'checker':
            base = checker(im.size)
            base.paste(im, (0, 0), im if im.mode == 'RGBA' else None)
            im = base
        canvas.paste(im.convert('RGB'), (x0 + 30 + (area[0] - im.width) // 2, y0 + 140 + (area[1] - im.height) // 2))


def arrow(canvas, x, y):
    d = ImageDraw.Draw(canvas)
    d.line([(x - 26, y), (x + 20, y)], fill=ACCENT, width=10)
    d.polygon([(x + 34, y), (x + 8, y - 22), (x + 8, y + 22)], fill=ACCENT)


def b03(out: Path):
    raw = Image.open(GEN / 'CHAR-REF-B-seed7270-s60.png').convert('RGB')
    guide = Image.open(REPO / 'gen-inputs/char-ref-guide.png').convert('RGB')
    c = Image.new('RGB', (W, H), CREAM)
    pw, gap, top = 960, 100, 40   # 40 + 3*960 + 2*100 = 3120 <= W
    xs = [40, 40 + pw + gap, 40 + 2 * (pw + gap)]
    panel(c, (xs[0], top, xs[0] + pw, H - 40), '1 · Design', 'gen-inputs/char-ref-guide.png (sheet front view)', guide)
    panel(c, (xs[1], top, xs[1] + pw, H - 40), '2 · Prompt', 'ASSET-LOG.md, CHAR-REF shared setup')
    d = ImageDraw.Draw(c)
    y = top + 150
    for line in textwrap.wrap(PROMPT, 32):
        d.text((xs[1] + 34, y), line, font=font(MONO, 44), fill=INK)
        y += 56
    y += 20
    for line in ['SDXL Base 1.0 · Draw Things (local)', 'image to image, strength 60%',
                 'seed 7270 · 30 steps · guidance 7.0']:
        d.text((xs[1] + 34, y), line, font=font(SANS, 44), fill=ACCENT)
        y += 58
    panel(c, (xs[2], top, xs[2] + pw, H - 40), '3 · Raw output (not in-engine)', 'CHAR-REF-B-seed7270-s60.png, unedited', raw)
    for x in (xs[1] - gap // 2, xs[2] - gap // 2):
        arrow(c, x, H // 2)
    c.save(out)


def engine_crop(work: Path, avi: str, t: float) -> Image.Image:
    png = work / f'engine-{t:.3f}.png'
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-ss', f'{t:.3f}', '-i', str(work / 'takes' / avi),
                    '-frames:v', '1', str(png)], check=True)
    return Image.open(png).convert('RGB')


def log_events(name):
    return [json.loads(l) for l in (REEL / 'capture' / f'{name}-inputs.jsonl').read_text().splitlines()]


def first(events, **match):
    for e in events:
        if all(e.get(k) == v for k, v in match.items()):
            return e
    sys.exit(f'STOPPED: no log event {match}')


def at_tick(tick):
    return (tick - 1) / 60.0


def b02(out: Path, work: Path):
    frame = engine_crop(work, 'run-01.avi', at_tick(90))   # 1.5 s into the intro pan (frozen forks, title)
    # Cropped above the table curtain (game y 533 of 720 -> 1600 of 2160): GATE T read a curtain texture blob
    # as low-contrast text (2026-10-05). The plates and sauce stay; the HUD skip hint on the curtain is cut.
    frame.crop((0, 0, 3840, 1600)).save(out)


def b08(out: Path, work: Path):
    ev = log_events('run-01')
    warn = first(ev, event='sound', id='SFX-WARN', game_state='PLAYING')
    for e in ev:   # the scrape that precedes the fork splat
        if e.get('event') == 'sound' and e.get('id') == 'SFX-SPLAT-FORK':
            splat = e
            break
    else:
        sys.exit('STOPPED: no SFX-SPLAT-FORK in run-01')
    warns = [e for e in ev if e.get('event') == 'sound' and e.get('id') == 'SFX-WARN' and e['tick'] <= splat['tick']]
    warn = warns[-1]
    ticks = [warn['tick'] - 30, warn['tick'], splat['tick'] + 1]
    labels = [f'shadow grows · {ticks[0]}', f'starts down · WARN · {warn["tick"]}',
              f'tines land · SPLAT · {splat["tick"]}']   # ticks; full event IDs are in the cards and CAPTURE.md
    c = Image.new('RGB', (W, 1060), CREAM)   # shorter canvas: no empty band under the frames
    d = ImageDraw.Draw(c)
    pw = 700
    for i, (t, lab) in enumerate(zip(ticks, labels)):
        fr = engine_crop(work, 'run-01.avi', at_tick(t)).crop((240, 180, 2160, 2160))
        fr.thumbnail((pw, 1200), Image.LANCZOS)
        x = 40 + i * (pw + 30)
        c.paste(fr, (x, 150))
        d.text((x, 60), lab, font=font(SANS, 44), fill=INK)
    d.text((40, 150 + 760), 'Frames from run-01 (scripted-input 4K capture); ticks from its input log.', font=font(SANS, 40), fill=MUTED)
    # Measured scrape counts: evidence/batch3-audio-trace-{before,after,after2}.txt (same scripted route).
    x0 = 40 + 3 * (pw + 30) + 30
    d.text((x0, 60), 'SFX-WARN per route', font=font(SANS, 48), fill=INK)
    rows = [('before', 22, 16), ('fix 1', 9, 6), ('fix 2', 8, 0)]
    for j, (name, total, idle) in enumerate(rows):
        y = 170 + j * 260
        d.text((x0, y), name, font=font(SANS, 48), fill=INK)
        d.rectangle([x0, y + 60, x0 + total * 22, y + 110], fill=INK)
        d.text((x0 + total * 22 + 14, y + 58), str(total), font=font(SANS, 48), fill=INK)
        d.rectangle([x0, y + 125, x0 + max(idle * 22, 4), y + 175], fill=ACCENT)
        d.text((x0 + max(idle * 22, 4) + 14, y + 123), f'{idle} idle', font=font(SANS, 48), fill=ACCENT)
    d.text((x0, 900), 'evidence/batch3-audio-trace-*.txt', font=font(SANS, 36), fill=MUTED)
    c.save(out)
    return {'warn_tick': warn['tick'], 'splat_tick': splat['tick']}


def b04(out: Path, work: Path):
    raw = Image.open(GEN / 'CHAR-REF-B-seed7270-s60.png').convert('RGB')
    ref = Image.open(REPO / 'art/reference/CHAR-REF.png').convert('RGB')
    cut = Image.open(REPO / 'art/game/CHAR-IDLE.png').convert('RGBA')
    copy = REPO / 'godot/assets/art/CHAR-IDLE.png'
    if sha(copy) != sha(REPO / 'art/game/CHAR-IDLE.png'):
        sys.exit('STOPPED: godot/assets/art/CHAR-IDLE.png is not byte-identical to art/game/CHAR-IDLE.png')
    ev = log_events('run-01')
    hop = first(ev, event='sound', id='SFX-HOP')
    tick = hop['tick'] - 20          # standing on plate 1 just before the first hop (IDLE pose)
    frame = engine_crop(work, 'run-01.avi', at_tick(tick))
    eng = frame.crop((795, 1074, 1395, 1614))   # around the jelly: game x 365, feet at y 498 (x3 at 4K)
    spec = {'label': f'run-01, tick {tick}, crop at 1:1'}
    zoom = (520, 290, 740, 430)   # the two speck boxes, shown at 4x
    raw_z = raw.crop(zoom).resize(((zoom[2] - zoom[0]) * 4, (zoom[3] - zoom[1]) * 4), Image.NEAREST)
    d = ImageDraw.Draw(raw_z)
    for b in SPECK_BOXES:
        d.rectangle([(b[0] - zoom[0]) * 4, (b[1] - zoom[1]) * 4, (b[2] - zoom[0]) * 4, (b[3] - zoom[1]) * 4], outline=ACCENT, width=8)
    ref_z = ref.crop(zoom).resize(raw_z.size, Image.NEAREST)
    c = Image.new('RGB', (W, H), CREAM)
    pw, gap, top = 700, 100, 40   # 40 + 4*700 + 3*100 = 3140 <= W
    xs = [40 + i * (pw + gap) for i in range(4)]
    panel(c, (xs[0], top, xs[0] + pw, H - 40), 'a · Raw, 4x zoom', 'two stray dots (boxes added)', raw_z)
    panel(c, (xs[1], top, xs[1] + pw, H - 40), 'b · Speck removal', '1,954 px in 2 boxes · CHAR-REF', ref_z)
    panel(c, (xs[2], top, xs[2] + pw, H - 40), 'c · Magenta cut out', 'art/game/CHAR-IDLE.png', cut, bg='checker')
    panel(c, (xs[3], top, xs[3] + pw, H - 40), 'd · In engine, 4K capture', spec['label'], eng)
    for x in xs[1:]:
        arrow(c, x - gap // 2, H // 2)
    c.save(out)


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: make_images.py CAPTURE_WORK_DIR')
    work = Path(sys.argv[1])
    for p, digest in INPUTS.items():
        need(p, digest)
    run = {l.split()[1]: l.split()[0] for l in (REEL / 'capture/captures.sha256').read_text().splitlines()}
    for avi in ('run-01.avi',):
        if sha(work / 'takes' / avi) != run[avi]:
            sys.exit(f'STOPPED: {avi} does not match captures.sha256')
    out = REEL / 'images'
    out.mkdir(exist_ok=True)
    b02(out / 'B02-intro-held-frame.png', work)
    b03(out / 'B03-design-prompt-raw.png')
    b04(out / 'B04-edits-to-engine.png', work)
    print(json.dumps(b08(out / 'B08-scrape-on-descent.png', work)))
    lines = [f'{sha(p)}  {p.name}' for p in sorted(out.glob('*.png'))]
    (out / 'images.sha256').write_text('\n'.join(lines) + '\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
