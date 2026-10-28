"""Builds the A5 film's figures from Kiran's committed evidence, logs and source files.

    python3 tools/make_images.py CAPTURE_WORK_DIR      (after tools/make_clips.py)

Written by Claude Code, 2026-10-28. Every repository input is compared byte for byte with its committed copy at
revision 77a6d10 (git show) before use; a mismatch stops the script. Captures are cropped and scaled, never
retouched; the only marks added are labelled rings on the sampled pixels. Every measured number is parsed from
the committed capture JSON or log; predictions are the ones Kiran wrote (CHANGE-BRIEF.md §6, §8, Revision 5).
Text quoted from CHANGE-BRIEF.md, LANGUAGE-NOTES.md and the shaders is read from the files and checked verbatim.
Held frames from the film's own scripted capture come from CAPTURE_WORK_DIR/held (hashes in media/clips.json).
Output: images/*.png and images/images.sha256.
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
REPO = REEL.parent.parent
REV = '77a6d10'
W, H = 3200, 1400
CREAM, INK, ACCENT, MUTED, LINE = (250, 249, 245), (61, 57, 41), (152, 80, 57), (100, 90, 76), (207, 198, 181)
GREEN, BAD = (48, 61, 52), (152, 40, 30)
SERIF = str(Path.home() / 'Library/Fonts/EBGaramond-Medium.ttf')
SANS = '/System/Library/Fonts/SFNS.ttf'
MONO = '/System/Library/Fonts/SFNSMono.ttf'
CROP_3D = (0, 190, 1280, 570)   # the table, board and A3 assets in the 1280 x 720 material captures
CROP_TIGHT = (40, 330, 880, 570)
CROP_TABLE = (40, 300, 880, 466)   # worn table only, above the serving board (the sweep changes only the table's material)   # board, dome, serving board and table only, drawn larger (GATE T §8.3b)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


USED = {}


def repo_file(rel) -> Path:
    p = REPO / rel
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
        sys.exit(f'STOPPED: quoted text not found verbatim in {rel}: {s[:60]}')
    return s


def font(path, size):
    return ImageFont.truetype(path, size)


def fit(im, bw, bh):
    k = min(bw / im.width, bh / im.height)
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def framed(c, im, x, y):
    c.paste(im, (x, y))
    ImageDraw.Draw(c).rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=LINE, width=3)


def label(d, x, y, t, size=44, fill=INK, face=SANS):
    d.text((x, y), t, font=font(face, size), fill=fill)


def wrap(d, x, y, t, width, size=44, fill=INK, face=SANS, gap=1.3):
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


def canvas():
    c = Image.new('RGB', (W, H), CREAM)
    return c, ImageDraw.Draw(c)


def rgb(v):
    return f'({v[0]}, {v[1]}, {v[2]})'


def log_lines(rel):
    return text_of(rel).splitlines()


def checks(rel):
    return {j['id']: j for j in (json.loads(l) for l in log_lines(rel) if l.startswith('{"id"'))}


# ---------- B02 identify ----------
def b02(work, clips):
    c, d = canvas()
    held = Image.open(work / 'held/held-t455.png').convert('RGB')
    if sha(work / 'held/held-t455.png') != clips['held']['held-t455.png']['sha256']:
        sys.exit('STOPPED: held frame hash mismatch')
    p2 = [f for f in clips['held']['held-t455.png']['forks'] if f[0] == 2][0]
    s = fit(held.crop((0, 0, 3840, 1560)), 1540, 870)   # above the curtain (GATE T §8.3b read its folds as text)
    framed(c, s, 40, 40)
    label(d, 40, 40 + s.height + 16, f'Held frame · the film\'s scripted capture, tick 455, cropped above the curtain · rev {REV}', 36, MUTED)
    label(d, 40, 40 + s.height + 64, f'Plate {p2[0]} fork (left): {p2[1]}, warning {p2[2]:.2f} (from the capture log)', 40, INK)
    t = img('evidence/a5-captures/materials_default.png').crop(CROP_3D)
    s2 = fit(t, 1540, 600)
    framed(c, s2, 1620, 40)
    label(d, 1620, 40 + s2.height + 16, "Scripted in-engine capture (Kiran's run) · materials_default.png", 36, MUTED)
    y = 40 + s2.height + 90
    label(d, 1620, y, 'The 3D object with the textured shader', 50, ACCENT)
    for t_ in ['the A3 Floor as a worn dinner table', 'a polished serving board (front, darker)',
               'both: table_wood.gdshader, Dark Wood textures', 'Compatibility · Sun only, no ambient']:
        y += 76
        label(d, 1620, y, t_, 44)
    label(d, 40, 1300, 'Fork: ENV-FORK.png sprite with fork_warning.gdshader · candle amber #FFB347 · CHANGE-BRIEF.md §1, §7', 38, MUTED)
    return c


# ---------- B03 the spec ----------
def b03():
    c, d = canvas()
    rel = 'CHANGE-BRIEF.md'
    colour = quote(rel, 'COLOR.rgb = mix(COLOR.rgb, warn_color.rgb, warning * strength);')
    label(d, 60, 40, 'CHANGE-BRIEF.md §2, Version 1 (2026-10-27), written before the shader · quoted, typeset (not a screenshot)', 38, MUTED)
    label(d, 60, 120, 'The colour line', 60, ACCENT, SERIF)
    d.rectangle([60, 210, W - 60, 330], fill=(32, 37, 49))
    label(d, 110, 236, colour, 60, (237, 241, 247), MONO)
    y = 380
    label(d, 60, y, 'Uniforms', 60, ACCENT, SERIF)
    rows = [('warning', 'float', 'hint_range(0.0, 1.0)', '0.0', 'the driver, from that fork\'s phase'),
            ('warn_color', 'vec4', 'source_color', '#FFB347', 'nobody at runtime'),
            ('strength', 'float', 'hint_range(0.0, 1.0)', '0.65', 'tuned in the Inspector')]
    for r in rows:
        quote(rel, f'| `{r[0]}` | `{r[1]}` | `{r[2]}` |')
    cols = [60, 520, 820, 1500, 1900]
    y += 100
    for x, h in zip(cols, ['Uniform', 'Type', 'Hint', 'Default', 'Set by']):
        label(d, x, y, h, 42, MUTED)
    for r in rows:
        y += 72
        for k, (x, v) in enumerate(zip(cols, r)):
            label(d, x, y, v, 46, INK, MONO if k < 4 else SANS)
    y += 120
    a = quote(rel, 'Only `.rgb` changes. `COLOR.a` is untouched, so the fork\'s transparent pixels stay transparent and its silhouette never changes.')
    y = wrap(d, 60, y, a.replace('`', ''), W - 120, 46)
    b = quote(rel, 'during SHADOW, `warning` equals the fork\'s own shadow growth, `(p − safe_ticks + 1) / shadow_ticks`')
    wrap(d, 60, y + 20, ('What warning is: ' + b + '; 0.0 in every other phase and whenever the fork is held.').replace('`', ''), W - 120, 46)
    return c


# ---------- B05 controlled values ----------
PRED = {'P1': {'0.00': (179, 183, 184), '0.50': (204, 182, 147), '1.00': (228, 180, 111), '2.00': (255, 178, 37)},
        'P2': {'0.00': (113, 126, 128), '0.50': (159, 143, 109), '1.00': (205, 160, 91), '2.00': (255, 195, 54)}}


def b05():
    c, d = canvas()
    res = json.loads(text_of('evidence/a5-captures/capture-results.json'))['fork']
    if res['plate_index'] != 2:
        sys.exit('STOPPED: unexpected plate in capture-results.json')
    box = (850, 0, 1080, 280)
    x = 60
    for w in ('0.00', '0.50', '1.00', '2.00'):
        im = img(f'evidence/a5-captures/fork_warning_{w}.png')
        cap = res['captures'][w]
        dd = ImageDraw.Draw(im)
        for name in ('P1', 'P2'):
            px, py = cap[name]['at']
            dd.ellipse([px - 7, py - 7, px + 7, py + 7], outline=(255, 255, 255), width=2)
        s = fit(im.crop(box), 640, 760)
        framed(c, s, x, 40)
        label(d, x, 40 + s.height + 12, f'warning = {float(w):.1f}', 46, ACCENT)
        x += 760
    label(d, 60, 900, 'Crops of evidence/a5-captures/fork_warning_*.png · scripted in-engine captures run by Kiran, windowed, Compatibility · plate 2 fork, physics stopped · rings (added) mark P1 (tine) and P2', 32, MUTED)
    cols = [60, 330, 900, 1470, 2040, 2610]
    y = 970
    for xx, h in zip(cols, ['warning', 'P1 measured', 'P1 predicted', 'P2 measured', 'P2 predicted', 'max step']):
        label(d, xx, y, h, 40, MUTED)
    for w in ('0.00', '0.50', '1.00', '2.00'):
        y += 74
        m1, m2 = res['captures'][w]['P1']['rgb'], res['captures'][w]['P2']['rgb']
        step = max(abs(a - b) for m, p in ((m1, PRED['P1'][w]), (m2, PRED['P2'][w])) for a, b in zip(m, p))
        if step > 1:
            sys.exit(f'STOPPED: capture differs from prediction by {step} at {w}')
        for xx, v in zip(cols, [w, rgb(m1), rgb(PRED['P1'][w]), rgb(m2), rgb(PRED['P2'][w]), str(step)]):
            label(d, xx, y, v, 46, INK, MONO)
    return c


# ---------- B09 headless driver test ----------
def b09():
    c, d = canvas()
    label(d, 60, 40, 'Headless · numbers only · test_fork_warning.gd through scripts/run-test.sh · logs/test_fork_warning_*fps.log', 40, MUTED)
    y = 130
    for fps in (30, 60, 144):
        rel = f'logs/test_fork_warning_{fps}fps.log'
        ls = log_lines(rel)
        summary = [l for l in ls if l.startswith('FORK WARNING TESTS:')]
        md5 = [l.split(': ')[-1] for l in ls if l.startswith('FORK WARNING PER-TICK SEQUENCE MD5')]
        if summary != ['FORK WARNING TESTS: 29 checks / 0 failures'] or md5 != ['35385bc4a519009a685ec285b3ba7529']:
            sys.exit(f'STOPPED: unexpected result in {rel}')
        d.rectangle([60, y, W - 60, y + 100], fill=GREEN)
        label(d, 100, y + 26, f'{fps:>3} fps   {summary[0]}   per-tick MD5 {md5[0]}', 42, (255, 253, 248), MONO)
        y += 120
    k = checks('logs/test_fork_warning_60fps.log')
    ramp = k['9-per-frame-ramp-duration']['observed']['per_plate']['2']['ramps'][0]
    intro = k['5-first-frame-intro-plates-5-6-mid-shadow']['observed']['w']
    pause = k['10-esc-pause-holds-warning-then-resumes-by-1-over-n']['observed']
    ts = k['11-time-scale-0.5-same-tick-count']['observed']
    sp = k['12-sauce-splat-mid-shadow-zero-on-splat-tick']['observed']
    rs = k['13-restart-reads-0-next-shadow-restarts-at-1-over-n']['observed']
    mats = k['3-distinct-materials']['observed']['distinct_material_ids']
    shd = k['3-one-shared-shader']['observed']['distinct_shader_ids']
    rows = [('Rule 1', f'plate 2, per frame at 60 fps: first value {ramp["first"]:.4f} (1/96), last {ramp["last"]:.1f}, then 0.0'),
            ('Rule 2', f'plate 2 ramp {ramp["seconds"]:.2f} s per frame at 60 fps · each plate within one frame period at 30/60/144'),
            ('Rule 4', f'intro: plate 5 {intro[4]:.4f} (37/72), plate 6 {intro[5]:.4f} (31/60), held through the pan'),
            ('Rule 5', f'Esc pause: held {pause["held_value"]} for {pause["frozen_ticks"]} ticks · time_scale 0.5: {ts["ramp_ticks_at_0.5"]} ticks, as at 1.0'),
            ('Rule 6, 3', f'splat mid-SHADOW: {sp["splat_tick"]["w"]} on the splat tick · next SHADOW starts at {rs["next_shadow_first_w"]:.4f}'),
            ('Rule 7', f'{mats} distinct materials · {shd} shared Shader')]
    y += 40
    for r, t in rows:
        label(d, 60, y, r, 46, ACCENT)
        label(d, 400, y, t, 46)
        y += 84
    label(d, 60, y + 10, 'Parsed from the 60 fps log; the 30 and 144 fps logs report the same 29 checks passing. Nothing is drawn headless.', 38, MUTED)
    return c


# ---------- B10 mutations ----------
def b10():
    c, d = canvas()
    m1 = log_lines('logs/mutation-1-semicolon_60fps.log')
    m2 = log_lines('logs/mutation-2-rename_60fps.log')
    m3 = log_lines('logs/mutation-3-source-color_60fps.log')
    def one(ls, pre):
        x = [l for l in ls if l.startswith(pre)]
        if len(x) != 1:
            sys.exit(f'STOPPED: expected one line starting {pre!r}')
        return x[0]
    names2 = json.loads(one(m2, '{"id":"1-uniform-names"'))['observed']['names']
    cols = [(60, 'Mutation 1 · fork_warning.gdshader line 4', 'semicolon removed',
             [one(m1, 'SHADER ERROR'), 'uniform list: []', one(m1, 'FORK WARNING TESTS')]),
            (1100, 'Mutation 2 · fork_warning.gdshader', 'warning renamed to warn_level (shader only)',
             ['no SHADER ERROR', 'uniform list: ' + ', '.join(names2), one(m2, 'FORK WARNING TESTS'), '25 value checks still passed']),
            (2140, 'Mutation 3 · table_wood.gdshader line 5', 'source_color removed from albedo_tex',
             ['no SHADER ERROR', 'FAIL sampler_hints albedo_tex', one(m3, 'MATERIAL CHECKS')])]
    for x, head, what, ls in cols:
        label(d, x, 40, head, 38, MUTED)
        label(d, x, 100, what, 42, ACCENT)
        y = 190
        for l in ls:
            y = wrap(d, x, y, l, 980, 38, INK, MONO, 1.25) + 18
    label(d, 60, 580, 'Each run by Kiran through scripts/run-test.sh, then restored from git · logs/mutation-1/2/3-*_60fps.log · each exited 1', 36, MUTED)
    d.line([60, 650, W - 60, 650], fill=LINE, width=3)
    label(d, 60, 690, 'What no headless run can show', 60, ACCENT, SERIF)
    y = 790
    for t in ['A headless run uses a dummy renderer and draws nothing (CLAUDE.md, headless facts)',
              'so: the colour on screen, the glow readable in play, the silhouette unchanged,',
              'the intro pan, the wood\'s look: each is a human check by Kiran (CHANGE-BRIEF.md §5)',
              '--fixed-fps also hides real-time frame pacing (TEST-REPORT.md A5.11)']:
        label(d, 60, y, t, 48)
        y += 92
    return c


# ---------- B12 one shader, two materials ----------
def b12():
    c, d = canvas()
    shots = [('1_before.png', 'before', 'table (92, 45, 29) · board (87, 32, 11)'),
             ('2_shader_line_edited.png', 'one shader line edited', 'table (41, 31, 29) · board (33, 17, 11)'),
             ('3_board_material_edited.png', "board material's brightness edited", 'table (92, 45, 29) · board (23, 4, 0)')]
    for v in ['table (92, 45, 29) → (41, 31, 29)', 'board (87, 32, 11) → (33, 17, 11)', '(→ (23, 4, 0)); the table stayed (92, 45, 29)']:
        quote('TEST-REPORT.md', v)
    y = 20
    for name, head, vals in shots:
        s = fit(img(f'evidence/a5-captures/shared/{name}').crop(CROP_TIGHT), 1500, 400)
        framed(c, s, 60, y)
        label(d, 1640, y + 100, head, 50, ACCENT)
        label(d, 1640, y + 180, vals, 42, INK, MONO)
        y += 420
    label(d, 1640, 1290, 'evidence/a5-captures/shared/ · scripted captures run by Kiran', 34, MUTED)
    label(d, 1640, 1340, 'in memory only, no file changed · values: TEST-REPORT.md A5.8', 34, MUTED)
    return c


# ---------- B14 hint experiment ----------
def b14():
    c, d = canvas()
    comp = json.loads(text_of('evidence/a5-captures/capture-results.json'))['hint']
    fwd = json.loads(text_of('evidence/a5-captures-forward-plus/capture-results.json'))['hint']
    for k, (name, rel) in enumerate([('Compatibility (the project)', 'evidence/a5-captures/hint_experiment.png'),
                                     ('Forward+ (one run, command-line override)', 'evidence/a5-captures-forward-plus/hint_experiment.png')]):
        im = img(rel)
        x = 60 + k * 1580
        label(d, x, 30, name, 44, ACCENT)
        for q, (box, cap) in enumerate((((52, 285, 580, 435), 'with source_color'), ((700, 285, 1228, 435), 'without'))):
            s = fit(im.crop(box), 720, 260)
            framed(c, s, x + q * 760, 100)
            label(d, x + q * 760, 100 + s.height + 12, cap, 34, MUTED)
    label(d, 60, 470, 'Crops of the two quads in hint_experiment.png from evidence/a5-captures/ and evidence/a5-captures-forward-plus/ · scripted in-engine captures run by Kiran', 34, MUTED)
    pred_with, pred_without = [64, 128, 192], [137, 188, 225]
    cols = [60, 500, 960, 1420, 1900, 2380, 2820]
    y = 580
    heads = ['File value', 'With: predicted', 'Compatibility', 'Forward+', 'Without: predicted', 'Compatibility', 'Forward+']
    for x, h in zip(cols, heads):
        label(d, x, y, h, 38, MUTED)
    for b in range(3):
        y += 90
        cw = comp[f'with_source_color_band{b}']['rgb'][0]
        fw = fwd[f'with_source_color_band{b}']['rgb'][0]
        co = comp[f'without_source_color_band{b}']['rgb'][0]
        fo = fwd[f'without_source_color_band{b}']['rgb'][0]
        vals = [pred_with[b], pred_with[b], cw, fw, pred_without[b], co, fo]
        for k, (x, v) in enumerate(zip(cols, vals)):
            hit = k == 5 and v != pred_without[b]
            label(d, x, y, str(v), 56, BAD if hit else INK, MONO)
    if [comp[f'without_source_color_band{b}']['rgb'][0] for b in range(3)] != [64, 128, 192]:
        sys.exit('STOPPED: unexpected Compatibility measurement')
    if [fwd[f'without_source_color_band{b}']['rgb'][0] for b in range(3)] != pred_without:
        sys.exit('STOPPED: unexpected Forward+ measurement')
    y += 130
    label(d, 60, y, 'Predicted (CHANGE-BRIEF.md §8) for Forward+ or Mobile. Forward+: exactly as predicted. Compatibility: the file unchanged on both quads.', 42)
    label(d, 60, y + 80, 'Red: measured differs from the prediction. Why Compatibility differs is unresolved (FRICTIONAL.md A5).', 42, BAD)
    return c


# ---------- B16 the wood, and the data checks ----------
def b16():
    c, d = canvas()
    s = fit(img('evidence/a5-captures/materials_default.png').crop(CROP_3D), 1700, 600)
    framed(c, s, 60, 60)
    label(d, 60, 60 + s.height + 16, "Scripted in-engine capture (Kiran's run) · materials_default.png · worn table and polished board", 34, MUTED)
    x = 1860
    label(d, x, 60, 'Checked headless', 56, ACCENT, SERIF)
    summ = [l for l in log_lines('logs/test_materials_60fps.log') if l.startswith('MATERIAL CHECKS:')]
    curl = [l for l in log_lines('logs/calibrate_normal_check_60fps.log') if l.startswith('CURL')]
    gl = re.search(r'directx=false: ([\d.]+)', [l for l in curl if 'nor_gl' in l][0]).group(1)
    dx = re.search(r'directx=true: ([\d.]+)', [l for l in curl if 'nor_gl' in l][0]).group(1)
    if summ != ['MATERIAL CHECKS: 108 checks / 0 failures']:
        sys.exit('STOPPED: unexpected test_materials summary')
    y = 160
    for t in [summ[0], 'each sampler\'s hints and each bound file', f'curl, nor_gl as GL: {gl}  (as DX: {dx})',
              'Kiran\'s threshold for this map: < 0.70']:
        label(d, x, y, t, 44, INK, MONO if t.startswith(('MATERIAL', 'curl')) else SANS)
        y += 78
    imp = {}
    for n in ('diff', 'rough', 'nor_gl'):
        txt = text_of(f'godot/assets/textures/dark_wood/dark_wood_{n}_2k.png.import')
        imp[n] = {k: re.search(rf'^{re.escape(k)}=(.*)$', txt, re.M).group(1) for k in ('compress/mode', 'compress/normal_map', 'mipmaps/generate')}
    y = 800
    label(d, 60, y, 'What each texture\'s numbers mean, and how the shader reads them', 52, ACCENT, SERIF)
    rows = [('albedo_tex', 'dark_wood_diff_2k.png', 'sRGB colour', 'source_color', imp['diff']),
            ('roughness_tex', 'dark_wood_rough_2k.png', '0 mirror … 1 rough', 'hint_default_white, read .r', imp['rough']),
            ('normal_tex', 'dark_wood_nor_gl_2k.png', 'slopes, n·0.5+0.5, GL', 'hint_normal', imp['nor_gl'])]
    y += 90
    for a, b, m, h, i in rows:
        label(d, 60, y, a, 42, INK, MONO)
        label(d, 480, y, b, 40, MUTED, MONO)
        label(d, 1240, y, m, 42)
        label(d, 1820, y, h, 42, INK, MONO)
        label(d, 2600, y, f'mode {i["compress/mode"]} · nmap {i["compress/normal_map"]}', 36, MUTED, MONO)
        y += 84
    label(d, 60, y + 20, 'Roles: CHANGE-BRIEF.md §7 · hints: table_wood.gdshader lines 5, 11, 12 · import values read from the .import files (Lossless = 0)', 34, MUTED)
    return c


# ---------- B17 generated vs mine ----------
def b17():
    c, d = canvas()
    gen, mine = 'godot/shaders/standard_generated.gdshader', 'godot/shaders/table_wood.gdshader'
    pairs = [(7, 5, quote('LANGUAGE-NOTES.md', 'Generated shader line 7 marks the albedo texture as colour with `source_color`, matching line 5 of my table shader.')),
             (19, 12, quote('LANGUAGE-NOTES.md', 'Generated line 19 declares the normal texture without `source_color`, so it is treated as data, matching my table\'s line 12.'))]
    label(d, 60, 30, 'Lines read from the files (typeset, not a screenshot) · annotations: Kiran\'s words, LANGUAGE-NOTES.md answer 6', 36, MUTED)
    y = 110
    for g, m, note in pairs:
        label(d, 60, y, f'standard_generated.gdshader, line {g} (Godot\'s Convert to ShaderMaterial, saved unedited)', 38, MUTED)
        d.rectangle([60, y + 56, W - 60, y + 146], fill=(32, 37, 49))
        label(d, 90, y + 74, line_of(gen, g), 46, (237, 241, 247), MONO)
        label(d, 60, y + 166, f'table_wood.gdshader, line {m} (hand-written by Kiran)', 38, MUTED)
        d.rectangle([60, y + 222, W - 60, y + 312], fill=(32, 37, 49))
        label(d, 90, y + 240, line_of(mine, m), 46, (237, 241, 247), MONO)
        y = wrap(d, 60, y + 340, '“' + note.replace('`', '') + '”', W - 120, 44, ACCENT) + 40
    n = quote('LANGUAGE-NOTES.md', "I haven't verified the exact difference between those two hints")
    wrap(d, 60, y, 'Difference: hint_roughness_normal (generated) vs hint_normal (mine). Kiran: “' + n + '.”', W - 120, 42, INK)
    return c


# ---------- B18 sweep ----------
def b18():
    c, d = canvas()
    rows = [('brightness', ['0.0', '1.0', '2.0'], 'brightness'), ('roughness_scale', ['0.0', '0.5', '1.0'], 'roughness_scale'),
            ('normal_strength', ['0.0', '1.0', '2.0'], 'normal_strength'), ('uv_scale', ['0.25', '1.0', '8.0'], 'uv_scale'),
            ('tint', ['0.0_0.0_0.0_1.0', '1.0_0.85_0.7_1.0', '1.0_1.0_1.0_1.0'], 'tint')]
    words = {'brightness': 'Yes, the wood goes from dark to bright', 'roughness_scale': 'I feel they all look the same',
             'normal_strength': 'They all look the same actually', 'uv_scale': 'Yes, the pattern gets smaller and more repeated',
             'tint': 'Yes: black, then warm, then normal'}
    tint_names = {'0.0_0.0_0.0_1.0': 'black', '1.0_0.85_0.7_1.0': '(1, 0.85, 0.7)', '1.0_1.0_1.0_1.0': 'white'}
    y = 20
    for name, vals, key in rows:
        quote('evidence/a5-sweep-notes.md', words[name])
        label(d, 40, y + 20, name, 42, ACCENT, MONO)
        wrap(d, 40, y + 126, '“' + words[name] + '”', 520, 32, INK)
        x = 560
        for v in vals:
            s = fit(img(f'evidence/a5-captures/sweep_table_{key}_{v}.png').crop(CROP_TABLE), 860, 236)
            framed(c, s, x, y + 10)
            x += 870
        label(d, 40, y + 76, ' · '.join(tint_names.get(v, v) for v in vals), 26, INK, MONO)
        y += 256
    label(d, 40, 1302, 'Crops of evidence/a5-captures/sweep_table_*.png · 15 scripted in-engine captures of the worn table (Kiran\'s run) · quotes: Kiran, evidence/a5-sweep-notes.md', 32, MUTED)
    label(d, 40, 1346, 'Largest pixel difference: brightness 0 vs 2: 159 · roughness_scale 0 vs 1: 20 · normal_strength 0 vs 2: 2 (of 255)', 42)
    for v in ['| `brightness` 0.0 vs 2.0 | 159 |', '| `roughness_scale` 0.0 vs 1.0 | 20 |', '| `normal_strength` 0.0 vs 2.0 | 2 |']:
        quote('evidence/a5-sweep-notes.md', v)
    return c


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: make_images.py CAPTURE_WORK_DIR')
    work = Path(sys.argv[1])
    clips = json.loads((REEL / 'media/clips.json').read_text())
    out = REEL / 'images'
    out.mkdir(exist_ok=True)
    made = {'B02-identify.png': b02(work, clips), 'B03-brief-colour-line.png': b03(), 'B05-controlled-values.png': b05(),
            'B09-headless-driver.png': b09(), 'B10-mutations.png': b10(), 'B12-one-shader-two-materials.png': b12(),
            'B14-hint-experiment.png': b14(), 'B16-wood-and-data.png': b16(), 'B17-generated-vs-mine.png': b17(),
            'B18-sweep.png': b18()}
    sums = []
    for name, im in made.items():
        p = out / name
        im.save(p, optimize=True)
        sums.append(f'{sha(p)}  {name}')
        print(name, im.size)
    (out / 'images.sha256').write_text('\n'.join(sums) + '\n')
    (out / 'inputs.sha256').write_text(''.join(f'{v}  {k}\n' for k, v in sorted(USED.items())))
    print(f'{len(USED)} repository inputs matched their committed copies at {REV}')


if __name__ == '__main__':
    main()
