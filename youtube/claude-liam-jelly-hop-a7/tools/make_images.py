"""Builds the A7 film's figures from Kiran's committed evidence and the film's own scripted capture.

    python3 tools/make_images.py      (after tools/make_clips.py)

Written by Claude Code, 2026-11-17, after the A6 film's make_images.py. Inputs are read from the read-only snapshot
(git archive of c1bbb13) and each one is compared byte for byte with `git show c1bbb13:<path>` from Kiran's
repository (a read-only git command) before use; a mismatch stops the script. Captures are cropped and scaled, never
retouched. Quoted text is checked verbatim against its file. Held frames from the film's own scripted capture come
from _work/held (hashes in media/clips.json). Diagrams are labelled as diagrams drawn from the files.
Output: images/*.png, images/images.sha256, images/inputs.sha256.
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
SNAP = REEL.parent / 'snapshot-c1bbb13'
REPO = Path('/Users/kiran/Documents/walker-jellyhop-kiran-g')
REV = 'c1bbb13'
W, H = 3200, 1250
CREAM, INK, ACCENT, MUTED, LINE = (250, 249, 245), (61, 57, 41), (152, 80, 57), (100, 90, 76), (207, 198, 181)
CODEBG, CODEFG = (38, 42, 54), (232, 230, 222)
PHASE = {'startup': (196, 120, 84), 'active': (152, 80, 57), 'recovery': (110, 140, 120)}
SERIF = str(Path.home() / 'Library/Fonts/EBGaramond-Medium.ttf')
SANS = '/System/Library/Fonts/SFNS.ttf'
MONO = '/System/Library/Fonts/SFNSMono.ttf'
STRIP_CROP = (200, 418, 330, 522)     # plate-1 jelly and the rim in the 1280 x 720 land fixture frames
SCOOT_CROP = (175, 400, 435, 525)     # the plate-1 scoot range in the 1280 x 720 scoot fixture frames
USED = {}


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def repo_file(rel) -> Path:
    p = SNAP / rel
    if not p.is_file():
        sys.exit(f'STOPPED: missing {rel}')
    if rel not in USED:
        committed = subprocess.run(['git', '-C', str(REPO), 'show', f'{REV}:{rel}'], capture_output=True)
        if committed.returncode != 0 or committed.stdout != p.read_bytes():
            sys.exit(f'STOPPED: {rel} differs from its committed copy at {REV}')
        USED[rel] = sha(p)
    return p


def img(rel) -> Image.Image:
    return Image.open(repo_file(rel)).convert('RGB')


def text_of(rel) -> str:
    return repo_file(rel).read_text()


def line_of(rel, n) -> str:
    return text_of(rel).splitlines()[n - 1]


def quote(rel, s) -> str:
    if s not in text_of(rel):
        sys.exit(f'STOPPED: quoted text not found verbatim in {rel}: {s[:70]}')
    return s


def log_line(rel, startswith) -> str:
    hits = [l for l in text_of(rel).splitlines() if l.startswith(startswith)]
    if len(hits) != 1:
        sys.exit(f'STOPPED: {len(hits)} lines in {rel} start with {startswith!r}')
    return hits[0]


def font(path, size):
    return ImageFont.truetype(path, size)


def fit(im, bw, bh):
    k = min(bw / im.width, bh / im.height)
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def framed(c, im, x, y, color=LINE, width=3):
    c.paste(im, (x, y))
    ImageDraw.Draw(c).rectangle([x - width, y - width, x + im.width + width - 1, y + im.height + width - 1],
                                outline=color, width=width)


def label(d, x, y, t, size=46, fill=INK, face=SANS):
    d.text((x, y), t, font=font(face, size), fill=fill)
    if x + font(face, size).getlength(t) > W - 20:
        sys.exit(f'STOPPED: text runs off the canvas: {t[:60]}')


def wrap(d, x, y, t, width, size=46, fill=INK, face=SANS, gap=1.3):
    f = font(face, size)
    line = ''
    for w in t.split(' '):
        trial = (line + ' ' + w).strip()
        if f.getlength(trial) > width and line:
            d.text((x, y), line, font=f, fill=fill)
            y += int(size * gap)
            line = w
        else:
            line = trial
    if line:
        d.text((x, y), line, font=f, fill=fill)
        y += int(size * gap)
    return y


def code_line(c, d, x, y, w, text, num=None, size=40, hl=False):
    """A dark code strip: the line number and the line, verbatim."""
    f = font(MONO, size)
    h = size + 30
    d.rectangle([x, y, x + w, y + h], fill=(70, 52, 44) if hl else CODEBG)
    tx = x + 24
    if num is not None:
        d.text((tx, y + 14), f'{num:>3}', font=f, fill=(150, 156, 170))
        tx += int(f.getlength('0000 '))
    t = text.replace('\t', '    ')
    d.text((tx, y + 14), t, font=f, fill=CODEFG)
    if tx + f.getlength(t) > x + w:
        sys.exit(f'STOPPED: code line overflows: {text[:60]}')
    return y + h


def canvas():
    c = Image.new('RGB', (W, H), CREAM)
    return c, ImageDraw.Draw(c)


def held(name, clips):
    p = REEL / '_work/held' / name
    if sha(p) != clips['held'][name]['sha256']:
        sys.exit(f'STOPPED: held frame {name} hash mismatch')
    return Image.open(p).convert('RGB')


def capture_x(tick):
    for l in (REEL / 'capture/run-a7-inputs.jsonl').read_text().splitlines():
        e = json.loads(l)
        if e.get('event') == 'frame' and e['physics_frame'] == tick:
            return e['x']
    sys.exit(f'STOPPED: tick {tick} not in the capture log')


def jelly_crop(im, tick, w=600, h=420):
    """A held frame is the 1920x1080 crop of the 4K frame (game canvas x 0-640, y 233-593, 3 px per game px)."""
    cx = round(capture_x(tick) * 3)
    y1 = round((498 - 233.33) * 3) + 40
    return im.crop((cx - w // 2, y1 - h, cx + w // 2, y1))


def strip_frame(rel, crop=STRIP_CROP, k=3.6):
    im = img(rel).crop(crop)
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def heading(d, t, y=36):
    label(d, 60, y, t, 62, ACCENT, SERIF)


# ---------- B02 identify ----------
def b02(clips):
    c, d = canvas()
    brief = 'CHANGE-BRIEF.md'
    for i, (name, title, route_line, route) in enumerate([
            ('held-scoot-b.png', '“scoot” · the looping cycle', 11, 'Two cells on a Sprite2D, held by a discrete `frame` track.'),
            ('held-land-rig2.png', '“land” · the committing action', 12,
             'Two Sprite2D cutouts under Node2D pivots. The pieces move and scale without swapping drawings.')]):
        x = 60 + i * 1580
        e = clips['held'][name]
        im = fit(jelly_crop(held(name, clips), e['tick']), 1480, 600)
        framed(c, im, x, 40)
        y = 40 + im.height + 16
        label(d, x, y, f'Held frame · scripted capture, tick {e["tick"]} · {e["pose"]}, clip {e["cur"]} · crop of the 4K frame', 36, MUTED)
        label(d, x, y + 70, title, 64, ACCENT, SERIF)
        y = wrap(d, x, y + 160, 'Route (CHANGE-BRIEF.md line %d): ' % route_line + quote(brief, route).replace('`', ''), 1460, 44)
        if i == 0:
            wrap(d, x, y + 10, 'Sheet packed from Kiran\'s A2 CHAR-SCOOT-A / B art · 7 ticks per cell · LOOP_LINEAR', 1460, 44, MUTED)
        else:
            wrap(d, x, y + 10, 'Cut from CHAR-IDLE.png at y 622 · keys at frames 0, 2, 4, 8 · LOOP_NONE', 1460, 44, MUTED)
    return c


# ---------- B04 the sheet and its slicing ----------
def b04():
    c, d = canvas()
    sheet = Image.open(repo_file('godot/assets/art/CHAR-SCOOT-SHEET.png')).convert('RGBA')
    k = 1000 / sheet.height
    sw, sh = round(sheet.width * k), round(sheet.height * k)
    board = Image.new('RGB', (sw, sh), (236, 232, 222))
    bd = ImageDraw.Draw(board)
    for yy in range(0, sh, 40):
        for xx in range(0, sw, 40):
            if (xx // 40 + yy // 40) % 2:
                bd.rectangle([xx, yy, xx + 39, yy + 39], fill=(222, 216, 204))
    board.paste(sheet.resize((sw, sh), Image.LANCZOS), (0, 0), sheet.resize((sw, sh), Image.LANCZOS))
    x0, y0 = 60, 160
    framed(c, board, x0, y0)
    d.line([x0 + sw // 2, y0, x0 + sw // 2, y0 + sh], fill=ACCENT, width=8)
    heading(d, 'CHAR-SCOOT-SHEET.png · 2048 × 1024 · hframes 2, vframes 1', 40)
    label(d, x0 + 20, y0 + 16, 'frame 0 · cell 0 · x 0–1023', 44, ACCENT)
    label(d, x0 + sw // 2 + 20, y0 + 16, 'frame 1 · cell 1 · x 1024–2047', 44, ACCENT)
    tx = x0 + sw + 80
    label(d, tx, 170, 'Kiran\'s committed file, scaled; the checkerboard', 40, MUTED)
    label(d, tx, 220, 'shows the transparent pixels. Divider: hframes 2.', 40, MUTED)
    y = 320
    for head, body in (('Cell 0', 'CHAR-SCOOT-A.png, unchanged'), ('Cell 1', 'CHAR-SCOOT-B.png, unchanged'),
                       ('Slicing', '2048 ÷ hframes 2 = 1024 px wide; 1024 ÷ vframes 1 = 1024 px tall'),
                       ('Packed by', 'godot/tools/make_scoot_sheet.gd: 0 mismatched pixels per cell'),
                       ('Read by', 'scoot.tres line 11: FacingPivot/Scoot/ScootSprite:frame')):
        label(d, tx, y, head, 50, ACCENT, SERIF)
        y = wrap(d, tx + 270, y + 4, body, W - tx - 330, 44) + 30
    quote('godot/assets/art/CHAR-SCOOT-SHEET.ATTRIBUTION.md', 'Its checks found 0 mismatched pixels in each cell against its source')
    return c


# ---------- B06 scoot fixture strip ----------
def b06():
    c, d = canvas()
    heading(d, 'The frame track reading the sheet · fixture strip r1 (scoot_preview, 60 fps)')
    base = 'captures/scoot/r1/'
    log = text_of(base + 'scoot.log')
    rows = [('facing right · swap 1', ['scoot_right_swap1_before_clip6_cell0_png00000259.png',
                                       'scoot_right_swap1_on_clip7_cell1_png00000260.png',
                                       'scoot_right_swap1_after_clip8_cell1_png00000261.png']),
            ('facing left · wrap 1', ['scoot_left_wrap1_before_clip13_cell1_png00000322.png',
                                      'scoot_left_wrap1_on_clip0_cell0_png00000323.png',
                                      'scoot_left_wrap1_after_clip1_cell0_png00000324.png'])]
    y = 150
    for title, files in rows:
        label(d, 60, y + 150, title, 50, ACCENT, SERIF)
        x = 560
        for f in files:
            im = strip_frame(base + f, SCOOT_CROP, 3.0)
            im = fit(im, 860, 380)
            framed(c, im, x, y)
            n = int(re.search(r'png(\d+)', f).group(1))
            fl = [l for l in log.splitlines() if l.startswith(f'FRAME {n} ')][0]
            m = re.search(r'clip=(\S+) t=(\S+) cell=(\d)', fl)
            label(d, x, y + im.height + 8, f'frame {n} · clip {m.group(1)} t={m.group(2)} · cell {m.group(3)}', 36, MUTED)
            x += im.width + 50
        y += 500
    label(d, 60, 1180, 'Fixture capture · preview scene, not gameplay · Kiran\'s Movie Maker run · crops of 1280 × 720 frames, '
          'enlarged 3× · values from captures/scoot/r1/scoot.log', 36, MUTED)
    return c


# ---------- B08 mutation M1 ----------
def b08():
    c, d = canvas()
    heading(d, 'Mutation M1 · one renamed property in land.tres (Kiran\'s run, 2026-11-17)')
    diff = 'evidence/a7-mutations/M1_diff.txt'
    y = 160
    label(d, 60, y, 'evidence/a7-mutations/M1_diff.txt', 40, MUTED)
    y = code_line(c, d, 60, y + 60, 3080, quote(diff, '-tracks/1/path = NodePath("FacingPivot/LandRig/UpperPivot:position")'), None, 46)
    y = code_line(c, d, 60, y + 8, 3080, quote(diff, '+tracks/1/path = NodePath("FacingPivot/LandRig/UpperPivot:positon")'), None, 46, True)
    y += 50
    fl = 'evidence/a7-mutations/fail_lines.txt'
    label(d, 60, y, 'Land read-back on the mutated worktree · evidence/a7-mutations/fail_lines.txt (M1)', 40, MUTED)
    y += 60
    for s in ('  track problem: land track 1: UpperPivot has no property positon',
              'FAIL every track of every clip resolves (track_problems): 1 problems over clips ["land", "scoot"]',
              'FAIL FacingPivot/LandRig/UpperPivot:position present for key checks: missing'):
        y = code_line(c, d, 60, y, 3080, quote(fl, s), None, 40) + 6
    y += 40
    m1 = log_line('evidence/a7-mutations/M1_test_a7_land_readback_60fps.log', 'A7 LAND READBACK:')
    ok = log_line('logs/test_a7_land_readback_60fps.log', 'A7 LAND READBACK:')
    label(d, 60, y, 'Mutated:', 54, ACCENT, SERIF)
    label(d, 380, y + 6, m1 + '  · wrapper exit 1 · Godot imported it with exit 0', 46, INK, MONO)
    label(d, 60, y + 90, 'Committed:', 54, ACCENT, SERIF)
    label(d, 380, y + 96, ok + '  · logs/test_a7_land_readback_60fps.log', 46, INK, MONO)
    return c


# ---------- B09 one authority ----------
def b09():
    c, d = canvas()
    rel = 'CLAUDE.md'
    heading(d, 'CLAUDE.md, “One authority” · lines 69–78')
    label(d, 60, 130, quote(rel, 'Exactly one writer per animated node and property.') + '  (line 67)', 46, INK)
    y = 220
    for n in range(71, 79):
        cells = [x.strip().replace('`', '') for x in line_of(rel, n).strip('|').split('|')]
        node, who = cells[0], cells[1]
        hl = n in (71, 72)
        if len(who) > 70:
            who = who.split(';')[0] + ' (…)'
        d.rectangle([60, y, 3140, y + 98], fill=(244, 235, 226) if hl else CREAM, outline=LINE, width=2)
        label(d, 80, y + 24, f'{n}', 40, MUTED, MONO)
        label(d, 190, y + 22, node, 44, INK, MONO)
        label(d, 1700, y + 22, who, 44, ACCENT if hl else INK)
        y += 104
    label(d, 60, y + 20, 'Highlighted: the frame and the rig transforms, written only by the AnimationPlayer. '
          'Line 75 is shortened here (…); line 78 is read verbatim.', 38, MUTED)
    return c


# ---------- B15 two clocks ----------
def b15():
    c, d = canvas()
    heading(d, 'Two clocks: the clips and gameplay both tick on physics')
    y = code_line(c, d, 60, 140, 1500, line_of('godot/features/player/player_visuals.tscn', 66), 66, 44, True)
    label(d, 60, y + 10, 'player_visuals.tscn · 0 = ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS', 36, MUTED)
    y2 = code_line(c, d, 1640, 140, 1500, line_of('godot/features/player/player.gd', 94), 94, 44)
    label(d, 1640, y2 + 10, 'player.gd · gameplay: tick, land_ticks, just_landed, pose', 36, MUTED)
    y = y + 110
    tr = 'TEST-REPORT.md'
    label(d, 60, y, '74fe4b5 · state test 132 checks / 5 failures · lines quoted in TEST-REPORT.md (A7, “The 132/5 failure”)', 40, ACCENT)
    y += 60
    for s in ('tick=8100 pose=SCOOT-A ptick=61     exp_t=0.083333333333 pos=0.100000000000 diff_ticks=1.000000 cell=0',
              'tick=8101 pose=SCOOT-A ptick=62     exp_t=0.100000000000 pos=0.116666666667 diff_ticks=1.000000 cell=1   <- B shown during A'):
        y = code_line(c, d, 60, y, 3080, quote(tr, s), None, 38, True) + 6
    y += 20
    label(d, 60, y, 'fd4d855 · cause: play() on an AnimationPlayer already playing a clip gets +1/60 s from its own update that tick', 40, INK)
    y += 60
    label(d, 60, y, '5c0fb9a · fix on the direct LAND → SCOOT switch only (Revision 2) · state test 132 / 0 at 30, 60 and 144', 40, INK)
    y += 80
    rel = 'logs/test_a7_visual_state_60fps.log'
    label(d, 60, y, f'Now · {rel}, lines 4468–4469 (selected fields, verbatim)', 40, ACCENT)
    y += 60
    for n in (4468, 4469):
        full = line_of(rel, n)
        keep = [t for t in full.split() if t.split('=')[0] in ('tick', 'pose', 'ptick', 'exp_t', 'pos', 'diff_ticks', 'cell')]
        y = code_line(c, d, 60, y, 3080, '  '.join(keep), n, 38) + 6
    return c


# ---------- B18 phase table beside key times ----------
def b18():
    c, d = canvas()
    brief, land = 'CHANGE-BRIEF.md', 'godot/animations/land.tres'
    heading(d, 'The phase table (CHANGE-BRIEF.md lines 33–37) beside the key times built from it')
    y = 150
    for n, ph in ((35, 'startup'), (36, 'active'), (37, 'recovery')):
        cells = [x.strip().replace('`', '') for x in line_of(brief, n).strip('|').split('|')]
        d.rectangle([60, y, 1500, y + 150], fill=CREAM, outline=PHASE[ph], width=5)
        label(d, 90, y + 18, f'line {n} · {cells[0]} · frames {cells[1]}', 46, PHASE[ph], SERIF)
        wrap(d, 90, y + 80, cells[2], 1380, 34, INK)
        y += 172
    label(d, 60, y + 10, 'Quoted cells: phase, frames at 60 fps, what the player may do.', 34, MUTED)
    # Timeline diagram
    x0, xt, ty = 1640, 3100, 250
    step = (xt - x0) / 8
    label(d, x0, 140, 'Diagram drawn from the files (not a capture): ticks 0–8 at 60 fps', 38, MUTED)
    for t in range(8):
        ph = 'startup' if t < 2 else ('active' if t < 4 else 'recovery')
        d.rectangle([x0 + t * step + 4, ty, x0 + (t + 1) * step - 4, ty + 120], fill=PHASE[ph])
        label(d, x0 + t * step + step / 2 - 12, ty + 36, str(t), 46, CREAM)
    label(d, x0 + 8 * step - 30, ty + 140, '8', 46, INK)
    times = line_of(land, 15)
    vals = line_of(land, 18)
    m = re.search(r'PackedFloat32Array\(([^)]*)\)', times).group(1).split(', ')
    for tk in m:
        fr = round(float(tk) * 60)
        x = x0 + fr * step
        d.line([x, ty - 30, x, ty + 130], fill=INK, width=8)
        d.ellipse([x - 16, ty - 52, x + 16, ty - 20], fill=INK)
    label(d, x0, ty + 210, 'Keys (●) at 0, 2/60, 4/60, 8/60 s → frames 0, 2, 4, 8', 40, INK)
    wrap(d, x0, ty + 280, 'Frames 2 and 4 hold identical values: the squash is held across ticks 2–4. Transitions 2.0 ease in, '
         '1.0 hold, 0.5 ease out (CHANGE-BRIEF.md lines 55–57).', 1460, 36, INK)
    y = 720
    label(d, 60, y, 'godot/animations/land.tres lines 15, 16 and 18 (track 0, LowerPivot:scale) · Revision 3 changed 0.60 → 0.55 '
          'at frames 2 and 4 (CHANGE-BRIEF.md lines 204–205)', 36, MUTED)
    y = code_line(c, d, 60, y + 56, 3080, times.strip(), 15, 40)
    y = code_line(c, d, 60, y + 6, 3080, line_of(land, 16).strip(), 16, 40)
    y = code_line(c, d, 60, y + 6, 3080, vals.strip(), 18, 40, True)
    quote(brief, 'Lower height scale 0.60 → 0.55 at the keys at 2/60 and 4/60 s.')
    return c


STRIP_NAMES = [('trig-1_FALL', 'trigger − 1 · FALL', None), ('trig+0_rig0_impact', 'rig 0 · impact', 'startup'),
               ('trig+1_rig2_deepest-squash', 'rig 2 · deepest squash', 'active'),
               ('trig+2_rig4_same-squash', 'rig 4 · same squash', 'recovery'),
               ('trig+3_rig6_eased-rise', 'rig 6 · eased rise', 'recovery'),
               ('trig+4_tick8_IDLE-handoff', 'tick 8 · IDLE hand-off', None)]


def strip_files(r):
    base = f'captures/land/{r}/clean/'
    start = 104 if r == 'r0' else 145
    return [f'{base}land_clean_{k}_png{start + i:08d}.png' for i, (k, _, _) in enumerate(STRIP_NAMES)]


# ---------- B20 strips r0 and r1 ----------
def b20():
    c, d = canvas()
    heading(d, 'Land strips r0 and r1 at each phase boundary · fixture (land_preview, Movie Maker, 30 fps)')
    label(d, 1840, 124, 'bar = phase:', 34, INK)
    for i, ph in enumerate(('startup', 'active', 'recovery')):
        x = 2110 + i * 340
        d.rectangle([x, 128, x + 40, 168], fill=PHASE[ph])
        label(d, x + 54, 124, ph, 34, INK)
    y = 140
    for r, note in (('r0', 'r0 · lower height 0.60 at frames 2 and 4'), ('r1', 'r1 · lower height 0.55 (Revision 3)')):
        label(d, 60, y, note, 42, ACCENT, SERIF)
        x = 60
        for f, (_, name, ph) in zip(strip_files(r), STRIP_NAMES):
            im = fit(strip_frame(f), 470, 340)
            framed(c, im, x, y + 60)
            if ph:
                d.rectangle([x, y + 60 + im.height + 8, x + im.width, y + 60 + im.height + 20], fill=PHASE[ph])
            if r == 'r1':
                label(d, x, y + 60 + im.height + 26, name, 36, INK)
            x += im.width + 30
        y += 60 + im.height + (100 if r == 'r1' else 40)
    tu = 'TUNING.md'
    s1 = quote(tu, 'The landing looked smooth at normal speed.')
    s2 = quote(tu, 'The hold was easier to see frame by frame.')
    wrap(d, 60, y, f'Kiran\'s r0 verdict, written before any Claude reading: “Impact, hold, and rise: Yes. {s1} … {s2}”', 3080, 40, INK)
    label(d, 60, 1190, 'Frames 104–109 (r0) and 145–150 (r1), from captures/land/r0, r1/clean · crops of the 1280 × 720 frames, enlarged 3.6×',
          32, MUTED)
    quote(tu, '**Impact, hold, and rise:** Yes.')
    return c


# ---------- B21 the r1 reading ----------
def b21():
    c, d = canvas()
    tu = 'TUNING.md'
    heading(d, 'r1 at rig frames 2 and 4: Claude\'s reading and Kiran\'s verdict · fixture')
    x = 60
    f0, f1 = strip_files('r0'), strip_files('r1')
    for idx, nm in ((2, 'rig 2'), (3, 'rig 4')):
        for r, files in (('r0', f0), ('r1', f1)):
            im = fit(strip_frame(files[idx], STRIP_CROP, 5.0), 360, 300)
            framed(c, im, x, 150)
            label(d, x, 150 + im.height + 10, f'{nm} · {r}', 38, MUTED)
            x += im.width + 26
        x += 40
    tx = 1700
    y = 150
    label(d, tx, y, 'Claude\'s prediction (before the r1 capture)', 42, ACCENT, SERIF)
    y = wrap(d, tx, y + 64, '“' + quote(tu, 'The **deepest height is about 43 game px** (r0: about 44)').replace('**', '') +
             '” · “' + quote(tu, 'the r1 strip will look almost the same as r0') + '”', 1440, 36) + 20
    label(d, tx, y, 'Kiran\'s verdict (written first)', 42, ACCENT, SERIF)
    y = wrap(d, tx, y + 64, '“' + quote(tu, 'The difference was easier to see in Preview, especially at rig frames 2 and 4.') +
             ' ' + quote(tu, 'Jelly looks slightly flatter in r1 and holds that shape across both frames.') + '” Kept: r1.', 1440, 36) + 20
    label(d, tx, y, 'Claude\'s comparison (afterwards)', 42, ACCENT, SERIF)
    y = wrap(d, tx, y + 64, '“' + quote(tu, 'The top edge looks at most about 1 px lower than in r0. That is inside my ±2 px estimate error, '
                                        'so I cannot confirm the 1.007 px difference from these stills.') + '”', 1440, 36)
    y0 = 150 + 300 + 110
    wrap(d, 60, y0, 'Kiran\'s reading had a tool Claude\'s did not: Preview. Claude read the 1280 × 720 frames unzoomed. '
         'The stills here are crops of the committed frames, enlarged 5×; they are shown for orientation, not as a measurement.',
         1560, 38, MUTED)
    quote(tu, 'his reading had a tool I did not use here')
    return c


# ---------- B22 tests ----------
def b22():
    c, d = canvas()
    heading(d, 'What the tests proved · logs of the committed runs (headless · numbers only, not a render)')
    rows = [('Read-back · land', 'logs/test_a7_land_readback_60fps.log', 'A7 LAND READBACK:'),
            ('Read-back · scoot', 'logs/test_a7_scoot_readback_60fps.log', 'A7 SCOOT READBACK:'),
            ('Structure', 'logs/test_a7_visual_structure_60fps.log', 'A7 VISUAL STRUCTURE: 29'),
            ('State · 30 fps', 'logs/test_a7_visual_state_30fps.log', 'A7 VISUAL STATE: 132'),
            ('State · 60 fps', 'logs/test_a7_visual_state_60fps.log', 'A7 VISUAL STATE: 132'),
            ('State · 144 fps', 'logs/test_a7_visual_state_144fps.log', 'A7 VISUAL STATE: 132'),
            ('Edges · 30 fps', 'logs/test_a7_edges_30fps.log', 'A7 EDGES: 397'),
            ('Edges · 60 fps', 'logs/test_a7_edges_60fps.log', 'A7 EDGES: 397'),
            ('Edges · 144 fps', 'logs/test_a7_edges_144fps.log', 'A7 EDGES: 397')]
    y = 150
    for name, rel, start in rows:
        label(d, 60, y + 10, name, 44, ACCENT, SERIF)
        code_line(c, d, 560, y, 1500, log_line(rel, start), None, 38)
        label(d, 2100, y + 18, rel.replace('logs/', ''), 32, MUTED)
        y += 92
    y += 10
    k = log_line('logs/test_a7_scoot_readback_60fps.log', 'KEYTIME')
    label(d, 60, y + 6, 'float32 key', 44, ACCENT, SERIF)
    code_line(c, d, 560, y, 2580, k, None, 36)
    return c


# ---------- B23 mutations ----------
def b23():
    c, d = canvas()
    rel = 'evidence/a7-mutations/summary.txt'
    heading(d, 'Four mutations · evidence/a7-mutations/summary.txt (Kiran\'s run of mutations.sh at 167f3ab)')
    rows = [l.split('\t') for l in text_of(rel).splitlines() if re.match(r'M\d\t', l)]
    what = {'M1': 'track subname “positon” in land.tres', 'M2': 'SCOOT looping disabled in scoot.tres',
            'M3': 'a key on cell 2 in scoot.tres', 'M4': 'no change · empty import cache'}
    y = 150
    for r in rows:
        name, file, _, imp, test, _, actual, _, summ, verdict = r[:10]
        d.rectangle([60, y, 3140, y + 220], fill=CREAM, outline=LINE, width=3)
        label(d, 90, y + 20, name, 64, ACCENT, SERIF)
        label(d, 260, y + 30, what[name], 46, INK)
        label(d, 2300, y + 30, verdict, 46, ACCENT if verdict == 'CONFIRMED' else (80, 120, 90), SERIF)
        label(d, 260, y + 100, f'import exit {imp} · {test} · exit {actual}', 36, MUTED)
        summ = summ if len(summ) < 110 else summ.replace(' | ', '  ·  ')
        label(d, 260, y + 150, summ, 36, INK, MONO)
        y += 240
    return c


FIGS = {'B02': (b02, 'identify'), 'B04': (b04, 'sheet'), 'B06': (b06, 'scoot-strip'), 'B08': (b08, 'mutation-m1'),
        'B09': (b09, 'one-authority'), 'B15': (b15, 'two-clocks'), 'B18': (b18, 'phase-table'),
        'B20': (b20, 'land-strips'), 'B21': (b21, 'r1-reading'), 'B22': (b22, 'tests'), 'B23': (b23, 'mutations')}


def main():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    out = REEL / 'images'
    out.mkdir(exist_ok=True)
    sums = []
    for bid, (fn, name) in FIGS.items():
        im = fn(clips) if bid == 'B02' else fn()
        p = out / f'{bid}-{name}.png'
        im.save(p)
        sums.append(f'{sha(p)}  {p.name}')
        print(p.name)
    (out / 'images.sha256').write_text('\n'.join(sums) + '\n')
    (out / 'inputs.sha256').write_text(''.join(f'{v}  {k}\n' for k, v in sorted(USED.items())))
    print(f'{len(USED)} repository inputs matched their committed copies at {REV}')


if __name__ == '__main__':
    main()
