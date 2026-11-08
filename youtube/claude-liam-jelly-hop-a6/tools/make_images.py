"""Builds the A6 film's figures from Kiran's committed evidence and the film's own capture.

    python3 tools/make_images.py      (after tools/make_clips.py)

Written by Claude Code, 2026-11-08, after the A5 film's make_images.py. Inputs are read from the read-only snapshot
(git archive of 8004dea) and each one is compared byte for byte with `git show 8004dea:<path>` from Kiran's
repository (a read-only git command) before use; a mismatch stops the script. Captures are cropped and scaled, never
retouched. Quoted text is checked verbatim against its file; log lines are copied whole from the logs. Held frames from
the film's own scripted capture come from _work/held (hashes in media/clips.json).
Output: images/*.png and images/images.sha256, images/inputs.sha256.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
SNAP = REEL.parent / 'snapshot-8004dea'
REPO = Path('/Users/kiran/Documents/walker-jellyhop-kiran-g')
REV = '8004dea'
W, H = 3200, 1250
CREAM, INK, ACCENT, MUTED, LINE = (250, 249, 245), (61, 57, 41), (152, 80, 57), (100, 90, 76), (207, 198, 181)
CODEBG, CODEFG = (38, 42, 54), (232, 230, 222)
SERIF = str(Path.home() / 'Library/Fonts/EBGaramond-Medium.ttf')
SANS = '/System/Library/Fonts/SFNS.ttf'
MONO = '/System/Library/Fonts/SFNSMono.ttf'
PUFF_CROP = (150, 438, 530, 532)     # both still jellies and their surfaces in the 1280 x 720 Effect A strip frames
DOME_CROP = (820, 330, 1060, 530)    # the dome and the room above it in the Effect B strip frames
USED = {}


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def repo_file(rel) -> Path:
    p = SNAP / rel
    if not p.is_file():
        sys.exit(f'STOPPED: missing {rel}')
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


def framed(c, im, x, y):
    c.paste(im, (x, y))
    ImageDraw.Draw(c).rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=LINE, width=3)


def label(d, x, y, t, size=46, fill=INK, face=SANS):
    d.text((x, y), t, font=font(face, size), fill=fill)


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


def wrap_chars(d, x, y, t, width, size=40, fill=INK, face=MONO, gap=1.3):
    f = font(face, size)
    line = ''
    for ch in t:
        if f.getlength(line + ch) > width:
            d.text((x, y), line, font=f, fill=fill)
            y += int(size * gap)
            line = ''
        line += ch
    if line:
        d.text((x, y), line, font=f, fill=fill)
        y += int(size * gap)
    return y


def code_line(c, d, x, y, w, text, num=None, size=40):
    """A dark code strip: the line number and the line, verbatim."""
    f = font(MONO, size)
    h = size + 30
    d.rectangle([x, y, x + w, y + h], fill=CODEBG)
    tx = x + 24
    if num is not None:
        d.text((tx, y + 14), f'{num:>3}', font=f, fill=(150, 156, 170))
        tx += int(f.getlength('0000 '))
    d.text((tx, y + 14), text.replace('\t', '    '), font=f, fill=CODEFG)
    if tx + f.getlength(text.replace('\t', '    ')) > x + w:
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


def strip(effect, r, n, crop):
    return img(f'captures/{effect}/{r}/frame{n:08d}.png').crop(crop)


# ---------- B02 identify ----------
def b02(clips):
    c, d = canvas()
    hp, hd = held('held-puff.png', clips), held('held-dome.png', clips)
    tp, td = clips['held']['held-puff.png'], clips['held']['held-dome.png']
    a = fit(hp, 1520, 790)
    framed(c, a, 40, 40)
    b = fit(hd, 1520, 790)
    framed(c, b, 1640, 40)
    y = 40 + a.height + 18
    label(d, 40, y, f'Held frame · the film\'s scripted capture, tick {tp["tick"]} · crop of the 4K frame, enlarged 2×', 40, MUTED)
    label(d, 1640, y, f'Held frame · same capture, tick {td["tick"]} (first frame of the intro) · crop, 2×', 40, MUTED)
    y += 70
    label(d, 40, y, 'Effect A · the landing crumb puff', 58, ACCENT, SERIF)
    label(d, 1640, y, 'Effect B · the dome sugar glints', 58, ACCENT, SERIF)
    y += 90
    wrap(d, 40, y, quote('CHANGE-BRIEF.md', 'if state == State.PLAYING and player.just_landed:') +
         '  (session.gd line 372), the same branch that plays SFX-LAND', 1500, 44)
    wrap(d, 1640, y, 'Job: ambience. Condition: ' + quote('CHANGE-BRIEF.md', 'session.state != State.WON') +
         ' (CHANGE-BRIEF.md, Effect B)', 1500, 44)
    return c


# ---------- B03 three parts ----------
def b03():
    c, d = canvas()
    rows = [('EMISSION', 'when and how many are born', 'godot/effects/land_puff.tscn', 69),
            ('PROCESS', 'how each one moves and changes, every frame', 'godot/shaders/particles_generated.gdshader', 343),
            ('DRAW', 'what each one looks like on screen', 'godot/effects/land_puff.tscn', 65)]
    notes = ['all 16 crumbs are born on the landing frame (amount = 16, line 64)',
             'the force starts with gravity; the radial push and damping follow (lines 349, 360)',
             'each crumb is a 16 × 16 radial GradientTexture2D defined in this file (lines 7–13)']
    y = 50
    for (part, what, rel, n), note in zip(rows, notes):
        label(d, 60, y, part, 76, ACCENT, SERIF)
        label(d, 560, y + 20, what, 54, INK)
        label(d, 2000, y + 26, f'{rel}, line {n}', 42, MUTED)
        y += 110
        y = code_line(c, d, 60, y, 3080, line_of(rel, n), n, 60)
        y += 18
        label(d, 60, y, note, 50, INK)
        y += 160
    return c


# ---------- B04 headless price ----------
def b04():
    c, d = canvas()
    rel = 'logs/cost_effects_60fps_mine_20261108-001211.log'
    label(d, 60, 50, 'Why a low headless CPU cost is expected', 60, ACCENT, SERIF)
    y = code_line(c, d, 60, 150, 1400, line_of('godot/shaders/particles_generated.gdshader', 3), 3, 50)
    y = wrap(d, 60, y + 30, 'The process step of a GPUParticles2D is a particles shader: it runs on the GPU.', 1400, 52)
    y = wrap(d, 60, y + 24, 'A headless run measures CPU time only: the wall time between frames, in ms.', 1400, 52)
    y = wrap(d, 60, y + 24, 'So the effects\' GPU work is not in this number.', 1400, 52)
    label(d, 1600, 50, 'What Kiran measured (5 rounds × 300 frames)', 60, ACCENT, SERIF)
    yy = 160
    for case in ('game_off', 'effect_a_restart', 'effect_a_lifecycle', 'effect_b'):
        full = log_line(rel, f'COST {case:<19}wall')
        short = full.split('|')[0].replace('COST ', '').split(' (sd')[0]
        label(d, 1600, yy, ' '.join(short.split()), 44, INK, MONO)
        yy += 64
    yy += 20
    for case in ('effect_a_restart', 'effect_a_lifecycle', 'effect_b'):
        full = log_line(rel, f'COST compare {case:<19}vs game_off').replace('COST compare ', '')
        name, rest = full.split(':', 1)
        label(d, 1600, yy, name.split()[0] + ' vs game_off', 44, INK, MONO)
        yy = wrap(d, 1600, yy + 56, rest.strip(), 1540, 40, ACCENT, MONO, 1.2) + 22
    y = max(y, yy) + 20
    d.line([60, y, 3140, y], fill=LINE, width=3)
    label(d, 60, y + 24, 'Not distinguishable within spread is not zero cost. The same log reports: '
          + log_line(rel, 'COST rendering driver').replace('COST ', ''), 48, INK)
    label(d, 60, y + 96, 'so it does not settle whether particles were processed on the GPU: the dummy-renderer statement is '
          'still unconfirmed (CLAUDE.md).', 48, INK)
    return c


# ---------- intent blocks ----------
def intent(rows, title_note):
    c, d = canvas()
    label(d, 60, 40, title_note, 40, MUTED)
    y = 120
    for head, rel, q in rows:
        label(d, 60, y, head, 58, ACCENT, SERIF)
        shown = quote(rel, q).replace('**', '').replace('`', '')
        if shown.startswith('Stop: '):
            shown = shown[len('Stop: '):]
        y = wrap(d, 640, y + 6, shown, 2480, 50, INK, SANS, 1.25) + 30
    return c


def b05():
    B = 'CHANGE-BRIEF.md'
    return intent([
        ('Impact (0–2)', B, 'crumbs appear at both edges of the jelly\'s base at full size and full brightness'),
        ('Kick (2–5)', B, 'the crumbs travel fast outward, sideways, reaching roughly one jelly width beyond each side, staying within about 6 px of the surface.'),
        ('Settle (5–12)', B, 'they slow almost to a stop, shrink and fade. All are gone by frame 12 (0.40 s)'),
        ('Contrast', B, 'Value contrast does it, not hue: each crumb has a **light cream core and a dark brown rim**.'),
        ('Scale', B, 'each crumb is about 6–12 px across (one eighth to one quarter of the jelly\'s 52 px width)'),
        ('Over life', B, 'size holds for the first third of life, then shrinks to zero; colour shifts from cream-white toward a warm crumb tan; alpha fades to zero at the end.'),
        ('Layering', B, 'It is drawn **behind the jelly and in front of the plates** (`z_index = -1`; plates are −2, the jelly is 0)'),
    ], 'Quoted from CHANGE-BRIEF.md, Effect A, "The intent block" (Version 1, 2026-11-07) · frames at 30 fps, frame 0 = the landing tick')


def b12():
    B = 'CHANGE-BRIEF.md'
    return intent([
        ('Job', B, 'where the goal is, and that it is the prize. Soft sugar glints rise from the dessert dome for the whole run.'),
        ('Start', B, 'on the first frame after the scene loads, the dome is already glinting at its steady-state density (preprocess). No fill-in.'),
        ('Steady', B, 'about 24 glints alive.'),
        ('Stop', B, '**Stop:** at `WON`, no new glints are born; the ones alive keep rising and fade out naturally.'),
        ('Scale', B, 'each glint is about 4–9 px across, smaller than the landing crumbs'),
        ('Contrast', B, 'the glints rise from the dome\'s glass into the **dark room** behind it (darkest), and the additive glow reads strongly there.'),
        ('Over life', B, 'size grows from zero over the first fifth of life and shrinks to zero over the last fifth; alpha fades in and out with it; colour shifts from sugar white to pale gold.'),
        ('Layering', B, 'Drawn in front of the dome glass (`z_index = 6`; the dome is 5).'),
        ('Not in A', B, "a **box emission shape** (`EMISSION_SHAPE_BOX`) across the dome's glass. Effect B also uses `preprocess` and an additive `CanvasItemMaterial`"),
    ], 'Quoted from CHANGE-BRIEF.md, Effect B (Version 1) · Revision 2 later moved the fade-in to 8 % of life (shown later in this film)')


# ---------- strips ----------
def grid(c, d, effect, cells, crop, x, y, cw, ch, gapx=30, gapy=74, cols=2, cap=40):
    """cells: list of (r, frame). Each crop is fitted into cw x ch, captioned below."""
    for i, (r, f) in enumerate(cells):
        im = fit(strip(effect, r, f, crop), cw, ch)
        cx, cy = x + (i % cols) * (cw + gapx), y + (i // cols) * (ch + gapy)
        framed(c, im, cx, cy)
        label(d, cx, cy + im.height + 10, f'{r} · frame {f}', cap, MUTED)
    rows = (len(cells) + cols - 1) // cols
    return y + rows * (ch + gapy)


def b07():
    c, d = canvas()
    label(d, 60, 24, 'Fixture capture: land_puff_preview.tscn, Movie Maker 30 fps, fixed seeds on the preview only · '
          'captures/land_puff/r0/ · crops of the 1280 × 720 frames, enlarged', 40, MUTED)
    y = grid(c, d, 'land_puff', [('r0', 10), ('r0', 12), ('r0', 15), ('r0', 20)], PUFF_CROP, 60, 100, 1525, 377)
    label(d, 60, y, 'Kiran\'s r0 verdict (TUNING.md), before Claude read anything:', 46, ACCENT)
    wrap(d, 60, y + 66, '"' + quote('TUNING.md', 'At frame 12, it was easy to see on both the pale plate and the dark table. '
                                    'At frame 15, most of the crumbs were still under the jellies, so I didn\'t see the wide '
                                    'sideways fan I expected. The crumbs were gone by frame 20 and stayed gone in frames 30 and 50.') + '"',
         3080, 50, INK, SERIF, 1.22)
    return c


def three_cols(d, y, cols, size=42):
    x = 60
    for head, body in cols:
        label(d, x, y, head, 46, ACCENT)
        wrap(d, x, y + 66, body, 990, size, INK, SANS, 1.25)
        x += 1045


def b09():
    c, d = canvas()
    label(d, 60, 24, 'Fixture captures r0 (top) and r1 (bottom) · same preview, seeds 1001 and 1002 · captures/land_puff/ · '
          'crops, enlarged', 40, MUTED)
    y = grid(c, d, 'land_puff', [('r0', 12), ('r0', 15), ('r1', 12), ('r1', 15)], PUFF_CROP, 60, 96, 1525, 300, gapy=66)
    three_cols(d, y + 6, [
        ('Claude\'s prediction (session 4b)',
         quote('TUNING.md', 'frame 12 crumbs still mostly behind the jelly, no crumb centre clearing the visible edge')
         + '; frame 15 ' + quote('TUNING.md', 'mostly by 5–35 px, at most about 40 px')),
        ('Claude\'s comparison (session 4d)',
         quote('TUNING.md', 'Frame 12 does **not** match: crumbs show about 5–15 px past both edges of both jellies').replace('**', '')
         + '; frame 15: ' + quote('TUNING.md', 'about 36–49 px beyond the visible edges')
         + '. Cause: ' + quote('TUNING.md', 'its model was one frame off')),
        ('Kiran\'s verdict (running game, 1280 × 720)',
         'Kept, ' + quote('TUNING.md', 'because the puff was easy to see when the jelly landed in the running game'))])
    return c


def b14():
    c, d = canvas()
    label(d, 60, 24, 'Fixture capture: dome_glints_preview.tscn · restart() at frame 10, emitting = false at 70 · seed 2001 · '
          'captures/dome_glints/r0/ · crops, enlarged', 40, MUTED)
    grid(c, d, 'dome_glints', [('r0', f) for f in (10, 12, 40, 70, 85, 145)], DOME_CROP, 60, 100, 528, 440, cols=3)
    label(d, 1780, 110, 'Kiran\'s r0 verdict (TUNING.md):', 50, ACCENT)
    wrap(d, 1780, 190, '"' + quote('TUNING.md', 'The glints were already visible around the dome at frame 10, and I saw more of '
                                   'them there than at frame 40. I didn\'t notice them thinning out by frame 85. By frame 145, '
                                   'no glints were visible.') + '"', 1360, 54, INK, SERIF, 1.25)
    return c


def b16():
    c, d = canvas()
    label(d, 60, 24, 'Fixture captures r0 (top) and r1 (bottom) · seed 2001 · captures/dome_glints/ · crops, enlarged', 40, MUTED)
    grid(c, d, 'dome_glints', [('r0', 10), ('r0', 40), ('r0', 85), ('r1', 10), ('r1', 40), ('r1', 85)], DOME_CROP,
         60, 96, 480, 400, gapx=24, gapy=74, cols=3)
    y = 96
    for head, body in (
            ('Kiran\'s byte comparison (cmp)', quote('TUNING.md', 'frames 10, 12, 40, 70 and 85 differ between r0 and r1, '
                                                    'and frame 145 is identical')),
            ('Claude\'s prediction (7a) → comparison (7c)', 'frame 10 ' + quote('TUNING.md', 'about 16 to 18 visible')
             + ' → ' + quote('TUNING.md', 'no extra visible dots at 10 or 40 (about 9 at 40)') + '; '
             + quote('TUNING.md', 'it called its count prediction its own mistake')),
            ('Kiran overruled the reading', quote('TUNING.md', 'at full frame size Claude saw no visible difference between r0 and r1, '
                                                   'while in the running game I found the glints noticeably easier to see in the intro')
             + '. Kept.')):
        label(d, 1640, y, head, 46, ACCENT)
        y = wrap(d, 1640, y + 64, body, 1500, 42, INK, SANS, 1.25) + 34
    return c


# ---------- B19 start / stop / pause ----------
def b19(clips):
    c, d = canvas()
    rows = [('On from load', 'headless B1: emitting true from load, through the intro', 'capture: glinting on tick 1'),
            ('Stops on WON', 'headless B2: false on the WON tick, 2 real-key runs', 'capture: false on tick 1233; Kiran saw them fade'),
            ('Restarts on replay', 'headless B3: true on the first tick after each replay', 'in play: NOT verified (dome off screen)'),
            ('Esc pause', 'headless B4: emitting and processing for 60 PAUSED ticks', 'Kiran in play, and this capture: they keep drifting'),
            ('Tree pause', 'headless B5: emitting stays true; does not process', 'headless only'),
            ('Hidden', 'headless B6: visible false 60 ticks, emitting stays true', 'headless (Kiran also toggled Visible in play)'),
            ('One emitter', 'headless B7: the same object across both replays', 'headless only')]
    label(d, 60, 24, 'Sources: TEST-REPORT.md A6, "State — Effect B" (27 checks / 0) and "In play — Effect B" · the film\'s capture log',
          40, MUTED)
    y = 100
    for a, b, e in rows:
        label(d, 60, y, a, 52, ACCENT, SERIF)
        label(d, 560, y + 8, b, 42, INK)
        label(d, 1900, y + 8, e, 42, INK)
        y += 100
        d.line([60, y - 18, 3140, y - 18], fill=LINE, width=2)
    p = fit(held('held-pause.png', clips), 1400, 380)
    framed(c, p, 60, y + 10)
    w_ = fit(held('held-won.png', clips), 1400, 380)
    framed(c, w_, 1640, y + 10)
    label(d, 60 + p.width + 24, y + 20, 'Held frame,', 40, MUTED)
    label(d, 60 + p.width + 24, y + 70, f'tick {clips["held"]["held-pause.png"]["tick"]}:', 40, MUTED)
    label(d, 60 + p.width + 24, y + 120, 'Esc pause,', 40, MUTED)
    label(d, 60 + p.width + 24, y + 170, 'full frame', 40, MUTED)
    label(d, 1640 + w_.width + 24, y + 20, 'Held frame,', 40, MUTED)
    label(d, 1640 + w_.width + 24, y + 70, f'tick {clips["held"]["held-won.png"]["tick"]}:', 40, MUTED)
    label(d, 1640 + w_.width + 24, y + 120, 'WON, crop 2×', 40, MUTED)
    return c


# ---------- B20 generated shader lines ----------
def b20():
    c, d = canvas()
    S = 'godot/shaders/particles_generated.gdshader'
    P = 'godot/effects/land_puff.tscn'
    label(d, 60, 30, 'Lines read from the files at 8004dea · particles_generated.gdshader: Godot\'s Convert to ShaderMaterial '
          'output, saved unedited, not used by the game', 40, MUTED)
    y = 110
    label(d, 60, y, 'Line 145 · initial velocity', 56, ACCENT, SERIF)
    y = code_line(c, d, 60, y + 86, 3080, line_of(S, 145).strip(), 145, 38) + 20
    label(d, 60, y, 'picks a speed between the minimum and the maximum, with a seeded random value · from the brief:', 42, INK)
    y += 70
    for n in (45, 46):
        y = code_line(c, d, 60, y, 1300, line_of(P, n), n, 40) + 6
    y += 60
    label(d, 60, y, 'Line 254 · the radial curve', 56, ACCENT, SERIF)
    y = code_line(c, d, 60, y + 90, 3080, line_of(S, 254).strip(), 254, 40) + 20
    label(d, 60, y, 'samples the curve at the particle\'s lifetime percentage and scales the radial push · Revision 1:', 42, INK)
    y += 70
    y = code_line(c, d, 60, y, 3080, line_of(P, 16), 16, 40) + 10
    label(d, 60, y, 'points (0, 1), (0.18, 1), (0.2, 0): full push until 18 % of life, none from 20 % (CHANGE-BRIEF.md, Revision 1)',
          40, MUTED)
    return c


# ---------- B21 tests ----------
def b21():
    c, d = canvas()
    logs = [('logs/test_land_puff_config_60fps.log', 'LAND PUFF CONFIG:', 'reads every land_puff.tscn setting back against the brief'),
            ('logs/test_dome_glints_config_60fps.log', 'DOME GLINTS CONFIG:', 'reads every dome_glints.tscn setting back, the box included'),
            ('logs/test_land_puff_state_60fps.log', 'LAND PUFF STATE TESTS:', 'real main.tscn, key events only: A1–A8'),
            ('logs/test_dome_glints_state_60fps.log', 'DOME GLINTS STATE TESTS:', 'two real-key runs to the dome, two replays: B1–B7')]
    label(d, 60, 24, 'Logs of Kiran\'s runs through scripts/run-test.sh at 60 fps (fixed rate) · each exited 0 · TEST-REPORT.md A6',
          40, MUTED)
    y = 110
    for rel, head, note in logs:
        y = code_line(c, d, 60, y, 1560, log_line(rel, head), None, 48) + 10
        label(d, 80, y, note, 42, MUTED)
        y += 98
    rows = [quote('TEST-REPORT.md', 'puff ticks = `SFX-LAND` ticks = 116, 263, 273, 372, 543, 687').replace('`', ''),
            'A3: ' + quote('TEST-REPORT.md', 'every puff at the jelly\'s feet: maximum distance 0.0 px'),
            'A4: ' + quote('TEST-REPORT.md', 'two landings **10 ticks (0.167 s)** apart').replace('**', '') + ', two separate instances',
            'A5: ' + quote('TEST-REPORT.md', '**peak of 2 puffs alive at once on the tested route**').replace('**', ''),
            'B1–B3: ' + quote('TEST-REPORT.md', '`emitting == (state != WON)` on all 1,667 ticks').replace('`', ''),
            'B7: ' + quote('TEST-REPORT.md', '**the same emitter object** across both replays').replace('**', ''),
            'A2 at WON: ' + quote('TEST-REPORT.md', 'no landing puff on the tick each run entered WON')]
    label(d, 1720, 100, 'What the state tests observed', 58, ACCENT, SERIF)
    yy = 200
    for r in rows:
        yy = wrap(d, 1720, yy, r, 1420, 44, INK, SANS, 1.22) + 22
    return c


# ---------- B22 mutations ----------
def b22():
    c, d = canvas()
    m1, m2 = 'logs/mutation1_godot3_name_config_60fps.log', 'logs/mutation2_value_drift_config_60fps.log'
    label(d, 60, 24, 'Logs of Kiran\'s runs · each a one-line edit to land_puff.tscn, restored with git checkout · TEST-REPORT.md A6',
          40, MUTED)
    for x, rel, head, edit, note in (
            (60, m1, 'Mutation 1 · a Godot 3 name', 'initial_velocity_min = 30.0  →  initial_velocity = 30.0',
             'Godot printed no error or warning, and the puff still appeared in the preview.'),
            (1640, m2, 'Mutation 2 · value drift', 'spread = 30.0  →  spread = 45.0, while the brief still says 30.0',
             'Exactly one failure: the test catches drift between the brief and the scene.')):
        label(d, x, 100, head, 64, ACCENT, SERIF)
        y = wrap(d, x, 210, edit, 1500, 44, INK, MONO)
        y = code_line(c, d, x, y + 30, 1500, log_line(rel, 'LAND PUFF CONFIG:'), None, 48) + 24
        if text_of(rel).count('"FAIL"') != 1:
            sys.exit('STOPPED: expected exactly one FAIL in ' + rel)
        failing = [l for l in text_of(rel).splitlines() if '"FAIL"' in l][0]
        y = wrap_chars(d, x, y, failing, 1500, 42, ACCENT) + 30
        wrap(d, x, y, note, 1500, 50, INK)
    d.line([60, 1010, 3140, 1010], fill=LINE, width=3)
    wrap(d, 60, 1050, 'After each restore: 51 checks / 0 failures, exit 0. A firing puff was not evidence that its settings '
         'had loaded (FRICTIONAL.md A6).', 3080, 52, INK)
    return c


# ---------- B23 prices ----------
def b23():
    c, d = canvas()
    a = img('evidence/a6-visual-profiler-compat-gpu-zero.png')
    b = img('evidence/a6-visual-profiler-forwardplus-proxy-gpu-zero.png').crop((580, 840, 2445, 1760))
    ia, ib = fit(a, 1200, 780), fit(b, 1580, 780)
    framed(c, ia, 60, 40)
    framed(c, ib, 3140 - ib.width, 40)
    label(d, 60, 40 + ia.height + 14, 'Kiran\'s screenshot · Compatibility, the shipped renderer', 40, MUTED)
    label(d, 3140 - ib.width, 40 + ib.height + 14, 'Kiran\'s screenshot, cropped · Forward+ by command-line override:', 40, MUTED)
    label(d, 3140 - ib.width, 40 + ib.height + 60, 'a labelled comparison only, not the shipped renderer', 40, MUTED)
    y = 40 + max(ia.height, ib.height) + 140
    for head, body in (('GPU', 'every GPU reading 0.0 ms and the graph blank, on both: timing unavailable, so the '
                        '0.25 ms budgets are unverified'),
                       ('Headless CPU', 'no effect case distinguishable from the effects-off baseline: unresolved')):
        label(d, 60, y, head, 58, ACCENT, SERIF)
        y = wrap(d, 560, y + 6, body, 2580, 50, INK) + 26
    return c


FIGS = {'B02': b02, 'B03': b03, 'B04': b04, 'B05': b05, 'B07': b07, 'B09': b09, 'B12': b12, 'B14': b14,
        'B16': b16, 'B19': b19, 'B20': b20, 'B21': b21, 'B22': b22, 'B23': b23}
NAMES = {'B02': 'identify', 'B03': 'three-parts', 'B04': 'headless-price', 'B05': 'intent-a', 'B07': 'strip-a-r0',
         'B09': 'revision-a-r1', 'B12': 'intent-b', 'B14': 'strip-b-r0', 'B16': 'revision-b-r1', 'B19': 'start-stop-pause',
         'B20': 'generated-lines', 'B21': 'tests', 'B22': 'mutations', 'B23': 'prices'}


def main():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    out = REEL / 'images'
    out.mkdir(exist_ok=True)
    sums = []
    for bid, fn in FIGS.items():
        im = fn(clips) if bid in ('B02', 'B19') else fn()
        p = out / f'{bid}-{NAMES[bid]}.png'
        im.save(p)
        sums.append(f'{sha(p)}  {p.name}')
        print(p.name)
    (out / 'images.sha256').write_text('\n'.join(sums) + '\n')
    (out / 'inputs.sha256').write_text(''.join(f'{v}  {k}\n' for k, v in sorted(USED.items())))
    print(f'{len(USED)} repository inputs matched their committed copies at {REV}')


if __name__ == '__main__':
    main()
